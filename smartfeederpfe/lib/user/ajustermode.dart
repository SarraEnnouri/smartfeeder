import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AjusterModePage extends StatefulWidget {
  const AjusterModePage({super.key});

  @override
  State<AjusterModePage> createState() => _AjusterModePageState();
}

class _AjusterModePageState extends State<AjusterModePage> {
  bool isAutoMode = false;
  int _selectedBottomIndex = 3;
  double manualPercentage = 50;
  int manualQuantity = 2500;
  double scheduledPercentage = 50;
  int scheduledQuantity = 2500;
  TimeOfDay scheduledTime = const TimeOfDay(hour: 20, minute: 0);
  bool isDistributing = false;
  String? selectedFeed;

  List<String> feedTypes = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadFeedTypes();
  }

  Future<void> _loadFeedTypes() async {
    try {
      final snapshot = await _firestore.collection('animals').get();

      final allFoods = snapshot.docs
          .map((doc) => doc.data()['food'] as String?)
          .where((food) => food != null)
          .cast<String>()
          .toList();

      final uniqueFoods = allFoods.toSet().toList();

      setState(() {
        feedTypes = uniqueFoods;
        if (feedTypes.isNotEmpty) selectedFeed = feedTypes.first;
      });
    } catch (e) {
      print("Erreur chargement des types d'alimentation : $e");
    }
  }

  Future<void> _saveConsumptionData(String mode, double eau, int nourriture) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      setState(() {
        isDistributing = true;
      });

      final now = DateTime.now();
      final docId = now.toIso8601String();

      await _firestore.collection('consommation').doc(docId).set({
        'userId': user.uid,
        'date': now,
        'mode': mode,
        'eau': eau,
        'nourriture': nourriture,
        'typeAliment': selectedFeed,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Distribution enregistrée avec succès!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDistributing = false;
        });
      }
    }
  }

  void _distribute() {
    if (isAutoMode) {
      _saveConsumptionData('Automatique', 50, 2500);
    } else {
      if (manualPercentage > 0 || manualQuantity > 0) {
        _saveConsumptionData('Manuel', manualPercentage, manualQuantity);
      } else {
        _saveConsumptionData(
          'Programmé à ${scheduledTime.format(context)}',
          scheduledPercentage,
          scheduledQuantity,
        );
      }
    }
  }

  void _onBottomTabTapped(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/alertuser');
        break;
      case 1:
        Navigator.pushNamed(context, '/profiluser');
        break;
      case 2:
        Navigator.pushNamed(context, '/userac');
        break;
      case 3:
        Navigator.pushNamed(context, '/ajustermode');
        break;
      case 4:
        Navigator.pushNamed(context, '/historiqueuser');
        break;
      case 5:
        Navigator.pushNamed(context, '/calendrier');
        break;
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: scheduledTime,
    );
    if (picked != null) {
      setState(() {
        scheduledTime = picked;
      });
    }
  }

  Widget _buildQuantityInput({
    required String label,
    required double value,
    required String imageAsset,
    required ValueChanged<double> onChanged,
    bool isPercentage = false,
  }) {
    final TextEditingController controller = TextEditingController(
      text: value.toStringAsFixed(0),
    );

    return Column(
      children: [
        Image.asset(imageAsset, width: 24, height: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  suffixText: isPercentage ? '%' : 'g',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (text) {
                  final numericValue = double.tryParse(text) ?? value;
                  if (isPercentage) {
                    if (numericValue >= 0 && numericValue <= 100) {
                      onChanged(numericValue);
                    }
                  } else {
                    onChanged(numericValue);
                  }
                },
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_drop_up),
                  onPressed: () {
                    double newValue = value + 1;
                    if (isPercentage && newValue > 100) newValue = 100;
                    onChanged(newValue);
                    controller.text = newValue.toStringAsFixed(0);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    double newValue = value - 1;
                    if (newValue < 0) newValue = 0;
                    onChanged(newValue);
                    controller.text = newValue.toStringAsFixed(0);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  /*

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 2,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () => Navigator.pushNamed(context, '/userac'),
  ),
  title: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset('assets/images/logo.png', height: 30),
      const SizedBox(width: 8),
      Text.rich(
        TextSpan(
          text: 'Ajuster',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange),
          children: const [
            TextSpan(
              text: ' Mode',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    ],
  ),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications_none, color: Colors.black),
      onPressed: () => Navigator.pushNamed(context, '/alertuser'),
    ),
  ],
),

      
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text('Sélectionner le type d’alimentation',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: feedTypes.map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: selectedFeed == type,
                      onSelected: (_) => setState(() => selectedFeed = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Mode automatique
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.grey.shade100,
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mode Automatique',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: isAutoMode,
                          onChanged: (val) {
                            setState(() => isAutoMode = val);
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  title: 'Manuel mode',
                  percentage: manualPercentage,
                  quantity: manualQuantity,
                  onPercentageChanged: (val) => setState(() => manualPercentage = val),
                  onQuantityChanged: (val) => setState(() => manualQuantity = val),
                ),
                const SizedBox(height: 20),
                _buildModeCard(
                  title: 'Mode Programmé',
                  percentage: scheduledPercentage,
                  quantity: scheduledQuantity,
                  onPercentageChanged: (val) => setState(() => scheduledPercentage = val),
                  onQuantityChanged: (val) => setState(() => scheduledQuantity = val),
                  timePicker: _buildTimePicker(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // logique de distribution
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(330, 50),
                  ),
                  child: const Text('Distribuer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onTap: _onBottomTabTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
         backgroundColor: AppColors.lightGray,
         type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notification_add_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label:""),

        ],
      ),
    );
  }*/

  Widget _buildModeCard({
    required String title,
    required double percentage,
    required int quantity,
    required ValueChanged<double> onPercentageChanged,
    required ValueChanged<int> onQuantityChanged,
    Widget? timePicker,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey.shade100,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuantityInput(
                  label: 'Eau',
                  value: percentage,
                  imageAsset: 'assets/images/eau.png',
                  onChanged: (val) => onPercentageChanged(val),
                  isPercentage: true,
                ),
                _buildQuantityInput(
                  label: 'Nourriture',
                  value: quantity.toDouble(),
                  imageAsset: 'assets/images/nouriture.jpg',
                  onChanged: (val) => onQuantityChanged(val.toInt()),
                ),
              ],
            ),
            if (timePicker != null) ...[
              const SizedBox(height: 12),
              timePicker,
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 8),
            Text(scheduledTime.format(context)),
            const Spacer(),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/userac'),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                text: 'Ajuster',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                children: const [
                  TextSpan(
                    text: ' Mode',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/alertuser'),
          ),
        ],
      ),
      body: SafeArea(
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Partie "Type d'alimentation" avec fond blanc
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Sélectionner le type d\'alimentation ', 
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6), 
                Wrap(
                  spacing: 10,
                    children: feedTypes.map((type) {
                    return ChoiceChip(
                      label: Text(type), 
                      selected: selectedFeed == type,
                      onSelected: (_) => setState(() => selectedFeed = type),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Carte Mode Automatique
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
            color: Colors.grey.shade100,
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mode Automatique',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: isAutoMode,
                    onChanged: (val) => setState(() => isAutoMode = val),
                    activeColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Carte Mode Manuel
          _buildModeCard(
            title: 'Manuel mode',
            percentage: manualPercentage,
            quantity: manualQuantity,
            onPercentageChanged: (val) => setState(() => manualPercentage = val),
            onQuantityChanged: (val) => setState(() => manualQuantity = val),
          ),
          
          const SizedBox(height: 20),
          
          // Carte Mode Programmé
          _buildModeCard(
            title: 'Mode Programmé',
            percentage: scheduledPercentage,
            quantity: scheduledQuantity,
            onPercentageChanged: (val) => setState(() => scheduledPercentage = val),
            onQuantityChanged: (val) => setState(() => scheduledQuantity = val),
            timePicker: _buildTimePicker(),
          ),
          
          const SizedBox(height: 20),
          
          // Bouton Distribuer
          ElevatedButton(
            onPressed: isDistributing ? null : _distribute,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(330, 50),
            ),
            child: isDistributing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Distribuer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  ),
),
bottomNavigationBar: BottomNavigationBar(
  currentIndex: _selectedBottomIndex,
  onTap: _onBottomTabTapped,
  selectedItemColor: Colors.orange,
  unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
  backgroundColor: AppColors.lightGray,
  type: BottomNavigationBarType.fixed,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.notification_add_outlined), label: ""),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
    BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: ""),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: ""),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ""),
  ],
),
);}}

class AppColors { static const Color lightGray = Color(0xFFF2F2F2);  // Gris clair
  static const Color primaryOrange = Color(0xFFFFA500);  // Orange
}
