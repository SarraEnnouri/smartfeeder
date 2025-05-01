import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartfeeder/aide.dart';
import 'package:smartfeeder/login.dart';
import 'package:smartfeeder/user/calendrier.dart';
import 'package:smartfeeder/user/historiqueuser.dart';
import 'package:smartfeeder/user/userac.dart';
import 'alertuser.dart';


class Profileuser extends StatefulWidget {
  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<Profileuser > {
  String firstName = '';
  String lastName = '';
  String email = '';
  bool isLoading = true;
  String statusMessage = '';
  File? image;
  String imageUrl = '';

  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            firstName = userDoc.data()?['firstName'] ?? '';
            lastName = userDoc.data()?['lastName'] ?? '';
            email = userDoc.data()?['email'] ?? '';
            imageUrl = userDoc.data()?['imageUrl'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusMessage = 'Erreur de chargement du profil';
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement du profil')),
      );
    }
  }

  Future<void> _pickImage() async {
  try {
    // Demander la permission d'accéder aux photos
    final PermissionStatus status = await Permission.photos.request();

    if (status.isGranted) {
      // Permission accordée, continuer avec la sélection de l'image
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        isLoading = true;
        image = File(pickedFile.path);
      });

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      // Préparer l'upload
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      // Metadata pour améliorer la compatibilité
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': user.uid,
          'uploaded_at': DateTime.now().toString(),
        },
      );

      // Upload avec gestion de progression
      final UploadTask uploadTask = storageRef.putFile(
        image!,
        metadata,
      );

      // Suivre la progression
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Progression de l\'upload: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Attendre la complétion
      final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

      // Récupérer l'URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Mettre à jour Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'imageUrl': downloadUrl});

      // Mettre à jour l'état local
      if (mounted) {
        setState(() {
          imageUrl = downloadUrl;
          isLoading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour avec succès')),
      );
    } else {
      // Permission refusée, afficher un message à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accès aux photos refusé')),
      );
    }
  } catch (e) {
    print('Erreur détaillée: $e');
    if (mounted) {
      setState(() => isLoading = false);
    }
    String errorMessage = 'Erreur lors du téléchargement de l\'image';
    if (e is FirebaseException) {
      errorMessage = 'Erreur Firebase: ${e.message}';
    } else if (e is PlatformException) {
      errorMessage = 'Erreur de plateforme: ${e.message}';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

  void _editProfile() {
    TextEditingController firstNameController =
        TextEditingController(text: firstName);
    TextEditingController lastNameController =
        TextEditingController(text: lastName);
    TextEditingController emailController = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modifier le profil"),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Prénom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre prénom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("Changer la photo de profil"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  setState(() {
                    isLoading = true;
                  });

                  await _updateProfile(
                    firstNameController.text,
                    lastNameController.text,
                    emailController.text,
                  );

                  if (mounted) {
                    setState(() {
                      firstName = firstNameController.text;
                      lastName = lastNameController.text;
                      email = emailController.text;
                      isLoading = false;
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profil mis à jour avec succès')),
                  );
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la mise à jour')),
                  );
                }
              }
            },
            child: Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(
      String newFirstName, String newLastName, String newEmail) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'firstName': newFirstName,
        'lastName': newLastName,
        'email': newEmail,
      });

      if (user.email != newEmail) {
        await user.updateEmail(newEmail);
      }
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

  Widget _buildOptionItem(IconData icon, String label, {bool isLogout = false}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: Color(0xFFF8D4BA), size: 20),
          ),
          title: Text(label, style: TextStyle(fontSize: 16)),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            if (isLogout) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirmation'),
                  content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      child: Text('Oui'),
                    ),
                  ],
                ),
              );
            } else if (label == 'Aide') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AidePage()));
            } else if (label == 'Alertes') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => Alertuser()));
            } else if (label == 'Historique') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => Historiqueuser()));
            } else if (label == 'Plans') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarPage()));
            } else if (label == 'Mot de passe') {
              _changePassword();
            }
          },
        ),
        Divider(height: 1, color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.person, size: 50),
                        )
                      : Icon(Icons.person, size: 50),
                ),
              ),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  onPressed: _pickImage,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '$firstName $lastName',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 5),
              GestureDetector(
                onTap: _editProfile,
                child: Icon(Icons.edit, size: 16, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _buildOptionItem(Icons.notifications, 'Alertes'),
          _buildOptionItem(Icons.history, 'Historique'),
          _buildOptionItem(Icons.help_outline, 'Aide'),
          _buildOptionItem(Icons.lock_outline, 'Mot de passe'),
          _buildOptionItem(Icons.calendar_today, 'Plans'),
          _buildOptionItem(Icons.logout, 'Déconnexion', isLogout: true),
        ],
      ),
    );
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardPage()),
              );
            },
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildSettingsList(),
                  if (statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        statusMessage,
                        style: TextStyle(
                          color: statusMessage.contains("Erreur")
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}