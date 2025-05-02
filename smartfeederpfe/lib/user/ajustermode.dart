import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AjusterModePage extends StatefulWidget {
  const AjusterModePage({Key? key}) : super(key: key);

  @override
  State<AjusterModePage> createState() => _AjusterModePageState();
}

class _AjusterModePageState extends State<AjusterModePage> {
  // États de l'application
  bool isAutoMode = false;
  bool isProgrammedMode = false;
  int _selectedBottomIndex = 3;
  int manualFoodQuantity = 250;
  int manualWaterQuantity = 500; // ml
  int scheduledFoodQuantity = 250;
  int scheduledWaterQuantity = 500; // ml
  TimeOfDay scheduledTime = const TimeOfDay(hour: 20, minute: 0);
  bool isDistributing = false;
  bool isLoadingFeedTypes = false;
  String? selectedFeed;
  
  // Références Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> feedTypes = [];

  @override
  void initState() {
    super.initState();
    _loadFeedTypes();
  }

  Future<void> _loadFeedTypes() async {
    if (!mounted) return;
    
    setState(() => isLoadingFeedTypes = true);
    
    try {
      final snapshot = await _firestore.collection('animals').get();
      
      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun animal trouvé')),
          );
        }
        return;
      }
      
      final allFoods = snapshot.docs
          .map((doc) => doc.data()['food'] as String?)
          .where((food) => food != null)
          .cast<String>()
          .toList();
          
      if (allFoods.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun type d\'alimentation trouvé')),
          );
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          feedTypes = allFoods.toSet().toList();
          selectedFeed = feedTypes.isNotEmpty ? feedTypes.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingFeedTypes = false);
      }
    }
  }

  Future<void> _saveConsumptionData(String mode, int eau, int nourriture) async {
    if (!mounted) return;

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
      }
      return;
    }

    if (selectedFeed == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un type d\'alimentation')),
        );
      }
      return;
    }

    setState(() => isDistributing = true);

    try {
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
        setState(() => isDistributing = false);
      }
    }
  }

  void _saveDistribution() {
    if (isAutoMode) {
      _saveConsumptionData('Automatique', 0, 0);
    } else if (isProgrammedMode) {
      _saveConsumptionData('Programmé', scheduledWaterQuantity, scheduledFoodQuantity);
    } else {
      _saveConsumptionData('Manuel', manualWaterQuantity, manualFoodQuantity);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: scheduledTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null && mounted) {
      setState(() => scheduledTime = pickedTime);
    }
  }

  void _onBottomTabTapped(int index) {
    if (!mounted) return;
    
    setState(() => _selectedBottomIndex = index);
    
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
                  suffixText: isPercentage ? '%' : label == 'Eau' ? 'ml' : 'g',
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
                      controller.text = numericValue.toStringAsFixed(0);
                    }
                  } else {
                    onChanged(numericValue);
                    controller.text = numericValue.toStringAsFixed(0);
                  }
                },
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_drop_up),
                  onPressed: () {
                    double newValue = value + (isPercentage ? 1 : label == 'Eau' ? 50 : 10);
                    if (isPercentage && newValue > 100) newValue = 100;
                    onChanged(newValue);
                    controller.text = newValue.toStringAsFixed(0);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    double newValue = value - (isPercentage ? 1 : label == 'Eau' ? 50 : 10);
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Automatique Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mode Automatique', 
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Switch(
                    value: isAutoMode,
                    activeColor: Colors.orange,
                    onChanged: (value) => setState(() => isAutoMode = value),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Manuel/Programmé Selector (seulement visible en mode manuel)
              if (!isAutoMode) ...[
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isProgrammedMode = true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isProgrammedMode ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('Programmé', 
                                   style: TextStyle(
                                     color: isProgrammedMode ? Colors.white : Colors.black,
                                     fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isProgrammedMode = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !isProgrammedMode ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('Manuel', 
                                   style: TextStyle(
                                     color: !isProgrammedMode ? Colors.white : Colors.black,
                                     fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Sélection du grain
              const Text('Type d\'alimentation', 
                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              if (isLoadingFeedTypes)
                const Center(child: CircularProgressIndicator())
              else if (feedTypes.isEmpty)
                const Text('Aucun type d\'alimentation disponible',
                     style: TextStyle(color: Colors.red))
              else
                Opacity(
                  opacity: isAutoMode ? 0.5 : 1.0,
                  child: AbsorbPointer(
                    absorbing: isAutoMode,
                    child: Wrap(
                      spacing: 10,
                      children: feedTypes.map((feed) {
                        return ChoiceChip(
                          label: Text(feed),
                          selected: selectedFeed == feed,
                          onSelected: isAutoMode 
                              ? null 
                              : (selected) {
                                  if (selected) {
                                    setState(() => selectedFeed = feed);
                                  }
                                },
                          selectedColor: Colors.orange, 
                          labelStyle: TextStyle(
                            color: selectedFeed == feed ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              
              // Contrôles pour l'eau et la nourriture
              if (!isAutoMode) ...[
                const SizedBox(height: 20),
                const Text('Quantités de distribution',
                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Quantité de nourriture
                    _buildQuantityInput(
                      label: 'Nourriture',
                      value: isProgrammedMode 
                          ? scheduledFoodQuantity.toDouble() 
                          : manualFoodQuantity.toDouble(),
                      imageAsset: 'assets/images/nouriture.jpg',
                      onChanged: (value) {
                        setState(() {
                          if (isProgrammedMode) {
                            scheduledFoodQuantity = value.toInt();
                          } else {
                            manualFoodQuantity = value.toInt();
                          }
                        });
                      },
                    ),
                    
                    // Quantité d'eau
                    _buildQuantityInput(
                      label: 'Eau',
                      value: isProgrammedMode 
                          ? scheduledWaterQuantity.toDouble() 
                          : manualWaterQuantity.toDouble(),
                      imageAsset: 'assets/images/eau.png',
                      onChanged: (value) {
                        setState(() {
                          if (isProgrammedMode) {
                            scheduledWaterQuantity = value.toInt();
                          } else {
                            manualWaterQuantity = value.toInt();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
              
              // Sélecteur de temps (seulement visible en mode programmé)
              if (!isAutoMode && isProgrammedMode) ...[
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          scheduledTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.access_time, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Bouton de distribution - SEULEMENT visible si le mode automatique est désactivé
              if (!isAutoMode) ...[
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isDistributing ? null : _saveDistribution,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isDistributing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('DISTRIBUER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onTap: _onBottomTabTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.grey[200],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notification_add_outlined), 
            label: "Alertes"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), 
            label: "Paramètres"),
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: "Accueil"),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank), 
            label: "Alimentation"),
          BottomNavigationBarItem(
            icon: Icon(Icons.history), 
            label: "Historique"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), 
            label: "Calendrier"),
        ],
      ),
    );
  }
}