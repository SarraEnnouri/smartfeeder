import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalEditScreen extends StatefulWidget {
  final String speciesName;
  const AnimalEditScreen({Key? key, required this.speciesName}) : super(key: key);

  @override
  _AnimalEditScreenState createState() => _AnimalEditScreenState();
}

class _AnimalEditScreenState extends State<AnimalEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _foodController = TextEditingController();
  final _medicationController = TextEditingController();
  int _quantity = 0;
  TimeOfDay? _medicationTime;
  String? _docId;
  Map<String, dynamic>? _oldValues;

  final Color orangeColor = Color(0xFFE7B48C);
  final Color defaultBorderColor = Colors.grey;

  final FocusNode _foodFocusNode = FocusNode();
  final FocusNode _medicationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadAnimalData();
  }

  @override
  void dispose() {
    _foodFocusNode.dispose();
    _medicationFocusNode.dispose();
    _speciesController.dispose();
    _foodController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimalData() async {
    try {
      var animalDoc = await FirebaseFirestore.instance
          .collection('animals')
          .where('species', isEqualTo: widget.speciesName)
          .limit(1)
          .get();

      if (animalDoc.docs.isEmpty) {
        throw Exception("Animal non trouvé");
      }

      var doc = animalDoc.docs.first;
      var data = doc.data();

      setState(() {
        _docId = doc.id;
        _oldValues = data;
        _speciesController.text = data['species'] ?? '';
        _foodController.text = data['food'] ?? '';
        _medicationController.text = data['medications'] ?? '';
        _quantity = data['quantity'] ?? 0;

        if (data['medicationTime'] != null) {
          final parts = data['medicationTime'].toString().split(':');
          _medicationTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de chargement: ${e.toString()}")),
      );
    }
  }

  Future<void> _saveToHistory(String action, String details, {bool isError = false}) async {
    try {
      await FirebaseFirestore.instance.collection('historique').add({
        'action': action,
        'details': details,
        'timestamp': Timestamp.now(),
        'categorie': 'animal',
        'user': 'Admin',
        'isError': isError,
      });
    } catch (error) {
      debugPrint("Erreur historique: $error");
    }
  }

 Future<void> _sendAlert() async {
  try {
    if (_medicationController.text.isEmpty || _medicationTime == null) {
      throw ArgumentError('Médicament et heure requis');
    }

    // Créer un DateTime basé sur la date actuelle et l'heure sélectionnée
    final DateTime now = DateTime.now();
    final DateTime scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _medicationTime!.hour,
      _medicationTime!.minute,
    );

    await FirebaseFirestore.instance.collection('alertUser').add({
      'title': 'Médicament pour ${_speciesController.text}',
      'description': "Administrer :Modifier ",
      'timestamp': Timestamp.now(),
      'seen': false,
      'type': 'warning',
      'species': _speciesController.text,
      'medication': _medicationController.text,
      'status': 'pending',
      'scheduledTime': Timestamp.fromDate(scheduledDateTime),
    });

  } catch (e) {
    await _saveToHistory('Erreur d\'alerte', e.toString(), isError: true);
    rethrow;
  }
}


  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _medicationTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _medicationTime = picked);
    }
  }

  Future<void> _updateAnimal() async {
    FocusScope.of(context).unfocus();

    if (_speciesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'espèce est obligatoire")),
      );
      return;
    }

    try {
      final updatedData = {
        'species': _speciesController.text.trim(),
        'quantity': _quantity,
        'food': _foodController.text.trim(),
        'medications': _medicationController.text.trim(),
        'lastUpdate': Timestamp.now(),
      };

      if (_medicationTime != null) {
        updatedData['medicationTime'] =
            '${_medicationTime!.hour}:${_medicationTime!.minute.toString().padLeft(2, '0')}';
      }

      await FirebaseFirestore.instance.collection('animals').doc(_docId!).update(updatedData);

      if (_medicationController.text.isNotEmpty && _medicationTime != null) {
        await _sendAlert();
      }

      await _saveToHistory(
        'Modification animal',
        '${_speciesController.text} (Qty: $_quantity)',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Modification réussie")),
      );
      Navigator.pop(context);
    } catch (e) {
      await _saveToHistory('Erreur modification', e.toString(), isError: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focusNode.hasFocus ? orangeColor : defaultBorderColor,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
        color: Colors.white,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          hintStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimePickerField() {
    return InkWell(
      onTap: () => _selectTime(context),
      child: Container(
        height: 50,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _medicationTime != null ? orangeColor : Colors.grey.shade300,
            width: 1.5,
          ),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: _medicationTime != null ? orangeColor : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              _medicationTime != null
                  ? '${_medicationTime!.hour}:${_medicationTime!.minute.toString().padLeft(2, '0')}'
                  : 'Heure',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _medicationTime != null ? Colors.black : Colors.grey,
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
        border: Border.all(
          color: _quantity > 0 ? orangeColor : Colors.grey.shade400,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$_quantity',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => setState(() => _quantity++),
                child: const Icon(Icons.keyboard_arrow_up, color: Colors.orange, size: 28),
              ),
              InkWell(
                onTap: () => setState(() => _quantity = _quantity > 0 ? _quantity - 1 : 0),
                child: const Icon(Icons.keyboard_arrow_down, color: Colors.orange, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _showCancelDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler les modifications'),
          content: const Text('Voulez-vous vraiment annuler ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 600 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier un animal", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.cancel, color: Colors.black),
          onPressed: () async {
            final confirmCancel = await _showCancelDialog(context);
            if (confirmCancel == true) Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFF2E7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildLabel("Nombre d'animaux"),
                            _buildQuantityField(),
                            const SizedBox(height: 20),
                            _buildLabel("Alimentation"),
                            _buildTextField(
                              controller: _foodController,
                              hint: "Mais, Blé, Autre...",
                              focusNode: _foodFocusNode,
                            ),
                            const SizedBox(height: 20),
                            _buildLabel("Médicaments"),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _medicationController,
                                    hint: "Tyloxine, Perméthrine, Autre...",
                                    focusNode: _medicationFocusNode,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _buildTimePickerField(),
                              ],
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _updateAnimal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Modifier",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}