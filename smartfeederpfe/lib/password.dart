import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ignore: use_key_in_widget_constructors
class Password extends StatefulWidget {
  @override
  _PasswordState createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  final TextEditingController _emailController = TextEditingController(); // Contrôleur pour l'email

  // Méthode pour envoyer un email de réinitialisation de mot de passe
  void _sendPasswordResetEmail() async {
    String email = _emailController.text.trim(); // Récupère l'email saisi

    // Vérifie si l'email est vide
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un email valide.')), // Message d'erreur
      );
      return;
    }

    try {
      // Vérifie les méthodes de connexion disponibles pour l'email donné
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      // Envoie l'email de réinitialisation
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Un email de réinitialisation a été envoyé !')), // Message de succès
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cet email n\'est pas enregistré ou erreur lors de l\'envoi.')), // Message d'erreur
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Fond blanc pour l'AppBar
        elevation: 0, // Supprime l'ombre
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFF06500), // Couleur orange pour le bouton retour
            borderRadius: BorderRadius.circular(5),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white), // Icône de retour
            onPressed: () => Navigator.pop(context), // Retourne à l'écran précédent
          ),
        ),
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(
            "Mot de passe oublié", // Titre de la page
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              decoration: TextDecoration.underline, // Sous-ligné
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: false ,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.4, // 40% de la hauteur de l'écran
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // Affiche le logo
                      height: 80,
                    ),
                    SizedBox(height: 10), // Espacement
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Smart', 
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF06500), // Couleur orange
                            ),
                          ),
                          TextSpan(
                            text: ' Feeder', 
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, 
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.orange.shade100], // Dégradé du blanc à l'orange
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Champ pour l'email
                    TextField(
                      controller: _emailController, // Associe le contrôleur
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Color.fromARGB(193, 198, 198, 198)), // Icône d'email
                        hintText: "Entrez votre email", // Texte indicatif
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none, // Supprime la bordure par défaut
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.orange.shade300), // Bordure orange
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.orange), // Bordure orange au focus
                        ),
                      ),
                    ),
                    SizedBox(height: 10), // Espacement
                    Text(
                      "*Nous vous enverrons un message pour réinitialiser votre mot de passe.", 
                      style: TextStyle(fontSize: 12, color: Colors.black54), // Texte explicatif
                    ),
                    SizedBox(height: 20), // Espacement
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Envoyer le code", // Texte à gauche
                          style: TextStyle(fontSize: 20, color: Colors.orange),
                        ),
                        // Bouton pour envoyer le code
                        ElevatedButton.icon(
                          onPressed: _sendPasswordResetEmail, // Appel de la méthode pour envoyer le code
                          icon: Icon(Icons.arrow_forward, color: Colors.white), // Icône de flèche
                          label: Text(""), // Vide pour avoir seulement l'icône
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, // Couleur de fond noire pour le bouton
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding interne
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Coins arrondis
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}