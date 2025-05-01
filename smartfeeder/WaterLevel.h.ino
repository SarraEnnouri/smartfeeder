<<<<<<< HEAD
// WaterLevel.h - Déclaration de la classe WaterLevel pour gérer le capteur de niveau d'eau

#ifndef WATERLEVEL_h
#define WATERLEVEL_h

class WaterLevel {
public:
  WaterLevel(int trigPin, int echoPin);  // Constructeur pour initialiser les pins du capteur
  void begin();  // Initialiser le capteur de niveau d'eau
  float readDistance();  // Lire la distance du capteur à ultrasons

private:
  int trigPin;  // Pin TRIG pour envoyer l'impulsion
  int echoPin;  // Pin ECHO pour recevoir l'écho
};
=======
#ifndef WATERLEVEL_H
#define WATERLEVEL_H
#include <NewPing.h>

class WaterLevel {
public:
  WaterLevel(int trigPin, int echoPin);
  void begin();
  float readDistance();
  
private:
  NewPing sonar;
};
#endif
>>>>>>> 2a3260669d7942e56c6dccce3dd3c1a85aee43c2
