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
        title: const Text(
          'Alertes',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Nouvelles inscriptions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _buildSignupStream(),

          const Divider(height: 30, thickness: 0.5, color: Color.fromARGB(255, 196, 196, 196)),

          const Text(
            'Pannes du système',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _buildErrorStream(),

          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _markAllAsResolved,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Marquer tout comme résolu'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// STREAM BUILDERS

 Widget _buildSignupStream() {
  return StreamBuilder<QuerySnapshot>(
    stream: alertsCollection
        .where('type', isEqualTo: 'user_signup')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Erreur : ${snapshot.error}'));
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        );
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Aucune inscription récente.'));
      }
      return Column(
        children: snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _buildSignupItem(
            data['title'] ?? 'Titre non disponible',
            data['details'] ?? 'Détails non disponibles',
          );
        }).toList(),
      );
    },
  );
}

Widget _buildSignupItem(String title, String details) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 5),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 250, 236, 224),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color.fromARGB(255, 255, 228, 177).withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
          children: [
            const Icon(Icons.person_add, color: Color.fromARGB(255, 255, 190, 68)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ],
        ),
        Text(
          details,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 8),
       
      ],
    ),
  );
}


  Widget _buildErrorStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: alertsCollection
          .where('type', isEqualTo: 'error')
          .where('status', isEqualTo: 'unresolved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ));
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune panne détectée.'));
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            return _buildFailureItem(doc['title']);
          }).toList(),
        );
      },
    );
  }

  /// ACTIONS FIRESTORE

  Future<void> _markAsResolved(String alertId) async {
    try {
      await alertsCollection.doc(alertId).update({
        'status': 'resolved',
        'timestampResolved': Timestamp.now(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour : $e');
    }
  }

  Future<void> _markAllAsResolved() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      QuerySnapshot querySnapshot = await alertsCollection
          .where('status', isEqualTo: 'unresolved')
          .get();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'resolved',
          'timestampResolved': Timestamp.now(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Erreur lors du traitement batch : $e');
    }
  }

  /// BUILDER WIDGETS

  Widget _buildWarningItem(String alertId, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEAE9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _markAsResolved(alertId),
          ),
        ],
      ),
    );
  }

  
  Widget _buildFailureItem(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

 
}
