import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String _confirmPassword = '';
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _password = '';
  String _userType = 'user';
  
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordVisible = false;
  bool _isTermsAccepted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isTermsAccepted) {
      _showSnackBar('Veuillez accepter les termes et conditions');
      return;
    }
    if (_password != _confirmPassword) {
      _showSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      await userCredential.user?.sendEmailVerification();

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'firstName': _firstName,
        'lastName': _lastName,
        'email': _email,
        'userType': _userType,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'uid': userCredential.user?.uid,
      });
 await _sendSignupAlert();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              user: userCredential.user!,
              email: _email,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage = 'Erreur lors de l\'inscription';
    switch (e.code) {
      case 'weak-password':
        errorMessage = 'Le mot de passe doit contenir au moins 8 caractères';
        break;
      case 'email-already-in-use':
        errorMessage = 'Un compte existe déjà avec cet email';
        break;
      case 'invalid-email':
        errorMessage = 'Email invalide';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Opération non autorisée';
        break;
    }
    _showSnackBar(errorMessage);
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
      decoration: InputDecoration(
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
        suffixIcon: isPasswordField || isConfirmPasswordField
            ? IconButton(
                icon: Icon(
                  isPasswordField 
                    ? _isPasswordVisible 
                      ? Icons.visibility 
                      : Icons.visibility_off
                    : _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    if (isPasswordField) {
                      _isPasswordVisible = !_isPasswordVisible;
                    } else {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    }
                  });
                },
              )
            : null,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: TextStyle(fontSize: 18),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ce champ est obligatoire';
        if (label.contains('Email') && !value.contains('@')) return 'Email invalide';
        if (label.contains('Mot de passe') && value.length < 6) {
          return '6 caractères minimum';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              _buildAppHeader(),
              SizedBox(height: 30),
              Text('Sign Up', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text(
                "Optimisez l'alimentation et l'hydratation de votre poule avec Smart Feeder !",
                style: TextStyle(fontSize: 18, color: Color(0xFF505962)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              CircleAvatar(radius: 65, backgroundImage: AssetImage('assets/images/up.png')),
              SizedBox(height: 30),
              _buildSignUpForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Row(
      children: [
        Image.asset('assets/images/logo.png', height: 30),
        SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            children: [
              TextSpan(text: 'Smart ', style: TextStyle(color: Colors.orange)),
              TextSpan(text: 'Feeder'),
            ],
          ),
        ),
        Spacer(),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: Text("Login", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        TextButton(
          onPressed: () {},
          child: Column(
            children: [
              Text("Sign Up",
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(width: 50, height: 4, color: Colors.black),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildRoundedTextField(
                  label: "Prénom",
                  onChanged: (value) => _firstName = value,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildRoundedTextField(
                  label: "Nom",
                  onChanged: (value) => _lastName = value,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildRoundedTextField(
            label: "Email",
            onChanged: (value) => _email = value,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 20),
          _buildUserTypeDropdown(),
          SizedBox(height: 20),
          _buildRoundedTextField(
            label: "Mot de passe",
            onChanged: (value) => _password = value,
            obscureText: !_isPasswordVisible,
            isPasswordField: true,
          ),
          SizedBox(height: 20),
          _buildRoundedTextField(
            label: "Confirmation du mot de passe",
            onChanged: (value) => _confirmPassword = value,
            obscureText: !_isConfirmPasswordVisible,
            isConfirmPasswordField: true,
          ),
          SizedBox(height: 20),
          _buildTermsCheckbox(),
          SizedBox(height: 30),
          _buildSignUpButton(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildUserTypeDropdown() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 250,
        child: DropdownButtonFormField<String>(
          value: _userType,
          decoration: InputDecoration(
            labelText: "Type d'utilisateur",
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
          ),
          items: [
            DropdownMenuItem(
              value: 'user',
              child: Text("Utilisateur", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DropdownMenuItem(
              value: 'admin',
              child: Text("Admin", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          onChanged: (value) => setState(() => _userType = value!),
          validator: (value) => value == null ? 'Sélectionnez un type' : null,
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _isTermsAccepted,
          onChanged: (value) => setState(() => _isTermsAccepted = value!),
          activeColor: Color(0xFFF06500),
        ),
        Text(
          "J'accepte les termes et conditions",
          style: TextStyle(decoration: TextDecoration.underline),
        ),
      ],
    );
  }
 Future<void> _sendSignupAlert() async {
  try {
    await FirebaseFirestore.instance.collection('alerts').add({
      'title': 'Nouvel utilisateur inscrit',
      'type': 'user_signup',
      'status': 'active',
      'details': 'Email: $_email | Type: $_userType',
      'createdAt': FieldValue.serverTimestamp(),
      'priority': 2, // Moyenne priorité
      'userId': _auth.currentUser?.uid,
    });
  } catch (e) {
    print("Erreur envoi alerte: $e");
  }
} 

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _registerUser,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
      ),
      child: _isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Créer un compte',
              style: TextStyle(fontSize: 26, color: Colors.white),
            ),
    );
  }
}

class EmailVerificationScreen extends StatefulWidget {
  final User user;
  final String email;

  EmailVerificationScreen({required this.user, required this.email});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isLoading = false;
  bool _isVerified = false;
  int _resendCooldown = 60;

  @override
  void initState() {
    super.initState();
    _startVerificationTimer();
    _checkEmailVerified(); // Vérifie immédiatement l'état de vérification
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Vérifie périodiquement si l'email est vérifié
  void _startVerificationTimer() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await widget.user.reload();
      if (widget.user.emailVerified) {
        timer.cancel();
        if (mounted) {
          setState(() => _isVerified = true); // Met à jour l'état
          _navigateToLogin();
        }
      }
    });
  }

  // Vérifie manuellement l'état de vérification
  Future<void> _checkEmailVerified() async {
    await widget.user.reload();
    if (widget.user.emailVerified && mounted) {
      setState(() => _isVerified = true); // Met à jour _isVerified
      _navigateToLogin();
    }
  }

  // Rafraîchit manuellement l'état de vérification
  Future<void> _refreshVerificationStatus() async {
    setState(() => _isLoading = true);
    await widget.user.reload();
    if (widget.user.emailVerified) {
      setState(() => _isVerified = true);
      _navigateToLogin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("L'email n'est pas encore vérifié.")),
      );
    }
    setState(() => _isLoading = false);
  }

  // Renvoie l'email de vérification
  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await widget.user.sendEmailVerification();
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email de vérification renvoyé!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Démarrer le compte à rebours pour le renvoi
  void _startResendCooldown() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 60);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  // Redirige vers la page de connexion
  void _navigateToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vérification Email'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 80, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                'Vérification requise',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Un email de vérification a été envoyé à:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5),
              Text(
                widget.email,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              if (_isLoading)
                CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _resendCooldown == 60
                          ? _resendVerificationEmail
                          : null,
                      child: Text(
                        _resendCooldown == 60
                            ? 'Renvoyer l\'email'
                            : 'Renvoyer ($_resendCooldown)',
                      ),
                    ),
                  
                   
                   
                    SizedBox(height: 20),
                    // Bouton "J'ai vérifié mon email"
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: Text('J\'ai vérifié mon email'),
                    ),
                  ],
                ),
              SizedBox(height: 20),
              Text(
                'Si vous ne voyez pas l\'email, vérifiez votre dossier spam ou attendez quelques minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}  