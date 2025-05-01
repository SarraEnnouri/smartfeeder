import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'password.dart';
import 'user/userac.dart';
import 'admin/adminac.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  Color _messageColor = Colors.red;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/back.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 20),
                  _buildTitle(),
                  const SizedBox(height: 20),
                  _buildForm(),
                  const SizedBox(height: 10),
                  _buildForgotPasswordLink(),
                  _buildTermsAndConditions(),
                  const SizedBox(height: 20),
                  _buildSignInButton(),
                  const SizedBox(height: 16),
                  _buildOrSeparator(),
                  const SizedBox(height: 10),
                  _buildGoogleSignInButton(),
                  if (_errorMessage.isNotEmpty) _buildErrorMessage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 4,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      height: 80,
    );
  }

  Widget _buildTitle() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Smart',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFD9634),
            ),
          ),
          TextSpan(
            text: ' Feeder',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildPasswordField(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: "Email",
        labelStyle: TextStyle(color: Color(0xFFF06500)),
        prefixIcon: Icon(Icons.email, color: Color.fromARGB(193, 198, 198, 198)),
        hintText: "Entrez votre email",
        hintStyle: TextStyle(color: Color(0xFFB5B5B6)),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFB5B5B6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFF06500)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFB5B5B6)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _isObscure,
      decoration: InputDecoration(
        labelText: "Mot de passe",
        labelStyle: TextStyle(color: Color(0xFFF06500)),
        prefixIcon: Icon(Icons.lock, color: Color.fromARGB(193, 198, 198, 198)),
        hintText: "Entrez votre mot de passe",
        hintStyle: TextStyle(color: Color(0xFFB5B5B6)),
        filled: true,
        fillColor: const Color.fromARGB(255, 255, 255, 255),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFB5B5B6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFF06500)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFB5B5B6)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility : Icons.visibility_off,
            color: Color.fromARGB(193, 198, 198, 198),
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Password()),
          );
        },
        child: const Text(
          "Mot de passe oublié?",
          style: TextStyle(
            color: Color(0xFFF06500),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value!;
            });
          },
          activeColor: Color(0xFFF06500),
        ),
        Expanded(
          child: const Text(
            "J'accepte les conditions générales.",
            style: TextStyle(color: Color(0xFFB5B5B6)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
      ),
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : const Text(
              "Se connecter",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
    );
  }

  Widget _buildOrSeparator() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Divider(
              thickness: 3,
              color: Color(0xFFF06500),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "OU",
              style: TextStyle(
                color: Color(0xFFF06500),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              thickness: 3,
              color: Color(0xFFF06500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return GestureDetector(
      onTap: _isLoading ? null : signInWithGoogle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/google.webp',
              height: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              "Se connecter avec Google",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _messageColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Dans le cas de l'authentification Google,
  // si l'utilisateur n'existe pas déjà, on affiche une boîte de dialogue pour choisir le rôle
  Future<String?> _showRoleSelectionDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Choisir votre rôle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Utilisateur"),
                onTap: () => Navigator.pop(context, 'user'),
              ),
              ListTile(
                title: Text("Admin"),
                onTap: () => Navigator.pop(context, 'admin'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        setState(() {
          _errorMessage = "Veuillez accepter les conditions générales.";
          _messageColor = Colors.red;
        });
        return;
      }
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Recherche dans la collection "users"
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user?.uid)
            .get();

        // Si l'utilisateur n'est pas trouvé, rechercher dans la collection "admin"
        if (!userDoc.exists) {
          DocumentSnapshot adminDoc = await _firestore
              .collection('admin')
              .doc(userCredential.user?.uid)
              .get();
          if (adminDoc.exists) {
            userDoc = adminDoc;
          }
        }

        if (!userDoc.exists) {
          throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'Utilisateur non trouvé dans la base de données');
        }

        String userType = userDoc.get('userType') ?? 'user';

        setState(() {
          _errorMessage = "Connexion réussie!";
          _messageColor = Colors.green;
        });

        _redirectBasedOnUserType(userType);
       
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = "Identifiants incorrects ou utilisateur non trouvé";
          _messageColor = Colors.red;
        });
      } catch (e) {
        setState(() {
          _errorMessage = "Erreur inattendue: ${e.toString()}";
          _messageColor = Colors.red;
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Recherche le document dans la collection "users"
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();
      
      if (!userDoc.exists) {
        // Si nouvel utilisateur, demander le rôle
        final String? selectedRole = await _showRoleSelectionDialog();
        if (selectedRole == null) {
          await _googleSignIn.signOut();
          await FirebaseAuth.instance.signOut();
          setState(() => _isLoading = false);
          return;
        }

        // Selon le rôle sélectionné, stocker dans la collection appropriée
        if (selectedRole == 'admin') {
          await _firestore.collection('admin').doc(userCredential.user?.uid).set({
            'firstName': googleUser.displayName?.split(' ').first ?? '',
            'lastName': googleUser.displayName?.split(' ').last ?? '',
            'email': googleUser.email,
            'userType': selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
            'uid': userCredential.user?.uid,
          });
        } else {
          await _firestore.collection('users').doc(userCredential.user?.uid).set({
            'firstName': googleUser.displayName?.split(' ').first ?? '',
            'lastName': googleUser.displayName?.split(' ').last ?? '',
            'email': googleUser.email,
            'userType': selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
            'uid': userCredential.user?.uid,
          });
        }

        _redirectBasedOnUserType(selectedRole);
      } else {
        // Utilisateur existant, si besoin, on peut vérifier la collection
        String userType = userDoc.get('userType') ?? 'user';
        _redirectBasedOnUserType(userType);
      }

      setState(() {
        _errorMessage = "Connexion Google réussie!";
        _messageColor = Colors.green;
      });
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = "Erreur Google: ${e.message}";
        _messageColor = Colors.red;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur inattendue: ${e.toString()}";
        _messageColor = Colors.red;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _redirectBasedOnUserType(String userType) {
    if (userType == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminAcPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    }
  }
}