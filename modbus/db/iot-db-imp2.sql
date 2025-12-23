BEGIN TRANSACTION;

DROP TABLE IF EXISTS iotdata;
DROP TABLE IF EXISTS iotdevices;
DROP TABLE IF EXISTS iot_devices_types;
DROP TABLE IF EXISTS sensor_data_register_mapping;

CREATE TABLE IF NOT EXISTS "iotdata" (
	"id"	INTEGER,
	"ts"	TEXT DEFAULT NULL,
	"slaveid"	INTEGER,
	"iotdata"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);

CREATE TABLE IF NOT EXISTS "iot_devices_types" (
	"devices_type_id"	INTEGER NOT NULL,
	"devices_type_name"	TEXT NOT NULL,
	"description"	TEXT,	
	"register_list"	TEXT,
	PRIMARY KEY("devices_type_id")
);

CREATE TABLE IF NOT EXISTS "iotdevices" (
	"device_id"	INTEGER NOT NULL,
	"slaveid"	INTEGER NOT NULL,
	"devices_type_id"	INTEGER,
	"devicename"	TEXT NOT NULL,	
	"description"	TEXT NOT NULL,
	"location"	TEXT,	
	PRIMARY KEY("device_id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "sensor_data_register_mapping" (
	"mapid"	INTEGER NOT NULL,
	"devices_type_id"	INTEGER NOT NULL,
	"parameter_name"	TEXT NOT NULL,
	"register_address"	INTEGER NOT NULL,
	"register_count"	INTEGER NOT NULL,
	"data_type"	TEXT NOT NULL,
	"decimal_shift"	INTEGER NOT NULL,
	"unit"	TEXT,
	"log_to_db"	TEXT DEFAULT 'N' CHECK(UPPER("log_to_db") IN ('Y', 'YES', 'N', 'NO')),
	PRIMARY KEY("mapid" AUTOINCREMENT)
);
INSERT INTO "iotdata" ("id","ts","slaveid","iotdata") VALUES (1,'2025-11-05 18:25:01',1,'{ "Wind Speed": { "value": 1450.0, "unit": "m/s" }, "Wind Level": { "value": 25.0, "unit": "none" } }');
INSERT INTO "iotdata" ("id","ts","slaveid","iotdata") VALUES (2,'2025-11-05 18:25:01',2,'{ "Wind Direction Angle": { "value": 1450.0, "unit": "°" }, "Wind Direction": { "value": 25.0, "unit": "none" } }');
INSERT INTO "iotdata" ("id","ts","slaveid","iotdata") VALUES (3,'2025-11-05 18:25:01',7,'{ "Wind Direction Angle": { "value": 1450.0, "unit": "°" }, "Wind Direction": { "value": 25.0, "unit": "none" } }');

INSERT INTO "iot_devices_types" ("devices_type_id","devices_type_name","description","register_list") VALUES (1001,'Wind Speed Sensor','Wind Speed Sensor','[{"function": 3, "address": 0, "count": 2}]');
INSERT INTO "iot_devices_types" ("devices_type_id","devices_type_name","description","register_list") VALUES (1002,'Wind Direction Sensor','Wind Direction Sensor','[{"function": 3, "address": 0, "count": 1}]');
INSERT INTO "iot_devices_types" ("devices_type_id","devices_type_name","description","register_list") VALUES (1003,'Rain Sensor','Tipping Bucket Rain Sensor','[{"function": 3, "address": 0, "count": 16},{"function": 3, "address": 20, "count": 2}]');
INSERT INTO "iot_devices_types" ("devices_type_id","devices_type_name","description","register_list") VALUES (1004,'Water Level Sensor Head1','Water Level Sensor Head1','[{"function": 3, "address": 0, "count": 12},{"function": 3, "address": 22, "count": 7} ]');
INSERT INTO "iot_devices_types" ("devices_type_id","devices_type_name","description","register_list") VALUES (1005,'Water Level Sensor Head2','Water Level Sensor Head2','[{"function": 3, "address": 12, "count": 10},{"function": 3, "address": 29, "count": 7}]');
INSERT INTO "iot_devices_types" ("devices_type_id","devices_type_name","description","register_list") VALUES (1006,'DS18B20','Temperature Sensor','[{"function": 3, "address": 0, "count": 8}]');
INSERT INTO "iot_devices_types" ("devices_type_id","devices_type_name","description","register_list") VALUES (1007,'Atm Temperature and Humidity','Temperature Sensor','[{"function": 3, "address": 16, "count": 3}]');

INSERT INTO "iotdevices" ("slaveid","devicename","description","location","devices_type_id") VALUES (2,'WIND_SPEED_S1','Wind Speed','Kumbalam',1001);
INSERT INTO "iotdevices" ("slaveid","devicename","description", "location","devices_type_id") VALUES (3,'WIND_DIR_S1','Wind Direction','Kumbalam',1002);
INSERT INTO "iotdevices" ("slaveid","devicename","description", "location","devices_type_id") VALUES (4,'RAIN_S1','Tipping bucket Rain Sensor','Kumbalam',1003);
INSERT INTO "iotdevices" ("slaveid","devicename","description", "location","devices_type_id") VALUES (5,'OVHD_TNK1_LEVEL','Overhead Tank 1 Water Level Sensor','Kumbalam',1004);
INSERT INTO "iotdevices" ("slaveid","devicename","description", "location","devices_type_id") VALUES (5,'OVHD_TNK2_LEVEL','Overhead Tank 2 Water Level Sensor','Kumbalam',1005);
INSERT INTO "iotdevices" ("slaveid","devicename","description", "location","devices_type_id") VALUES (6,'UG_TNK1_LEVEL','Underground Tank 1 Water Level Sensor','Kumbalam',1004);
INSERT INTO "iotdevices" ("slaveid","devicename","description", "location","devices_type_id") VALUES (7,'DS18B20 Sensors','Kumbalam',1006);
INSERT INTO "iotdevices" ("slaveid","devicename","description", "location","devices_type_id") VALUES (4,'ATM_TEMP_HUM_S1','Atm. Temperature and Humidity Sensor','Kumbalam',1007);


INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1001,'Wind Speed',0,1,'FLOAT',1,'m/s','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1001,'Wind Level',1,1,'FLOAT',1,'none','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1001,'SLAVEID',2000,1,'FLOAT',1,'none','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1001,'BAUD_RATE_INDEX',2001,1,'FLOAT',1,'none','N');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1002,'Wind Direction Angle',0,1,'FLOAT',1,'°','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1002,'Wind Direction',1,1,'INT',0,'none','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1002,'SLAVEID',2000,1,'FLOAT',1,'none','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1002,'BAUD_RATE_INDEX',2001,1,'FLOAT',1,'none','N');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'MM_RAIN_PER_HOUR',0,1,'FLOAT',2,'mm/hr','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'MM_RAIN_PER_DAY',1,1,'FLOAT',2,'mm/day','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'LAST_MM_RAIN_PER_DAY',2,1,'FLOAT',2,'mm/day','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'TIPS_PER_DAY',3,2,'INT',0,'tips/day','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'LAST_TIPS_PER_DAY',5,2,'INT',0,'tips/day','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'MM_RAIN_PER_TIP',7,1,'FLOAT',4,'mm/tip','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'SECONDS_SINCE_LAST_TIP',8,1,'INT',0,'seconds','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'HOURS',9,1,'INT',0,'hours','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'MINUTES',10,1,'INT',0,'minutes','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'SECONDS',11,1,'INT',0,'seconds','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'DAY',12,1,'INT',0,'day','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'MONTH',13,1,'INT',0,'month','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'YEAR',14,1,'INT',0,'year','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'RTC_BAT_VCC_MV',15,1,'INT',0,'mV','N');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1007,'TMP_SENSOR_FOUND',16,1,'INT',0,'','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1007,'TEMPERATURE',17,1,'FLOAT',1,'°C','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1007,'HUMIDITY',18,1,'FLOAT',1,'%','YES');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'SLAVEID',19,1,'INT',0,'','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1003,'BAUD_RATE_INDEX',20,1,'INT',0,'','N');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'SLAVEID',0,1,'INT',0,'','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'BAUD_RATE_INDEX',1,1,'INT',0,'','N');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'CAP_LEVEL_ZERO_PF',2,1,'FLOAT',1,'pf','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'CAP_LEVEL_FULL_PF',3,1,'FLOAT',1,'pf','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'LEVEL_FULL_MM',4,1,'FLOAT',1,'mm','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'OSC_RES1_VAL',5,2,'INT',0,'Ohms','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'OSC_RES2_VAL',7,2,'INT',0,'Ohms','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'OSC_K_VAL',9,1,'FLOAT',3,'','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'LEVEL_HIGH_IN_PERC_SET',10,1,'FLOAT',1,'%','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'LEVEL_LOW_IN_PERC_SET',11,1,'FLOAT',1,'%','N');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'CAP_LEVEL_ZERO_PF',12,1,'FLOAT',1,'pf','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'CAP_LEVEL_FULL_PF',13,1,'FLOAT',1,'pf','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'LEVEL_FULL_MM',14,1,'FLOAT',1,'mm','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'OSC_RES1_VAL',15,2,'INT',0,'Ohms','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'OSC_RES2_VAL',17,2,'INT',0,'Ohms','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'OSC_K_VAL',19,1,'FLOAT',3,'','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'LEVEL_HIGH_IN_PERC_SET',20,1,'FLOAT',1,'%','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'LEVEL_LOW_IN_PERC_SET',21,1,'FLOAT',1,'%','N');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'LEVEL_IN_MM',22,1,'FLOAT',1,'mm','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'CAP_PF',23,1,'FLOAT',1,'pf','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'FREQUENCY',24,2,'INT',0,'Hz','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'LIQUID_TEMP',26,1,'FLOAT',1,'°C','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'ALARM_LEVEL_LOW',27,1,'INT',0,'','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1004,'ALARM_LEVEL_HIGH',28,1,'INT',0,'','YES');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'LEVEL_IN_MM',29,1,'FLOAT',1,'mm','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'CAP_PF',30,1,'FLOAT',1,'pf','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'FREQUENCY',31,2,'INT',0,'Hz','N');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'LIQUID_TEMP',33,1,'FLOAT',1,'°C','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'ALARM_LEVEL_LOW',34,1,'INT',0,'','YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1005,'ALARM_LEVEL_HIGH',35,1,'INT',0,'','YES');

INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1006,'DS18B20_COUNT',2,1,'INT',0,NULL,'YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1006,'DS18B20_ROM',3,4,'STRING',0,NULL,'YES');
INSERT INTO "sensor_data_register_mapping" ("devices_type_id","parameter_name","register_address","register_count","data_type","decimal_shift","unit","log_to_db") VALUES (1006,'TEMPERATURE',7,1,'FLOAT',1,'°C','YES');

COMMIT;
