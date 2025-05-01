import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartfeeder/admin/Ajouterutilisateur.dart';


class GererUtilisateursScreen extends StatefulWidget {
  @override
  _GererUtilisateursScreenState createState() => _GererUtilisateursScreenState();
}

class _GererUtilisateursScreenState extends State<GererUtilisateursScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': !isActive,
        'lastActivity': FieldValue.serverTimestamp(),
      });
      setState(() {});
    } catch (e) {
      print("Erreur lors de la modification du statut: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification du statut')),
      );
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    try {
      // Suppression du compte Firebase si l'email existe
      try {
        List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
        if (signInMethods.isNotEmpty) {
          // Note: Ne pas essayer de se connecter avec un mot de passe par défaut
          // C'est une mauvaise pratique et cela ne fonctionnera pas
          // A la place, cette opération devrait être faite côté admin avec les bonnes permissions
          print("L'utilisateur existe dans Firebase Auth mais ne peut pas être supprimé sans authentification");
        }
      } catch (e) {
        print("Erreur lors de la vérification de l'utilisateur Auth: $e");
      }

      // Suppression du document Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur supprimé avec succès')),
      );
    } catch (e) {
      print("Erreur lors de la suppression: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression de l\'utilisateur')),
      );
    }
  }

  // Vérifie si l'utilisateur est actif en fonction de sa dernière activité
  bool _isUserActive(Map<String, dynamic> userData) {
    final lastActivity = userData['lastActivity'] as Timestamp?;
    final isActive = userData['isActive'] as bool? ?? false;
    
    if (lastActivity == null) return false;
    
    // Considérer l'utilisateur comme actif s'il a eu une activité dans les 5 dernières minutes
    final now = DateTime.now();
    final lastActiveTime = lastActivity.toDate();
    return isActive && now.difference(lastActiveTime).inMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFDF6D2B),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo.png',
          width: 70,
          height: 70,
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Gérer les ',
                    style: TextStyle(
                      color: Color(0xFFDF6D2B),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'Utilisateurs',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 278,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher un utilisateur par nom',
                    labelStyle: TextStyle(fontSize: 11),
                    prefixIcon: Icon(Icons.search),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.orange.shade300, width: 1),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.toLowerCase();
                  return fullName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    var userData = user.data() as Map<String, dynamic>;
                    String userId = user.id;
                    String email = userData['email'] ?? '';
                    String firstName = userData['firstName'] ?? '';
                    String lastName = userData['lastName'] ?? '';
                    bool isActive = _isUserActive(userData);

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text('$firstName $lastName'),
                        subtitle: Text(email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.check_circle : Icons.cancel,
                                    color: isActive ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    isActive ? 'Actif' : 'Inactif',
                                    style: TextStyle(color: isActive ? Colors.green : Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Text(isActive ? 'Désactiver' : 'Activer'),
                                  value: 'toggle',
                                ),
                                PopupMenuItem(
                                  child: Text('Supprimer'),
                                  value: 'delete',
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'toggle') {
                                  await _toggleUserStatus(userId, isActive);
                                } else if (value == 'delete') {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Confirmer la suppression'),
                                      content: Text('Voulez-vous vraiment supprimer cet utilisateur ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _deleteUser(userId, email);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AjouterUtilisateurScreen()),
                  );
                },
                icon: Icon(Icons.add, size: 14),
                label: Text(
                  'Ajouter Utilisateur',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: Size(149.02, 50),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}