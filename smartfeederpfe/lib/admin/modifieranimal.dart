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

  Future<void> _loadAnimalData() async {
    var animalDoc = await FirebaseFirestore.instance
        .collection('animals')
        .where('species', isEqualTo: widget.speciesName)
        .limit(1)
        .get();

    if (animalDoc.docs.isNotEmpty) {
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
          _medicationTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      });
    }
  }
  
 Future<void> _saveToHistory(String action, String details, {bool isError = false}) async {
  try {
    await FirebaseFirestore.instance.collection('historique').add({
      'action': action,
      'details': details,
      'timestamp': Timestamp.now(),
      'categorie' : 'animal' ,
      'user': 'Admin', // Remplacez par l'utilisateur connecté si disponible
      'isError': isError,
    });
  } catch (error) {
    print("Erreur lors de la sauvegarde dans l'historique: $error");
  }
}
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _medicationTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _medicationTime = picked;
      });
    }
  }
Future<void> _updateAnimal() async {
  if (_docId != null && _oldValues != null) {
    try {
      await FirebaseFirestore.instance.collection('animals').doc(_docId!).update({
        'species': _speciesController.text.trim().isNotEmpty
            ? _speciesController.text.trim()
            : _oldValues!['species'],
        'quantity': _quantity > 0 ? _quantity : _oldValues!['quantity'],
        'food': _foodController.text.trim().isNotEmpty
            ? _foodController.text.trim()
            : _oldValues!['food'],
        'medications': _medicationController.text.trim().isNotEmpty
            ? _medicationController.text.trim()
            : _oldValues!['medications'],
        'medicationTime': _medicationTime != null
            ? '${_medicationTime!.hour}:${_medicationTime!.minute.toString().padLeft(2, '0')}'
            : _oldValues!['medicationTime'],
        'lastUpdate': Timestamp.now(),
      });

      await _saveToHistory(
        'Modification d\'un animal',
        'Espèce: ${_speciesController.text.trim().isNotEmpty ? _speciesController.text.trim() : _oldValues!['species']}, '
        'Quantité: ${_quantity > 0 ? _quantity : _oldValues!['quantity']}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Animal modifié avec succès")),
      );
      Navigator.pop(context);
    } catch (error) {
      await _saveToHistory(
        'Erreur lors de la modification d\'un animal',
        'Erreur: ${error.toString()}',
        isError: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${error.toString()}")),
      );
    }
  }
}

 

  Color _getBorderColor(FocusNode focusNode) {
    return focusNode.hasFocus ? orangeColor : defaultBorderColor;
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
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(focusNode), width: 1.5),
        boxShadow: [BoxShadow(color: const Color.fromARGB(31, 255, 26, 26), blurRadius: 4, offset: Offset(2, 2))],
        color: Colors.white,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
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
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
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


  Future<bool?> _showCancelDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Annuler les modifications'),
          content: Text('Êtes-vous sûr de vouloir annuler toutes les modifications ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Non'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxWidth = screenWidth > 600 ? 600 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: Text("Modifier animaux", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.cancel, color: Colors.black),
          onPressed: () async {
            bool? confirmCancel = await _showCancelDialog(context);
            if (confirmCancel == true) {
              setState(() {
                _speciesController.text = _oldValues?['species'] ?? '';
                _foodController.text = _oldValues?['food'] ?? '';
                _medicationController.text = _oldValues?['medications'] ?? '';
                _quantity = _oldValues?['quantity'] ?? 0;
                if (_oldValues?['medicationTime'] != null) {
                  final parts = _oldValues?['medicationTime'].toString().split(':');
                  _medicationTime = TimeOfDay(hour: int.parse(parts![0]), minute: int.parse(parts[1]));
                }
              });
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFF2E7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: maxWidth,
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
                            SizedBox(height: 20),
                            _buildLabel("Nombre d'animaux"),
                            _buildQuantityField(),
                            SizedBox(height: 20),
                            _buildLabel("Alimentation"),
                            _buildTextField(
                              controller: _foodController,
                              hint: "Mais, Blé, Autre...",
                              focusNode: _foodFocusNode,
                            ),
                            SizedBox(height: 20),
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
                                SizedBox(width: 10),
                                _buildTimePickerField(
                                  value: _medicationTime != null
                                      ? '${_medicationTime!.hour}:${_medicationTime!.minute.toString().padLeft(2, '0')}'
                                      : null,
                                  onTap: () => _selectTime(context),
                                  hint: 'Heure',
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
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
                                child: Text(
                                  "Modifier",
                                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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