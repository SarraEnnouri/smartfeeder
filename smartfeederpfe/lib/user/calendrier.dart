import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}
class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, String> _plans = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    QuerySnapshot snapshot = await _firestore.collection('plans').get();
    for (var doc in snapshot.docs) {
      DateTime date = DateTime.parse(doc['date']);
      String plan = doc['plan'];
      setState(() {
        _plans[date] = plan;
      });
    }
  }

  Future<void> _deletePlan(DateTime date) async {
    // Trouver le document correspondant à la date dans Firestore
    QuerySnapshot snapshot = await _firestore
        .collection('plans')
        .where('date', isEqualTo: date.toIso8601String())
        .get();

    // Supprimer tous les documents correspondants (normalement il n'y en a qu'un)
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Mettre à jour l'état local
    setState(() {
      _plans.remove(date);
    });
  }

  void _showPlanDialog(DateTime selectedDate) {
    TextEditingController planController = TextEditingController();
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Ajouter un plan pour le $formattedDate"),
          content: TextField(
            controller: planController,
            decoration: InputDecoration(hintText: "Entrez votre plan ici"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (planController.text.isNotEmpty) {
                  await _firestore.collection('plans').add({
                    'date': selectedDate.toIso8601String(),
                    'plan': planController.text,
                  });

                  setState(() {
                    _plans[selectedDate] = planController.text;
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text("Ajouter"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Annuler"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Calendrier",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TableCalendar(
                locale: 'fr_FR',
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showPlanDialog(selectedDay);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: const Color.fromARGB(220, 249, 118, 31),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayTextStyle: const TextStyle(color: Colors.white),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextFormatter: (date, locale) =>
                      DateFormat.yMMMM(locale).format(date),
                  titleTextStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 248, 248, 248),
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: const Color.fromARGB(255, 252, 251, 251),
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: const Color.fromARGB(255, 253, 253, 251),
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 8, 8, 8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Color.fromARGB(220, 249, 118, 31)),
                  weekdayStyle: TextStyle(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Plans :",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  DateTime date = _plans.keys.elementAt(index);
                  String plan = _plans[date] ?? '';
                  return Dismissible(
                    key: Key(date.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _deletePlan(date);
                    },
                    child: ListTile(
                      title: Text(DateFormat('yyyy-MM-dd').format(date)),
                      subtitle: Text(plan),
                      leading: Icon(Icons.calendar_today),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: const Color.fromARGB(255, 0, 0, 0)),
                        onPressed: () {
                          _deletePlan(date);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}