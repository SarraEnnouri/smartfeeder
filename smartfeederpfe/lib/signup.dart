import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String confirmPassword = '';
  String email = '';
  String firstName = '';
  String lastName = '';
  String password = '';
  String userType = 'user';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordVisible = false;
  bool _isTermsAccepted = false;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez accepter les termes et conditions')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      String collectionName = userType == 'admin' ? 'admin' : 'users';

      await _firestore.collection(collectionName).doc(userCredential.user?.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user?.uid,
      });

      _showEmailConfirmationDialog(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Erreur lors de l\'inscription';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible';
          break;
        case 'email-already-in-use':
          errorMessage = 'Un compte existe déjà avec cet email';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEmailConfirmationDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer votre email'),
          content: Text('Avez-vous reçu un email pour confirmer votre adresse ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Non'),
            ),
            TextButton(
              onPressed: () async {
                await checkEmailVerified(user);
              },
              child: Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkEmailVerified(User user) async {
    await user.reload();
    if (_auth.currentUser?.emailVerified ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vous pouvez maintenant vous connecter')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez vérifier votre email avant de vous connecter.')),
      );
    }
  }

  Widget _buildRoundedTextField({
    required String label,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isPasswordField = false,
    bool isConfirmPasswordField = false,
  }) {
    return TextFormField(
      decoration: _inputDecoration(
        label,
        isPasswordField: isPasswordField || isConfirmPasswordField,
        showPassword: isPasswordField ? _isPasswordVisible : _isConfirmPasswordVisible,
        onToggleVisibility: () {
          setState(() {
            if (isPasswordField) {
              _isPasswordVisible = !_isPasswordVisible;
            } else if (isConfirmPasswordField) {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            }
          });
        },
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: TextStyle(fontSize: 18),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
        if (label.contains('Email') && !value.contains('@')) return 'Email invalide';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    bool isPasswordField = false,
    bool showPassword = false,
    VoidCallback? onToggleVisibility,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.orange, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.orange, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[200],
      suffixIcon: isPasswordField
          ? IconButton(
              icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggleVisibility,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: 30),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        children: [
                          TextSpan(text: 'Smart ', style: TextStyle(color: Colors.orange)),
                          TextSpan(text: 'Feeder'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text("Login", style: TextStyle(color: Colors.black, fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Column(
                        children: [
                          const Text("Sign Up",
                              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                          Container(width: 50, height: 4, color: Colors.black),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text('Sign Up', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                const Text(
                  "Optimisez l'alimentation et l'hydratation de votre poule avec Smart Feeder !",
                  style: TextStyle(fontSize: 18, color: Color(0xFF505962)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const CircleAvatar(radius: 65, backgroundImage: AssetImage('assets/images/up.png')),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoundedTextField(
                              label: "Prénom",
                              onChanged: (value) => firstName = value,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildRoundedTextField(
                              label: "Nom",
                              onChanged: (value) => lastName = value,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildRoundedTextField(
                        label: "Email",
                        onChanged: (value) => email = value,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 250,
                          child: DropdownButtonFormField<String>(
                            value: userType,
                            decoration: _inputDecoration("Type d'utilisateur"),
                            items: const [
                              DropdownMenuItem(
                                  value: 'user',
                                  child: Text("Utilisateur", style: TextStyle(fontWeight: FontWeight.bold))),
                              DropdownMenuItem(
                                  value: 'admin',
                                  child: Text("Admin", style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (value) => setState(() => userType = value!),
                            validator: (value) => value == null ? 'Sélectionnez un type' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildRoundedTextField(
                        label: "Mot de passe",
                        onChanged: (value) => password = value,
                        obscureText: !_isPasswordVisible,
                        isPasswordField: true,
                      ),
                      const SizedBox(height: 20),
                      _buildRoundedTextField(
                        label: "Confirmation du mot de passe",
                        onChanged: (value) => confirmPassword = value,
                        obscureText: !_isConfirmPasswordVisible,
                        isConfirmPasswordField: true,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: _isTermsAccepted,
                            onChanged: (value) => setState(() => _isTermsAccepted = value!),
                            activeColor: Color(0xFFF06500),
                          ),
                          const Text(
                            "J'accepte les termes et conditions",
                            style: TextStyle(decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Créer un compte',
                                style: TextStyle(fontSize: 26, color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
