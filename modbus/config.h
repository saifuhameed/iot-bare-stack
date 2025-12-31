#ifndef CONFIG_H
#define CONFIG_H

typedef struct {
    char device[64];
    int baudrate;
    char parity;
    int data_bits;
    int stop_bits;
    char redis_host[64];
    int redis_port;
    char db_path[128];
    int poll_interval;
    int log_interval;
	int redis_ttl;
    char mqtt_broker[128];
    int mqtt_port;
    char mqtt_topic_prefix[128];
    int mqtt_qos;
    int mqtt_keepalive;
    char mqtt_client_id[64];
    char mqtt_username[64];
    char mqtt_password[64];
} Config;

int load_config(const char *filename, Config *cfg);

#endif
