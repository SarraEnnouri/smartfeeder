<<<<<<< HEAD
#include <WiFi.h>
#include <PubSubClient.h>
#include "config.h"

WiFiClient espClient;
=======
#include "mqtt.h"
#include "config.h"

>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
PubSubClient mqttClient(espClient);

void initMQTT() {
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
<<<<<<< HEAD
  while (!mqttClient.connected()) {
    Serial.println("Connexion au broker MQTT...");
    if (mqttClient.connect(MQTT_CLIENT_ID)) {
      Serial.println("Connecté au broker MQTT !");
    } else {
      Serial.print("Échec de la connexion MQTT, réessai dans 5 secondes...");
      delay(5000);
    }
  }
=======
  mqttClient.setCallback(mqttCallback);
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String message = String((char*)payload, length);
  Serial.println("Message MQTT : " + message);
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
}

void publishMQTT(const char* topic, String payload) {
  mqttClient.publish(topic, payload.c_str());
}
<<<<<<< HEAD

void checkMQTTCommands() {
  mqttClient.loop();
  // Ajoutez ici la logique pour traiter les commandes reçues via MQTT
}
=======
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
