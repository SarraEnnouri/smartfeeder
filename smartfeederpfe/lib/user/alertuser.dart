import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Alertuser extends StatefulWidget {
  const Alertuser({Key? key}) : super(key: key);

  @override
  State<Alertuser> createState() => _AlertuserState();
}

class _AlertuserState extends State<Alertuser> {
  final CollectionReference alertsCollection =
      FirebaseFirestore.instance.collection('alertUser');
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  Future<void> _markAsResolved(String alertId) async {
    try {
      setState(() => _isLoading = true);
      await alertsCollection.doc(alertId).update({
        'status': 'resolved',
        'resolvedAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerte marquée comme résolue')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAlert(String alertId) async {
    try {
      setState(() => _isLoading = true);
      await alertsCollection.doc(alertId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerte supprimée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsResolved() async {
    try {
      setState(() => _isLoading = true);
      final batch = FirebaseFirestore.instance.batch();

      final querySnapshot = await alertsCollection
          .where('status', isNotEqualTo: 'resolved')
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'resolved',
          'resolvedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les alertes marquées comme résolues')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  Widget _buildAlertItem(
    String alertId, 
    Map<String, dynamic> data, 
    Color backgroundColor,
    Color iconColor,
    String type,
  ) {
    return Dismissible(
      key: Key(alertId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmer'),
            content: const Text('Voulez-vous supprimer cette alerte ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteAlert(alertId),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'warning' ? Icons.warning : Icons.error,
                  color: iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['title'] ?? 'Alerte',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (data['status'] != 'resolved')
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green,
                    onPressed: () => _markAsResolved(alertId),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44.0, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['description'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (data['species'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Espèce: ${data['species']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  if (data['medication'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Médicament: ${data['medication']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(data['timestamp']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (data['status'] == 'resolved')
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'Résolu',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSection(String title, String type, Color backgroundColor, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: alertsCollection
              .where('type', isEqualTo: type)
              .orderBy('timestamp', descending: true) // Récupérer toutes les alertes
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur de chargement',
                  style: TextStyle(color: Colors.red[700]),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Aucune alerte de ce type',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                return _buildAlertItem(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                  backgroundColor,
                  iconColor,
                  type,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gestion des Alertes'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Tout marquer comme résolu',
              onPressed: _markAllAsResolved,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAlertSection(
                      'Alertes ',
                      'warning',
                      const Color(0xFFFCF1E4),
                      Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    _buildAlertSection(
                      'Pannes Système',
                      'error',
                      const Color(0xFFFDEAE9),
                      Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _markAllAsResolved,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Marquer tout comme résolu'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
