import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartfeeder/aide.dart';
import 'package:smartfeeder/login.dart';
import 'adminac.dart'; // Assurez-vous que ce fichier existe
import 'alertadmin.dart'; // Assurez-vous que ce fichier existe
import 'chat.dart'; // Assurez-vous que ce fichier existe

class Profileadmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profile Settings',
      theme: ThemeData(
        fontFamily: 'Arial',
        primarySwatch: Colors.orange,
      ),
      home: ProfileSettingsPage(),
    );
  }
}

class ProfileSettingsPage extends StatefulWidget {
  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  String firstName = '';
  String lastName = '';
  String email = '';
  File? image;
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    User? admin = FirebaseAuth.instance.currentUser;
    if (admin != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('admin').doc(admin.uid).get();
      if (userDoc.exists) {
        setState(() {
          firstName = userDoc['firstName'] ?? '';
          lastName = userDoc['lastName'] ?? '';
          email = userDoc['email'] ?? '';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
    }
  }
  void _changePassword() {
    final currentController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Changer le mot de passe"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Mot de passe actuel'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est obligatoire';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est obligatoire';
                    }
                    if (value.length < 8) {
                      return 'Minimum 8 caractères';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Confirmer le mot de passe'),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Confirmer"),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || user.email == null) return;

                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                      content: Text('Mot de passe changé avec succès'),
                    ),
                  );
                } catch (e) {
                  String errorMessage = "Une erreur s'est produite.";
                  if (e is FirebaseAuthException) {
                    switch (e.code) {
                      case 'wrong-password':
                        errorMessage = "Le mot de passe actuel est incorrect.";
                        break;
                      case 'weak-password':
                        errorMessage = "Le nouveau mot de passe est trop faible.";
                        break;
                      case 'requires-recent-login':
                        errorMessage = "Reconnectez-vous pour changer le mot de passe.";
                        break;
                      default:
                        errorMessage = e.message ?? errorMessage;
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                      content: Text(errorMessage),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
  void _editProfile() {
    TextEditingController firstNameController = TextEditingController(text: firstName);
    TextEditingController lastNameController = TextEditingController(text: lastName);
    TextEditingController emailController = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modifier le profil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: 'Prénom'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Choisir une image"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer la boîte de dialogue sans sauvegarder
            },
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              // Validation des champs
              if (firstNameController.text.isEmpty ||
                  lastNameController.text.isEmpty ||
                  emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez remplir tous les champs')),
                );
                return;
              }
              setState(() {
                firstName = firstNameController.text;
                lastName = lastNameController.text;
                email = emailController.text;
              });
              await _updateProfile(firstName, lastName, email);
              Navigator.pop(context);
              // Afficher un message de confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profil mis à jour avec succès')),
              );
            },
            child: Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String newFirstName, String newLastName, String newEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('admin').doc(user.uid).update({
        'firstName': newFirstName,
        'lastName': newLastName,
        'email': newEmail,
      }).then((_) {
        print("Profil mis à jour avec succès");
      }).catchError((error) {
        print("Erreur lors de la mise à jour du profil : $error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 232, 221, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminAcPage()),
                );
              }
            },
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      _buildProfileHeader(constraints),
                      _buildSettingsList(constraints),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildProfileHeader(BoxConstraints constraints) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: screenWidth * 0.12, // Taille relative à la largeur de l'écran
                backgroundImage: image != null
                    ? FileImage(image!)
                    : AssetImage('assets/profile_picture.jpg') as ImageProvider,
              ),
              Container(
                padding: EdgeInsets.all(6),
                child: IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.black),
                  onPressed: _pickImage,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '$firstName $lastName',
            style: TextStyle(
              fontSize: screenWidth * 0.05, // Taille relative à la largeur de l'écran
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                email,
                style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.black87),
              ),
              SizedBox(width: 5),
              GestureDetector(
                onTap: _editProfile,
                child: Icon(Icons.edit, size: screenWidth * 0.04, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BoxConstraints constraints) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          topRight: Radius.circular(70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Paramètres',
              style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
            ),
          ),
          _buildOptionItem(Icons.notifications, 'Alertes', screenWidth),
          _buildOptionItem(Icons.help_outline, 'Aide', screenWidth),
          _buildOptionItem(Icons.chat, 'Chat en direct', screenWidth),
          _buildOptionItem(Icons.lock_outline, 'Mot de passe', screenWidth),
          _buildOptionItem(Icons.logout, 'Déconnexion', screenWidth, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String label, double screenWidth, {bool isLogout = false}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: screenWidth * 0.1,
            height: screenWidth * 0.1,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 8, 8, 8),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: Colors.white, size: screenWidth * 0.05),
          ),
          title: Text(
            label,
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04, color: Colors.grey),
          onTap: () {
            if (isLogout) {
              logout();
            } else if (label == 'Alertes') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Alerteadmin()),
              );
            } else if (label == 'Chat en direct') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatVetPage()),
              );
            }else if (label == 'Aide') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>AidePage()),
              );
            }else if (label == 'Mot de passe') {
              _changePassword();
          } }
        ), 
        Divider(color: Colors.grey[300]),
      ],
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Déconnexion"),
        content: Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
        actions: [
          TextButton(
            child: Text("Non"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text("Oui"),
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
          ),
        ],
      ),
    );
  }
}