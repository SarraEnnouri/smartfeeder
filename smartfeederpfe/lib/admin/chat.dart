import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
 import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'alertadmin.dart';
import 'adminac.dart';
import 'profiladmin.dart';


class ChatVetPage extends StatefulWidget {
  @override
  _ChatVetPageState createState() => _ChatVetPageState();
}

class _ChatVetPageState extends State<ChatVetPage> {
  List<Map<String, String>> messages = [];
  final TextEditingController _controllerQuery = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isConnected = true;



 

  Future<void> sendMessage() async {
    final userInput = _controllerQuery.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      messages.insert(0, {"role": "user", "content": userInput});
      _isLoading = true;
      _controllerQuery.clear();
    });

    try {
      if (!_isConnected) {
        setState(() {
          messages.insert(0, {
            "role": "assistant",
            "content": "Pas de connexion internet. Veuillez vous connecter.",
          });
        });
        return;
      }

      final content = await _callGeminiAPI(userInput);
      setState(() {
        messages.insert(0, {"role": "assistant", "content": content});
      });
    } catch (e) {
      setState(() {
        messages.insert(0, {
          "role": "assistant",
          "content": "Erreur de connexion au service. Veuillez réessayer.",
        });
      });
      debugPrint('API Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _callGeminiAPI(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']!;
    const modelName = 'gemini-2.0-flash';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": "Réponds comme un vétérinaire spécialisé en volailles. "
                    "Répondez en français de manière claire et concise.\n\n"
                    "Question: $prompt\n\n"
                    "Réponse:"
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "topP": 0.9,
          "topK": 40,
          "maxOutputTokens": 1000
        },
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]['content']['parts'][0]['text'] ??
          "Je n'ai pas pu générer de réponse.";
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> searchOnWeb() async {
    if (_searchController.text.isEmpty) return;
    
    final query = Uri.encodeComponent("${_searchController.text} site:veterinaire.fr");
    final url = "https://www.google.com/search?q=$query";
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("Impossible d'ouvrir le navigateur");
      }
    } catch (e) {
      _showSnackBar("Erreur lors du lancement de la recherche");
      debugPrint('Launch URL error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildArticleCard({
    required Color backgroundColor,
    required String image,
    required String title,
    required String description,
    required String url,
  }) {
    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _launchURL(url),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(
                  image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Container(color: Colors.grey[200]),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("Impossible d'ouvrir le lien");
      }
    } catch (e) {
      _showSnackBar("Erreur lors de l'ouverture du lien");
      debugPrint('URL launch error: $e');
    }
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message["role"] == "user";
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: 
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.orange[100] : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 12 : 0),
                  topRight: Radius.circular(isUser ? 0 : 12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                message["content"]!,
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildBottomNavigationBar() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    child: BottomNavigationBar(
      backgroundColor: Colors.grey[200],
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      currentIndex: 1, // Index pour l'icône "article" qui est la page actuelle
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.article), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Alerteadmin()),
            );
            break;
          case 1:
            // Ne rien faire car on est déjà sur cette page
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminAcPage()),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Profileadmin()),
            );
            break;
        }
      },
    ),
  );
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: Image.asset(
          'assets/images/logo.png', 
          width: 50, 
          height: 50,
         
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => Alerteadmin())
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: const [
                            TextSpan(text: 'Articles Santé & '),
                            TextSpan(
                              text: 'Consultation IA',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                   Row(
              children: [
                Spacer(), // pousse le champ vers la droite
                Container(
                  width: 300, // largeur du champ de texte
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => searchOnWeb(),
                    decoration: InputDecoration(
                      labelText: 'Rechercher des articles',
                      prefixIcon: Icon(Icons.search),
                      labelStyle: TextStyle(color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                         focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                                    ),
                  ),
                ),
              ],
            ),

                   
                    SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                      children: [
                        _buildArticleCard(
                          backgroundColor: const Color(0xFFFFF0E3),
                          image: 'assets/images/article1.jpeg',
                          title: "Élever des poules",
                          description: "Comment élever des poules dans les meilleures conditions",
                          url: 'https://poules-club.com/elever-des-poules/',
                        ),
                        _buildArticleCard(
                          backgroundColor: const Color(0xFFFFF0E3),
                          image: 'assets/images/articles2.jpeg',
                          title: "Alimentation pour poules",
                          description: "Conseils pour nourrir vos poules",
                          url: 'http://www.jardiner-malin.fr/conseil-animal/alimentation-poule.html',
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "En quoi puis-je vous aider ?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      constraints: BoxConstraints(minHeight: 100, maxHeight: 300),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              reverse: true,
                              itemCount: messages.length,
                              itemBuilder: (_, index) {
                                return _buildMessageBubble(messages[index]);
                              },
                            ),
                          ),
                          if (_isLoading)
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllerQuery,
                      decoration: InputDecoration(
                        hintText: 'Posez votre question...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.orange),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}