import 'package:flutter/material.dart';

class AidePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      appBar: AppBar(
        title: Text('Aide'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            'Bienvenue dans la section Aide',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildHelpItem(
            '📋 Profil',
            'Vous pouvez modifier votre nom, prénom, email et photo de profil.',
          ),
          _buildHelpItem(
            '🔐 Mot de passe',
            'Assurez-vous d’utiliser un mot de passe sécurisé. Vous pouvez le modifier à tout moment.',
          ),
          _buildHelpItem(
            '🔔 Alertes',
            'Activez ou désactivez les alertes pour recevoir des notifications importantes.',
          ),
          _buildHelpItem(
            '📅 Plans',
            'Consultez vos plans d’alimentation ou de suivi pour chaque espèce.',
          ),
          SizedBox(height: 30),
          Text(
            '❓ Un problème ou une question ?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Contactez-nous à l’adresse : support@smartfeeder.com',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
