#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "config.h"

int load_config(const char *filename, Config *cfg) {
    FILE *fp = fopen(filename, "r");
    if (!fp) return -1;

    char line[256];
    while (fgets(line, sizeof(line), fp)) {
        char *eq = strchr(line, '=');
        if (!eq) continue;

        *eq = '\0';
        char *key = line;
        char *value = eq + 1;

        // Trim whitespace and newline
        key = strtok(key, " \t\r\n");
        value = strtok(value, " \t\r\n");

        if (!key || !value) continue;

        if (strcmp(key, "device") == 0) {
            strncpy(cfg->device, value, sizeof(cfg->device));
        } else if (strcmp(key, "baudrate") == 0) {
            cfg->baudrate = atoi(value);
        } else if (strcmp(key, "parity") == 0) {
            cfg->parity = value[0];
        } else if (strcmp(key, "data_bits") == 0) {
            cfg->data_bits = atoi(value);
        } else if (strcmp(key, "stop_bits") == 0) {
            cfg->stop_bits = atoi(value);
        } else if (strcmp(key, "poll_interval") == 0) {
            cfg->poll_interval = atoi(value);
        } else if (strcmp(key, "db_path") == 0) {
            strncpy(cfg->db_path, value, sizeof(cfg->db_path));
        } else if (strcmp(key, "redis_host") == 0) {
            strncpy(cfg->redis_host, value, sizeof(cfg->redis_host));
        } else if (strcmp(key, "redis_port") == 0) {
            cfg->redis_port = atoi(value);
        } else if (strcmp(key, "redis_ttl") == 0) {
            cfg->redis_ttl = atoi(value);
        } else if (strcmp(key, "mqtt_broker") == 0) {
            strncpy(cfg->mqtt_broker, value, sizeof(cfg->mqtt_broker));
        } else if (strcmp(key, "mqtt_port") == 0) {
            cfg->mqtt_port = atoi(value);
        } else if (strcmp(key, "mqtt_topic_prefix") == 0) {
            strncpy(cfg->mqtt_topic_prefix, value, sizeof(cfg->mqtt_topic_prefix));
        } else if (strcmp(key, "mqtt_qos") == 0) {
            cfg->mqtt_qos = atoi(value);
        } else if (strcmp(key, "mqtt_keepalive") == 0) {
            cfg->mqtt_keepalive = atoi(value);
        } else if (strcmp(key, "mqtt_client_id") == 0) {
            strncpy(cfg->mqtt_client_id, value, sizeof(cfg->mqtt_client_id));
        } else if (strcmp(key, "mqtt_username") == 0) {
            strncpy(cfg->mqtt_username, value, sizeof(cfg->mqtt_username));
        } else if (strcmp(key, "mqtt_password") == 0) {
            strncpy(cfg->mqtt_password, value, sizeof(cfg->mqtt_password));
        }   
    }

    fclose(fp);
    return 0;
}
