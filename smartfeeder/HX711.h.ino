<<<<<<< HEAD
#ifndef HX711_h
#define HX711_h
#include "HX711.h"  // Inclure la bibliothèque HX711

class HX711Sensor {
public:
  HX711Sensor(int doutPin, int clkPin);  // Constructeur pour initialiser les pins du capteur HX711
  void begin();  // Initialisation du capteur HX711
  long readWeight(); // Fonction pour lire le poids
  
private:
  HX711 scale;  // Objet HX711 pour gérer le capteur de poids
  int doutPin;  // Pin de données (DOUT) du capteur HX711
  int clkPin;   // Pin de l'horloge (CLK) du capteur HX711
};
=======
#ifndef HX711_H
#define HX711_H
#include <HX711.h>

class HX711Sensor {
public:
  HX711Sensor(int doutPin, int clkPin);
  void begin();
  float readWeight();
  
private:
  HX711 scale;
  int doutPin, clkPin;
};
#endif
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
