#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sqlite3.h>
#include <modbus/modbus.h>
#include <hiredis/hiredis.h>
#include <cjson/cJSON.h>
#include "config.h"
#include <errno.h>
//#include <arpa/inet.h>  // for socket functions

#define MAX_DEVICES 128
#define MAX_REGISTERS 5
#define RETRY_DELAY 5   // seconds between retries for checking status of redis server

//gcc -o  modbus_to_redis  modbus_to_redis.c config.c -lmodbus -lcjson -lsqlite3 -lhiredis 
#define KNRM  "\x1B[0m"   // Normal/Reset
#define KRED  "\x1B[31m"   // Red
#define KGRN  "\x1B[32m"   // Green
#define KYEL  "\x1B[33m"   // Yellow
#define KBLU  "\x1B[34m"   // Blue
#define KCYN  "\x1B[36m"   // Cyan

typedef enum {
    DT_UNKNOWN = -1,
    DT_INT = 0,
    DT_FLOAT = 1,
    DT_STRING = 2,
    DT_BOOL = 3
    // add more as needed: DT_UINT16, DT_INT32, DT_DOUBLE, etc.
} DataType;

typedef struct {
    char parameter_name[64];
    int address;
    int reg_count;
    DataType data_type;
    int dec_shift;
    char unit[20]; 
} DataRegisterMapDef;


typedef struct {
    int function;
    int address;
    int count;
} RegisterDef;

typedef struct {
    int slaveid;
    char devicename[64];
    RegisterDef registers[MAX_REGISTERS];
    int register_count;
    int devices_type_id;
    int is_online;
    DataRegisterMapDef datamap[10];
    int data_map_count;                  // number of entries in datamap[]
} Device;

int parse_register_list(const char *json_str, RegisterDef *regs, int *count) {
    cJSON *root = cJSON_Parse(json_str);
    if (!root || !cJSON_IsArray(root)) return -1;

    *count = 0;
    int len = cJSON_GetArraySize(root);
    for (int i = 0; i < len && i < MAX_REGISTERS; i++) {
        cJSON *item = cJSON_GetArrayItem(root, i);
        cJSON *fn = cJSON_GetObjectItem(item, "function");
        cJSON *addr = cJSON_GetObjectItem(item, "address");
        cJSON *cnt = cJSON_GetObjectItem(item, "count");
        if (cJSON_IsNumber(fn) && cJSON_IsNumber(addr) && cJSON_IsNumber(cnt)) {
            regs[*count].function = fn->valueint;
            regs[*count].address = addr->valueint;
            regs[*count].count = cnt->valueint;
            (*count)++;
        }
    }
    cJSON_Delete(root);
    return 0;
}

#include <stdio.h>
#include <string.h>
#include <sqlite3.h>

// Assuming RegisterDef is already defined elsewhere
// and MAX_REGISTERS is a known constant

int parse_data_register_map(sqlite3 *db, Device *dev) {
    if (!db || !dev) {
        fprintf(stderr, "Invalid arguments to parse_data_register_map\n");
        return -1;
    }

    const char *sql =
        "SELECT parameter_name, register_address, register_count, data_type, decimal_shift, unit "
        "FROM sensor_data_register_mapping "
        "WHERE devices_type_id = ? "
        "AND UPPER(log_to_db) IN ('Y','YES');";

    sqlite3_stmt *stmt;
    int rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to prepare statement: %s\n", sqlite3_errmsg(db));
        return -1;
    }

    sqlite3_bind_int(stmt, 1, dev->devices_type_id);

    int count = 0;
    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
        if (count >= 10) {
            fprintf(stderr, "Exceeded datamap capacity\n");
            break;
        }

        DataRegisterMapDef *map = &dev->datamap[count];

        const unsigned char *param = sqlite3_column_text(stmt, 0);
        int addr = sqlite3_column_int(stmt, 1);
        int reg_count = sqlite3_column_int(stmt, 2);
        const unsigned char *dtype = sqlite3_column_text(stmt, 3);
        int dec_shift = sqlite3_column_int(stmt, 4);
        const unsigned char *unit = sqlite3_column_text(stmt, 5);

        strncpy(map->parameter_name, param ? (const char *)param : "",
                sizeof(map->parameter_name) - 1);
        map->parameter_name[sizeof(map->parameter_name) - 1] = '\0';

        map->address = addr;
        map->reg_count = reg_count;

        if (dtype) {
            if (strcasecmp((const char *)dtype, "INT") == 0) {
                map->data_type = DT_INT;
            } else if (strcasecmp((const char *)dtype, "FLOAT") == 0) {
                map->data_type = DT_FLOAT;
            } else if (strcasecmp((const char *)dtype, "STRING") == 0) {
                map->data_type = DT_STRING;
            } else if (strcasecmp((const char *)dtype, "BOOL") == 0) {
                map->data_type = DT_BOOL;
            } else {
                map->data_type = DT_UNKNOWN;
            }
        } else {
            map->data_type = DT_UNKNOWN;
        }

        map->dec_shift = dec_shift;

        strncpy(map->unit, unit ? (const char *)unit : "",
                sizeof(map->unit) - 1);
        map->unit[sizeof(map->unit) - 1] = '\0';

        count++;
    }

    sqlite3_finalize(stmt);

    dev->data_map_count = count;   // ✅ track datamap entries separately

    return count;
}

int load_devices(sqlite3 *db, Device *devices, int *device_count) {
    sqlite3_stmt *stmt;
    const char *sql =
        "SELECT d.slaveid, d.devicename, t.register_list , d.devices_type_id "
        "FROM iotdevices d JOIN iot_devices_types t ON d.devices_type_id = t.devices_type_id ORDER BY d.slaveid;";

    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;

    *device_count = 0;
    while (sqlite3_step(stmt) == SQLITE_ROW && *device_count < MAX_DEVICES) {
        Device *dev = &devices[*device_count];
        dev->slaveid = sqlite3_column_int(stmt, 0);
        const unsigned char *name = sqlite3_column_text(stmt, 1);
        const unsigned char *reglist = sqlite3_column_text(stmt, 2);
        dev->devices_type_id= sqlite3_column_text(stmt, 3);
        strncpy(dev->devicename, name ? (const char *)name : "", sizeof(dev->devicename));
        if (reglist && parse_register_list((const char *)reglist, dev->registers, &dev->register_count) == 0) {
            (*device_count)++;
        }
        parse_data_register_map(db,dev);
    }

    sqlite3_finalize(stmt);
    return 0;
}

int read_modbus(modbus_t *ctx, int function, int address, int count, uint16_t *buffer) {
    if (count <= 0 || count > 64) return -1;

    int rc = -1;
    if (function == 3) {
        rc = modbus_read_registers(ctx, address, count, buffer);
    } else if (function == 4) {
        rc = modbus_read_input_registers(ctx, address, count, buffer);
    }

    return (rc == count) ? 0 : -1;
}



int upload_modbus_data_to_redis(redisContext *redis, Device *dev) {
    if (!redis || !dev) {
        fprintf(stderr, "Invalid arguments to upload_modbus_data_to_redis\n");
        return -1;
    }

    for (int i = 0; i < dev->data_map_count; i++) {
        DataRegisterMapDef *map = &dev->datamap[i];

        double value = 0.0;
        char strval[128];

        switch (map->data_type) {
            case DT_INT:
                if (map->reg_count == 1) {
                    int raw = dev->registers[map->address];
                    value = raw;
                } else if (map->reg_count == 2) {
                    int raw = (dev->registers[map->address] << 16) |
                               dev->registers[map->address + 1];
                    value = raw;
                }
                snprintf(strval, sizeof(strval), "%d", (int)value);
                break;

            case DT_FLOAT:
                if (map->reg_count == 2) {
                    uint32_t raw = ((uint32_t)dev->registers[map->address] << 16) |
                                    dev->registers[map->address + 1];
                    float f;
                    memcpy(&f, &raw, sizeof(float));
                    value = f;
                }
                snprintf(strval, sizeof(strval), "%.6f", value);
                break;

            case DT_BOOL:
                value = dev->registers[map->address] ? 1 : 0;
                snprintf(strval, sizeof(strval), "%d", (int)value);
                break;

            case DT_STRING: {
                char buf[64] = {0};
                for (int r = 0; r < map->reg_count && r < (int)sizeof(buf)-1; r++) {
                    buf[r] = (char)(dev->registers[map->address + r] & 0xFF);
                }
                snprintf(strval, sizeof(strval), "%s", buf);
                break;
            }

            default:
                snprintf(strval, sizeof(strval), "UNKNOWN");
                break;
        }

        // Apply decimal shift for numeric types
        if (map->data_type == DT_INT || map->data_type == DT_FLOAT) {
            for (int s = 0; s < map->dec_shift; s++) {
                value /= 10.0;
            }
            snprintf(strval, sizeof(strval), "%.6f", value);
        }

        // Upload to Redis
        redisReply *reply = (redisReply *)redisCommand(
            redis, "SET %s:%s %s",
            dev->devicename, map->parameter_name, strval);

        if (!reply) {
            fprintf(stderr, "Redis SET failed for %s:%s\n",
                    dev->devicename, map->parameter_name);
            continue;
        }
        freeReplyObject(reply);

        printf("Uploaded %s:%s = %s\n",
               dev->devicename, map->parameter_name, strval);
    }

    return 0;
}

void upload_registers(redisContext *redis, int slaveid, int base_index, uint16_t *regs, int count, int ttl) {
    for (int k = 0; k < count; k++) {
        char key[64], val[32];
        snprintf(key, sizeof(key), "modbus:%d:reg%d", slaveid, base_index + k);
        snprintf(val, sizeof(val), "%d", regs[k]);
        redisReply *reply = redisCommand(redis, "SET %s %s EX %d", key, val, ttl);
        if (reply) freeReplyObject(reply);
    }
}

void populate_redis_keys_for_flask(sqlite3 *db, redisContext *redis, int ttl) {
    sqlite3_stmt *stmt1, *stmt2;

    const char *sql1 = "SELECT slaveid, devices_type_id FROM iotdevices";
    if (sqlite3_prepare_v2(db, sql1, -1, &stmt1, NULL) != SQLITE_OK) {
        fprintf(stderr, "%sFailed to prepare iotdevices query: %s\n", sqlite3_errmsg(db),KRED);
        return;
    }

    while (sqlite3_step(stmt1) == SQLITE_ROW) {
        int slaveid = sqlite3_column_int(stmt1, 0);
        int devices_type_id = sqlite3_column_int(stmt1, 1);

        const char *sql2 =
            "SELECT parameter_name, register_address FROM sensor_data_register_mapping "
            "WHERE devices_type_id = ?";
        if (sqlite3_prepare_v2(db, sql2, -1, &stmt2, NULL) != SQLITE_OK) continue;

        sqlite3_bind_int(stmt2, 1, devices_type_id);

        while (sqlite3_step(stmt2) == SQLITE_ROW) {
            const unsigned char *param = sqlite3_column_text(stmt2, 0);
            int address = sqlite3_column_int(stmt2, 1);

            if (!param) continue;

            char key[128], val[32];
            snprintf(key, sizeof(key), "modbus:%d:%s", slaveid, param);
            snprintf(val, sizeof(val), "%d", address);

            redisReply *reply = redisCommand(redis, "SET %s %s EX %d", key, val, ttl);
            if (reply) freeReplyObject(reply);

            printf("%sLoaded Redis key: %s → %s\n",KGRN, key, val);
        }
        sqlite3_finalize(stmt2);
    }

    sqlite3_finalize(stmt1);
}

//SET modbus:write:7:4 3  SLAVEID=7, register_address=4, value=3
void handle_modbus_write_command(sqlite3 *db, redisContext *redis, modbus_t *ctx, int redis_ttl) {
    redisReply *keys = redisCommand(redis, "KEYS modbus:write:*");
    if (!keys || keys->type != REDIS_REPLY_ARRAY) {
        if (keys) freeReplyObject(keys);
        return;
    }

    for (size_t i = 0; i < keys->elements; i++) {
        const char *key = keys->element[i]->str;
        int slaveid;
        int address;
        if (sscanf(key, "modbus:write:%d:%d", &slaveid, &address) != 2) continue;

        redisReply *val = redisCommand(redis, "GET %s", key);
        if (!val || val->type != REDIS_REPLY_STRING) {
            if (val) freeReplyObject(val);
            continue;
        }

        int value = atoi(val->str);
        freeReplyObject(val);
 
        if (address < 0) continue; 
        modbus_set_slave(ctx, slaveid);
		char fail_key[128], result_key[128];
		snprintf(result_key, sizeof(result_key), "modbus:result:%d:%d", slaveid, address);
		snprintf(fail_key, sizeof(fail_key), "modbus:failcount:%d:%d", slaveid, address);

		//printf("WRITING TO MODBUS SLAVEID: %D,address: %d, value: %d\n", slaveid ,address,value);
		int rc = modbus_write_register(ctx, address, value);
		//printf("modbus_write_register returned %d for slave %d addr %d\n", rc, slaveid, address);

		if (rc >= 0 || errno == 0) {
			//printf("Wrote %d to slave %d register %d\n", value, slaveid, address);
			redisCommand(redis, "SET %s OK EX %d", result_key,redis_ttl);
			redisCommand(redis, "DEL %s", key);
			redisCommand(redis, "DEL %s", fail_key);  // reset failure count
		} else {
			fprintf(stderr, "Modbus write failed for %s\n", key);
			redisReply *fail = redisCommand(redis, "INCR %s", fail_key);
			int attempts = (fail && fail->type == REDIS_REPLY_INTEGER) ? fail->integer : 0;
			if (fail) freeReplyObject(fail);

			if (attempts >= 3) {				
				redisCommand(redis, "SET %s ERROR: Max retries reached EX %d", result_key,redis_ttl);
				redisCommand(redis, "DEL %s", key);
				redisCommand(redis, "DEL %s", fail_key);
				redisCommand(redis, "DEL %s", result_key); // delete result key too

			} else {				
				redisCommand(redis, "SET %s ERROR: Attempt %d EX %d", result_key, attempts,redis_ttl);
			}
		}


    }

    freeReplyObject(keys);
}

// Function to check if Redis is accepting TCP connections
int is_redis_running(char * redis_host, int redis_port) {
    redisContext *c = redisConnect(redis_host, redis_port);
    if (c == NULL) {
        fprintf(stderr, "Failed to allocate redis context\n");
        return 0;
    }

    if (c->err) {
        fprintf(stderr, "Redis connection error: %s [%s:%d]\n", c->errstr,redis_host,redis_port);
        redisFree(c);
        return 0;
    }

    // Redis is reachable
    redisFree(c);
    return 1;
}

void clearScreen() {
    printf("\e[1;1H\e[2J"); // ANSI codes to clear screen & move cursor to top-left
}

int main() {
    Config cfg;
    if (load_config("config.ini", &cfg) != 0) {
        fprintf(stderr, "%sFailed to load config.ini%s\n",KRED,KNRM);
        return 1;
    }
	if (cfg.redis_ttl <= 0) cfg.redis_ttl = 60;

    sqlite3 *db;
    if (sqlite3_open(cfg.db_path, &db) != SQLITE_OK) {
        fprintf(stderr, "%sSQLite open error: %s [%s]%s\n",KRED, sqlite3_errmsg(db),cfg.db_path,KNRM);
        return 1;
    }
	printf("%s✅ sqlite db file opened.%s\n",KGRN,KNRM);
	while (!is_redis_running(cfg.redis_host, cfg.redis_port)) {
        printf("%sRedis not available yet. Retrying in %d second(s)...%s\n", KRED,RETRY_DELAY,KNRM);
        sleep(RETRY_DELAY);
    }

    printf("%s✅ Redis server is running! Proceeding...%s\n",KGRN,KNRM);

    redisContext *redis = redisConnect(cfg.redis_host, cfg.redis_port);
    if (!redis || redis->err) {
        fprintf(stderr, "Redis error: %s\n", redis ? redis->errstr : "NULL");
        sqlite3_close(db);
        return 1;
    }
	//populate_redis_keys_for_flask(db, redis, cfg.redis_ttl);
	
    modbus_t *ctx = modbus_new_rtu(cfg.device, cfg.baudrate, cfg.parity, cfg.data_bits, cfg.stop_bits);
	//modbus_set_debug(ctx, TRUE);
    if (!ctx || modbus_connect(ctx) == -1) {
        fprintf(stderr, "%sModbus connection failed%s\n",KRED,KNRM);
        redisFree(redis);
        sqlite3_close(db);
        return 1;
    }

    printf("%s✅ Modbus connection succeeded. [device:%s, baud: %d] %s\n",KGRN, cfg.device, cfg.baudrate, KNRM);

    Device devices[MAX_DEVICES];
    int device_count = 0;
    if (load_devices(db, devices, &device_count ) != 0) {
        fprintf(stderr, "%sFailed to load devices%s\n",KRED,KNRM);
        modbus_close(ctx);
        modbus_free(ctx);
        redisFree(redis);
        sqlite3_close(db);
        return 1;
    }
    printf("%s✅ Devices loaded. Polling for %d devices ... %s\n",KGRN, device_count, KNRM);

    while (1) {
        for (int i = 0; i < device_count; i++) {
            modbus_set_slave(ctx, devices[i].slaveid);
			//int reg_offset = 0;
			for (int j = 0; j < devices[i].register_count; j++) {
				RegisterDef *reg = &devices[i].registers[j];
				uint16_t regs[64];
				if (read_modbus(ctx, reg->function, reg->address, reg->count, regs) == 0) {
					//printf("slaveid: %d  ",devices[i].slaveid);
					//for (int k = 0; k < reg->count; k++) {
					//	printf("%02d, ",regs[k]);
					//}
					//printf("\n");
                    
					upload_registers(redis, devices[i].slaveid, reg->address, regs, reg->count, cfg.redis_ttl);
                    upload_modbus_data_to_redis(redis,devices[i]);
					//reg_offset += reg->count;
                    devices[i].is_online=1;
				}
			}
            if(devices[i].is_online)printf("\r%sModbus device id: %d is online%s",KCYN,devices[i].slaveid,KNRM);            
        }
        fflush(stdout);
        handle_modbus_write_command(db, redis, ctx, cfg.redis_ttl);
        sleep(cfg.poll_interval);
    }

    modbus_close(ctx);
    modbus_free(ctx);
    redisFree(redis);
    sqlite3_close(db);
    return 0;

}
