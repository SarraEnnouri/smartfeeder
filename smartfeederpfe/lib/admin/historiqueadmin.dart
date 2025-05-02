import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoriqueAdmin extends StatefulWidget {
  @override
  _HistoriqueAdminState createState() => _HistoriqueAdminState();
}

class _HistoriqueAdminState extends State<HistoriqueAdmin> {
  String? _selectedTimeFilter;
  final List<String> _timeFilters = ['Aujourd\'hui', 'Hier', 'Cette semaine'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getFilteredHistory() {
    Query query = _firestore.collection('historique');

    if (_selectedTimeFilter != null) {
      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      switch (_selectedTimeFilter) {
        case 'Aujourd\'hui':
          query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(
                todayStart.add(Duration(days: 1))));
          break;

        case 'Hier':
          final yesterdayStart = todayStart.subtract(Duration(days: 1));
          query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(yesterdayStart))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(todayStart));
          break;

        case 'Cette semaine':
          int daysToSubtract = todayStart.weekday - 1;
          DateTime weekStart = todayStart.subtract(Duration(days: daysToSubtract));
          final weekEnd = weekStart.add(Duration(days: 7));
          query = query
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd));
          break;
      }
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> _deleteHistoryItem(String docId) async {
    try {
      await _firestore.collection('historique').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entrée supprimée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: ${e.toString()}')),
      );
    }
  }

  void _showDeleteDialog(String docId, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cette entrée d\'historique ?\n\nAction: $action'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHistoryItem(docId);
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedTimeFilter = null;
    });
  }

  Widget _buildTimeFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        children: _timeFilters.map((filter) {
          return ChoiceChip(
            label: Text(
              filter,
              style: TextStyle(
                color: _selectedTimeFilter == filter ? Colors.white : Colors.black,
              ),
            ),
            selected: _selectedTimeFilter == filter,
            onSelected: (selected) {
              setState(() {
                _selectedTimeFilter = selected ? filter : null;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryIcon(String? category) {
    if (category == 'utilisateur') {
      return Image.asset(
        'assets/images/up.png',
        width: 30,
        height: 30,
        fit: BoxFit.contain,
      );
    } 
    if (category == 'animal') {
      return Image.asset(
        'assets/images/logo.png',
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        color: const Color.fromARGB(255, 0, 0, 0),
      );
    } 
    return Icon(Icons.category);
  }

  Widget _buildActionIcon(String action) {
    if (action.startsWith('Ajout')) {
      return Icon(Icons.add_circle, color: Colors.orange);
    } else if (action.startsWith('Modification')) {
      return Icon(Icons.edit, color: Colors.orange);
    } else if (action.startsWith('Suppression')) {
      return Icon(Icons.delete, color: Colors.orange);
    }
    return Icon(Icons.info);
  }

  Widget _buildHistoryList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _getFilteredHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Erreur Firestore :", style: TextStyle(color: Colors.red)),
                  Text(snapshot.error.toString(), style: TextStyle(fontSize: 12)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _resetFilters,
                    child: Text("Réinitialiser les filtres"),
                  )
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text("Aucune action trouvée"));
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final action = data['action'] ?? 'Action inconnue';
              final details = data['details'] ?? 'Détails manquants';
              final user = data['user'] ?? data['userEmail'] ?? 'Utilisateur inconnu';
              final date = (data['timestamp'] as Timestamp).toDate();
              final category = data['categorie'];

              return LongPressDraggable(
                feedback: Material(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildHistoryItem(
                      action: action,
                      details: details,
                      user: user,
                      date: date,
                      category: category,
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: _buildHistoryItem(
                    action: action,
                    details: details,
                    user: user,
                    date: date,
                    category: category,
                  ),
                ),
                onDragStarted: () {},
                onDragEnd: (details) {},
                child: GestureDetector(
                  onLongPress: () => _showDeleteDialog(doc.id, action),
                  child: _buildHistoryItem(
                    action: action,
                    details: details,
                    user: user,
                    date: date,
                    category: category,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem({
    required String action,
    required String details,
    required String user,
    required DateTime date,
    required String? category,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[100],
        child: _buildCategoryIcon(category),
      ),
      title: Text(action, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details),
          SizedBox(height: 4),
          Text(
            '${DateFormat('dd/MM/yyyy à HH:mm').format(date)} • Par: $user',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      trailing: _buildActionIcon(action),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Historique des Actions"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetFilters,
            tooltip: "Réinitialiser les filtres",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimeFilterChips(),
          _buildHistoryList(),
        ],
      ),
    );
  }
}