import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mettre à jour l'état de l'utilisateur (Actif/Inactif) avec gestion d'erreur
  Future<void> updateUserStatus(bool isActive) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isActive': isActive,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut utilisateur: $e');
      // Vous pourriez relancer l'exception ou gérer l'erreur différemment
    }
  }

  // Obtenir une liste d'utilisateurs avec leur statut
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  // Fonction pour connecter un utilisateur avec gestion améliorée
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      // Connexion de l'utilisateur avec Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Mise à jour du statut après connexion réussie
      await updateUserStatus(true);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Erreur Firebase Auth lors de la connexion: ${e.code} - ${e.message}');
      rethrow; // Permet à l'UI de gérer l'erreur spécifique
    } catch (e) {
      print('Erreur inattendue lors de la connexion: $e');
      rethrow;
    }
  }

  // Fonction pour déconnecter un utilisateur avec garantie de mise à jour du statut
  Future<void> signOut() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // D'abord mettre à jour le statut
        await updateUserStatus(false);
        
        // Ensuite déconnecter l'utilisateur
        await _auth.signOut();
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      // Même si la déconnexion échoue, on essaie quand même de mettre à jour le statut
      try {
        await _auth.signOut(); // Tentative supplémentaire
      } catch (_) {}
      rethrow;
    }
  }

  // Fonction pour vérifier si l'utilisateur est connecté
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Fonction pour obtenir l'ID de l'utilisateur actuel
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}