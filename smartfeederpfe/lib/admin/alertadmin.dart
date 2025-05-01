import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Alerteadmin extends StatelessWidget {
  final CollectionReference alertsCollection =
      FirebaseFirestore.instance.collection('alerts');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Alertes',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alertes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: alertsCollection.where('type', isEqualTo: 'warning').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur : ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var alert = snapshot.data!.docs[index];
                        String alertId = alert.id;
                        String title = alert['title'];
                        return _buildWarningItem(alertId, title);
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Notifications générales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              _buildGeneralNotification(),
              Divider(height: 1, thickness: 0.5, color: Colors.grey), // Divider ajouté ici
              SizedBox(height: 20),
              Text(
                'Pannes du système',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: alertsCollection.where('type', isEqualTo: 'error').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur : ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var alert = snapshot.data!.docs[index];
                        String title = alert['title'];
                        return _buildFailureItem(title);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _markAllAsResolved();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Marquer comme résolu'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsResolved(String alertId) async {
    await alertsCollection.doc(alertId).update({
      'status': 'resolved',
    });
  }

  Future<void> _markAllAsResolved() async {
    QuerySnapshot querySnapshot = await alertsCollection.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.update({
        'status': 'resolved',
      });
    }
  }

  Widget _buildWarningItem(String alertId, String title) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFDEAE9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _markAsResolved(alertId),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralNotification() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFCF1E4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFFCF1E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color.fromARGB(255, 2, 2, 2)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Distribution effectuée avec succès',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8), // Espacement entre le texte et la ligne
          Divider(
            height: 1, // Hauteur totale incluant l'épaisseur
            thickness: 1, // Épaisseur de la ligne
            color: Colors.black, // Couleur noire
          ),
        ],
      ),
    );
  }

  Widget _buildFailureItem(String title) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 11, 11, 11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}