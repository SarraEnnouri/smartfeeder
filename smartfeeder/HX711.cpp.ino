<<<<<<< HEAD

#include "HX711.h"  // Inclure le fichier d'en-tête HX711.h
// Constructeur qui prend les pins DOUT et CLK
HX711Sensor::HX711Sensor(int doutPin, int clkPin) {
  this->doutPin = doutPin;  // Initialiser la pin DOUT
  this->clkPin = clkPin;    // Initialiser la pin CLK
}

// Fonction d'initialisation du capteur
void HX711Sensor::begin() {
  scale.begin(doutPin, clkPin);  // Initialiser le capteur HX711
  scale.tare();  // Réinitialiser la balance à zéro
  scale.set_scale(2280.f);  // Définir un facteur de calibrage (à ajuster selon tes besoins)
}

// Fonction pour lire le poids en unités
long HX711Sensor::readWeight() {
  return scale.get_units(10);  // Lire la moyenne de 10 mesures pour plus de stabilité
=======
#include "HX711.h"

HX711Sensor::HX711Sensor(int doutPin, int clkPin) 
  : doutPin(doutPin), clkPin(clkPin) {}

void HX711Sensor::begin() {
  scale.begin(doutPin, clkPin);
  scale.tare();
  scale.set_scale(2280.f);  // À calibrer !
}

float HX711Sensor::readWeight() {
  return scale.get_units(10);  // Moyenne de 10 lectures
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
}
