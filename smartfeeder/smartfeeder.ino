<<<<<<< HEAD
#include <WiFi.h>             
#include "mqtt.h"
#include "HX711.h"            
#include "FirebaseESP32.h"     
#include "define.h"  
#include "Waterlevel.h"        

//Connexion WiFi & MQTT
// Wi-Fi
char* ssidArray[] = { WIFI_SSID , WIFI_SSID1, WIFI_SSID2};
char* passwordArray[] = {WIFI_PASS, WIFI_PASS1, WIFI_PASS2};

// MQTT
const char* mqtt_server = "test.mosquitto.org"; // Par défaut pour tests

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connexion à ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);
=======
#include <WiFi.h>

#include <PubSubClient.h>
#include "HX711.h"
#include "WaterLevel.h"
#include "config.h"

// Déclaration des objets
HX711Sensor hx711(DOUT_PIN, CLK_PIN);
WaterLevel waterLevel(TRIG_PIN, ECHO_PIN);
WiFiClient espClient;
PubSubClient mqttClient(espClient);
FirebaseData firebaseData;

// Variables globales
float poids = 0.0;
float niveauEau = 0.0;
String mode = "AUTO";  // Modes possibles : AUTO, MANUEL, PROGRAMME

void setup() {
  Serial.begin(115200);
  
  // Initialisations
  setupWiFi();
  initMQTT();
  hx711.begin();
  waterLevel.begin();
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  
  Serial.println("Smart Feeder prêt !");
}

void loop() {
  // Lecture des capteurs
  poids = hx711.readWeight();
  niveauEau = waterLevel.readDistance();
  
  // Envoi des données à Firebase
  sendToFirebase();
  
  // Gestion MQTT
  checkMQTTCommands();
  mqttClient.loop();
  
  // Logique des modes
  handleMode();
  
  delay(1000);  // Pause de 1 seconde
}

// Fonctions
void setupWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASS);
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
<<<<<<< HEAD
  Serial.println("");
  Serial.println("WiFi connecté");
  Serial.println(WiFi.localIP());
}

//Initialiser les capteurs et modules
// Lire les capteurs
// Logique des 3 modes
// Contrôle des actionneurs
//Envoyer les données vers MQTT / Firebase
//Surveillance & alertes
=======
  Serial.println("\nWiFi connecté ! IP : " + WiFi.localIP());
}

void initMQTT() {
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
  reconnectMQTT();
}

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    if (mqttClient.connect(MQTT_CLIENT_ID)) {
      mqttClient.subscribe(MQTT_TOPIC);
      Serial.println("MQTT connecté !");
    } else {
      Serial.println("Échec MQTT, réessai...");
      delay(5000);
    }
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String message = String((char*)payload, length);
  if (String(topic) == MQTT_TOPIC) {
    mode = message;  // Mise à jour du mode via MQTT
    Serial.println("Mode changé : " + mode);
  }
}

void sendToFirebase() {
  Firebase.setFloat(firebaseData, "/poids", poids);
  Firebase.setFloat(firebaseData, "/eau", niveauEau);
  Firebase.setString(firebaseData, "/mode", mode);
}

void handleMode() {
  if (mode == "AUTO") {
    // Logique automatique (ex: nourrir si poids < seuil)
  } else if (mode == "MANUEL") {
    // Logique manuelle (commande via MQTT/Firebase)
  } else if (mode == "PROGRAMME") {
    // Logique programmée (ex: nourrir à heures fixes)
  }
}
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
