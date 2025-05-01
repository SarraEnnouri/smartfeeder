import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AjouterUtilisateurScreen extends StatefulWidget {
  @override
  _AjouterUtilisateurScreenState createState() => _AjouterUtilisateurScreenState();
}

class _AjouterUtilisateurScreenState extends State<AjouterUtilisateurScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isFormValid = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory(String action, String details, {bool isError = false}) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('historique').add({
        'action': action,
        'details': details,
        'timestamp': Timestamp.now(),
        'categorie' : 'utilisateur' ,
        'userEmail': user?.email ?? 'Admin',
        'userId': user?.uid ?? 'system',
        'isError': isError,
      });
    } catch (error) {
      print("Erreur lors de la sauvegarde dans l'historique: $error");
    }
  }

  bool _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isGmail = email.endsWith('@gmail.com');
    final isPasswordValid = password.length >= 7;

    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        isGmail &&
        isPasswordValid;
  }

  Future<void> _addUser() async {
    setState(() => _isLoading = true);
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      await _firestore.collection('users').doc(userId).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });

      // Sauvegarde dans l'historique
      await _saveToHistory(
        'Ajout utilisateur',
        'Nouvel utilisateur ajouté: $firstName $lastName ($email)',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Utilisateur ajouté avec succès !')),
      );

      Navigator.pop(context);
    } catch (e) {
      // Sauvegarde de l'erreur dans l'historique
      await _saveToHistory(
        'Erreur ajout utilisateur',
        'Échec de l\'ajout de l\'utilisateur: ${e.toString()}',
        isError: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur : ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputStyle(String label) {
    const Color customOrange = Color(0xFFDF6D2B);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: Colors.black),
      filled: true,
      fillColor: Colors.grey.shade100,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: customOrange, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color customOrange = Color(0xFFDF6D2B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: customOrange),
        title: Image.asset(
          'assets/images/logo.png',
          width: 70,
          height: 70,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Colors.white,
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            children: [
              Center(
                child: Text(
                  "Ajouter Utilisateur",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _firstNameController,
                decoration: _inputStyle("Prénom"),
                onChanged: (_) => setState(() => _isFormValid = _validateForm()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: _inputStyle("Nom"),
                onChanged: (_) => setState(() => _isFormValid = _validateForm()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputStyle("Email").copyWith(
                  errorText: _emailController.text.isNotEmpty &&
                          !_emailController.text.trim().endsWith('@gmail.com')
                      ? 'L\'email doit se terminer par @gmail.com'
                      : null,
                ),
                onChanged: (_) => setState(() => _isFormValid = _validateForm()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputStyle("Mot de passe").copyWith(
                  errorText: _passwordController.text.isNotEmpty &&
                          _passwordController.text.trim().length < 7
                      ? 'Le mot de passe doit contenir au moins 7 caractères'
                      : null,
                ),
                onChanged: (_) => setState(() => _isFormValid = _validateForm()),
              ),
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: _isFormValid && !_isLoading ? _addUser : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      _isFormValid && !_isLoading ? customOrange : Colors.grey.shade400),
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Ajouter",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}