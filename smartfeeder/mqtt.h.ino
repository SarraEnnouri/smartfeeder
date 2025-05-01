<<<<<<< HEAD
void setup() {
  // put your setup code here, to run once:

}

void loop() {
  // put your main code here, to run repeatedly:

}
=======
#ifndef MQTT_H
#define MQTT_H
#include <PubSubClient.h>

void initMQTT();
void reconnectMQTT();
void mqttCallback(char* topic, byte* payload, unsigned int length);
void publishMQTT(const char* topic, String payload);

extern PubSubClient mqttClient;
#endif
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
