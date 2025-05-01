<<<<<<< HEAD
#include "WaterLevel.h"  // Inclure le fichier d'en-tête WaterLevel.h
#include <NewPing.h>  // Bibliothèque pour capteurs à ultrasons (HC-SR04)

// Constructeur qui prend les pins TRIG et ECHO
WaterLevel::WaterLevel(int trigPin, int echoPin) {
  this->trigPin = trigPin;  // Initialiser la pin TRIG
  this->echoPin = echoPin;  // Initialiser la pin ECHO
}

// Fonction d'initialisation
void WaterLevel::begin() {
  // Initialise le capteur à ultrasons avec une portée maximale de 200 cm
  NewPing sonar(trigPin, echoPin, 200);
}

// Fonction pour lire la distance en cm
float WaterLevel::readDistance() {
  NewPing sonar(trigPin, echoPin, 200);  // Créer un objet NewPing
  return sonar.ping_cm();  // Retourner la distance mesurée en centimètres
=======
#include "WaterLevel.h"

WaterLevel::WaterLevel(int trigPin, int echoPin) 
  : sonar(trigPin, echoPin, 200) {}  // Portée max = 200 cm

void WaterLevel::begin() {
  // Initialisation facultative (déjà faite dans le constructeur)
}

float WaterLevel::readDistance() {
  return sonar.ping_cm();  // Distance en cm
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
}
