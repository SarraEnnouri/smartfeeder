import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class Historiqueuser extends StatefulWidget {
  @override
  _HistoriqueDistributionsPageState createState() => _HistoriqueDistributionsPageState();
}

class _HistoriqueDistributionsPageState extends State<Historiqueuser> {
  String? selectedMode;
  DateTimeRange? selectedDateRange;

  Stream<QuerySnapshot> getFilteredStream() {
    Query query = FirebaseFirestore.instance.collection('distributions');

    if (selectedMode != null) {
      query = query.where('mode', isEqualTo: selectedMode);
    }

    if (selectedDateRange != null) {
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: selectedDateRange!.start)
          .where('timestamp', isLessThanOrEqualTo: selectedDateRange!.end);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  void setDateRange(Duration duration) {
    final now = DateTime.now();
    setState(() {
      selectedDateRange = DateTimeRange(
        start: now.subtract(duration),
        end: now,
      );
    });
  }

  void resetFilters() {
    setState(() {
      selectedMode = null;
      selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text("Historique des Distributions", style: TextStyle(color: Colors.black,fontSize:18,)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Sous-titre pour "Distributions Passées"
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Distributions Passées",
                style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getFilteredStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("Aucune distribution trouvée.", style: TextStyle(color: Colors.black54)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0x3CC6B9B9)),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    DateTime date = (data['timestamp'] as Timestamp).toDate();
                    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                    String mode = data['mode'];
                    int quantite = data['quantite'];

                    return ListTile(
                      leading: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0x1ABBB6B6),
                        child: Icon(Icons.history, color: Colors.orange),
                      ),
                      title: Text(formattedDate, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      subtitle: Text(mode, style: TextStyle(color: Colors.grey[600])),
                      trailing: Text("$quantite g", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    );
                  },
                );
              },
            ),
          ),
          // Sous-titre pour "Filtrer par date"
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Filtrer par date",
                style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text("Aujourd'hui", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                  backgroundColor: const Color(0xFFEBEBEB),
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) => setDateRange(Duration(hours: 24)),
                ),
                FilterChip(
                  label: const Text("Hier", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                  backgroundColor: const Color(0xFFEBEBEB),
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) => setDateRange(Duration(days: 2)),
                ),
                FilterChip(
                  label: const Text("7 jours", style: TextStyle(color: Color.fromARGB(255, 10, 10, 10))),
                  backgroundColor: const Color(0xFFEBEBEB),
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) => setDateRange(Duration(days: 7)),
                ),
                FilterChip(
                  label: const Text("Personnalisé", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                  backgroundColor: const Color(0xFFEBEBEB),
                  selectedColor: Colors.orange,
                  onSelected: (bool selected) async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDateRange = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          // Sous-titre pour "Filtrer par Mode"
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Filtrer par Mode",
                style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text("Automatique", style: TextStyle(color: Color.fromARGB(255, 4, 4, 4))),
                  selectedColor: Colors.orange,
                  backgroundColor: const Color(0xFFEBEBEB),
                  selected: selectedMode == "Automatique",
                  onSelected: (bool selected) => setState(() => selectedMode = "Automatique"),
                ),
                ChoiceChip(
                  label: const Text("Manuel", style: TextStyle(color: Color.fromARGB(255, 8, 8, 8))),
                  selectedColor: Colors.orange,
                  backgroundColor: const Color(0xFFEBEBEB),
                  selected: selectedMode == "Manuel",
                  onSelected: (bool selected) => setState(() => selectedMode = "Manuel"),
                ),
                ChoiceChip(
                  label: const Text("Programmé", style: TextStyle(color: Color.fromARGB(255, 6, 6, 6))),
                  selectedColor: Colors.orange,
                  backgroundColor: const Color(0xFFEBEBEB),
                  selected: selectedMode == "Programmé",
                  onSelected: (bool selected) => setState(() => selectedMode = "Programmé"),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Rafraîchir", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: resetFilters,
            ),
          ),
        ],
      ),
    );
  }
}