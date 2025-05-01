import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartfeeder/admin/modifieranimal.dart';

class AnimalAddScreen extends StatefulWidget {
  @override
  _AnimalAddScreenState createState() => _AnimalAddScreenState();
}

class _AnimalAddScreenState extends State<AnimalAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _foodController = TextEditingController();
  final _medicationController = TextEditingController();
  int _quantity = 0;
  TimeOfDay? _medicationTime;
  DateTime? _lastFeedingTime;

  final FocusNode _speciesFocusNode = FocusNode();
  final FocusNode _foodFocusNode = FocusNode();
  final FocusNode _medicationFocusNode = FocusNode();

  final Color orangeColor = Color(0xFFE7B48C);
  final Color defaultBorderColor = Colors.grey;

  @override
  void dispose() {
    _speciesController.dispose();
    _foodController.dispose();
    _medicationController.dispose();
    _speciesFocusNode.dispose();
    _foodFocusNode.dispose();
    _medicationFocusNode.dispose();
    super.dispose();
  }
  Future<void> _saveToHistory(String action, String details, {bool isError = false}) async {
  try {
    await FirebaseFirestore.instance.collection('historique').add({
      'action': action,
      'details': details,
      'categorie' : 'animal' ,
      'timestamp': Timestamp.now(),
      'user': 'Admin', // Remplacez par l'utilisateur connecté si disponible
      'isError': isError,
      
    });
  } catch (error) {
    print("Erreur lors de la sauvegarde dans l'historique: $error");
  }
}

  Future<void> _selectTime(BuildContext context, bool isMedication) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isMedication) {
          _medicationTime = picked;
        } else {
          _lastFeedingTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

 Future<void> _addAnimal() async {
  if (_formKey.currentState!.validate()) {
    try {
      // Vérifie si l'animal existe déjà
      final querySnapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('species', isEqualTo: _speciesController.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final species = _speciesController.text.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Animal déjà existant. Modifiez-le si nécessaire.'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Modifier',
              textColor: Colors.orange,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimalEditScreen(
                      speciesName: species,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        await FirebaseFirestore.instance.collection('animals').add({
          'species': _speciesController.text.trim(),
          'quantity': _quantity,
          'food': _foodController.text.trim(),
          'medications': _medicationController.text.trim(),
          'medicationTime': _medicationTime != null
              ? '${_medicationTime!.hour}:${_medicationTime!.minute.toString().padLeft(2, '0')}'
              : null,
          'lastFeedingTime': _lastFeedingTime,
          'lastUpdate': Timestamp.now(),
          'createdAt': Timestamp.now(),
        });

        await _saveToHistory(
          'Ajout d\'un nouvel animal',
          'Espèce: ${_speciesController.text.trim()}, Quantité: $_quantity',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Animal ajouté avec succès')),
        );

        _resetForm();
      }
    } catch (error) {
      await _saveToHistory(
        'Erreur lors de l\'ajout d\'un animal',
        'Erreur: ${error.toString()}',
        isError: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${error.toString()}')),
      );
    }
  }
}


  void _resetForm() {
    _speciesController.clear();
    _foodController.clear();
    _medicationController.clear();
    setState(() {
      _quantity = 0;
      _medicationTime = null;
      _lastFeedingTime = null;
    });
  }

  Color _getBorderColor(FocusNode focusNode) {
    return focusNode.hasFocus ? orangeColor : defaultBorderColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter animaux', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _resetForm,
            tooltip: 'Réinitialiser le formulaire',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF2E7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Espèce"),
                          _buildTextField(
                            controller: _speciesController,
                            hint: "Poule, Canard, Autre...",
                            validator: (value) => value!.isEmpty ? 'Ce champ est obligatoire' : null,
                            focusNode: _speciesFocusNode,
                          ),
                          SizedBox(height: 20),
                          _buildLabel("Nombre d'animaux"),
                          _buildQuantityField(),
                          SizedBox(height: 20),
                          _buildLabel("Alimentation"),
                          _buildTextField(
                            controller: _foodController,
                            hint: "Maïs, Blé, Autre...",
                            validator: (value) => value!.isEmpty ? 'Ce champ est obligatoire' : null,
                            focusNode: _foodFocusNode,
                          ),
                          SizedBox(height: 20),
                          _buildLabel("Médicaments"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _medicationController,
                                  hint: "Tyloxine, Perméthrine...",
                                  focusNode: _medicationFocusNode,
                                ),
                              ),
                              SizedBox(width: 10),
                              _buildTimePickerField(
                                value: _medicationTime != null
                                    ? '${_medicationTime!.hour}:${_medicationTime!.minute.toString().padLeft(2, '0')}'
                                    : null,
                                onTap: () => _selectTime(context, true),
                                hint: 'Heure',
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _addAnimal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Ajouter",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    required FocusNode focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(focusNode), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
        color: Colors.white,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        focusNode: focusNode,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          hintStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimePickerField({
    required String? value,
    required VoidCallback onTap,
    required String hint,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null ? orangeColor : Colors.grey.shade300,
            width: 1.5,
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 20, color: value != null ? orangeColor : Colors.grey),
            SizedBox(width: 8),
            Text(
              value ?? hint,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: value != null ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _quantity > 0 ? orangeColor : Colors.grey.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4, offset: Offset(2, 2))],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$_quantity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => setState(() => _quantity++),
                child: Icon(Icons.keyboard_arrow_up, color: Colors.orange, size: 28),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    if (_quantity > 0) _quantity--;
                  });
                },
                child: Icon(Icons.keyboard_arrow_down, color: Colors.orange, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}