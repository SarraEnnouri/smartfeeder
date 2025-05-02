import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:smartfeeder/admin/ajoutanimal.dart';
import 'package:smartfeeder/admin/alertadmin.dart';
import 'package:smartfeeder/admin/chat.dart';
import 'package:smartfeeder/admin/gereuser.dart';
import 'package:smartfeeder/admin/gestionanimal.dart';
import 'package:smartfeeder/admin/historiqueadmin.dart';
import 'package:smartfeeder/admin/profiladmin.dart';

class AdminAcPage extends StatefulWidget {
  @override
  _AdminAcPageState createState() => _AdminAcPageState();
}

class _AdminAcPageState extends State<AdminAcPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Variables pour Gemini AI
  bool _showGeminiPanel = false;
  String _selectedStatistic = '';
  String _geminiResponse = '';
  bool _isLoadingGemini = false;
  bool _hasError = false;

  // Variables pour les totaux de consommation
  double _totalWater = 0;
  double _totalFood = 0;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadInitialData();
    _calculateTotals();
  }

  Future<void> _initializeGemini() async {
    await dotenv.load();
  }

  Future<void> _loadInitialData() async {
    final snapshot = await _firestore.collection('consommation')
      .orderBy('date', descending: true)
      .limit(1)
      .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _lastUpdate = (snapshot.docs.first.data()['date'] as Timestamp).toDate();
      });
    }
  }

  Future<Map<String, int>> _calculateFoodDistribution() async {
    try {
      final snapshot = await _firestore.collection('consommation').get();
      final distribution = <String, int>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['typeAliment'] as String? ?? 'Autre';
        final quantity = (data['nourriture'] as num? ?? 0).toInt();

        distribution.update(
          type,
          (value) => value + quantity,
          ifAbsent: () => quantity,
        );
      }

      return distribution;
    } catch (e) {
      print('Erreur calcul distribution alimentaire: $e');
      return {
        'Blé': 2500,
        'Maïs': 1500,
        'Autre': 1000,
      };
    }
  }

  Color _getFoodColorByRank(int rank) {
    switch (rank) {
      case 1: return const Color.fromARGB(212, 244, 155, 54);
      case 2: return const Color.fromARGB(255, 109, 109, 109);
      case 3: return const Color.fromARGB(255, 0, 0, 0);
      default: return const Color.fromARGB(255, 255, 211, 175);
    }
  }

  Future<void> _calculateTotals() async {
    try {
      final snapshot = await _firestore.collection('consommation').get();

      double waterSum = 0;
      double foodSum = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        waterSum += (data['eau'] as num? ?? 0).toDouble();
        foodSum += (data['nourriture'] as num? ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _totalWater = waterSum;
          _totalFood = foodSum;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de calcul: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Erreur de calcul des totaux: $e');
    }
  }

  String _getConsumptionAnalysis(double food, double water) {
    String foodAnalysis = '';
    String waterAnalysis = '';
    
    if (food < 5000000) foodAnalysis = 'FAIBLE consommation alimentaire';
    else if (food < 8000000) foodAnalysis = 'Consommation alimentaire NORMALE';
    else foodAnalysis = 'HAUTE consommation alimentaire - À surveiller';
    
    if (water < 3000000) waterAnalysis = 'FAIBLE consommation hydrique';
    else if (water < 6000000) waterAnalysis = 'Consommation hydrique NORMALE';
    else waterAnalysis = 'HAUTE consommation d\'eau - Vérifier l\'abreuvement';
    
    return '''
STATISTIQUES:
- Nourriture: ${food.toStringAsFixed(0)} g ($foodAnalysis)
- Eau: ${water.toStringAsFixed(0)} ml ($waterAnalysis)
- Ratio nourriture/eau: ${(food/water).toStringAsFixed(2)} (idéal: 1.5-2.0)
- Consommation moyenne/jour (nourriture): ${(food / 30).toStringAsFixed(0)} g
- Consommation moyenne/jour (eau): ${(water / 30).toStringAsFixed(0)} ml
''';
  }

  Future<void> _askGemini({bool autoAnalysis = false}) async {
    if (autoAnalysis && _selectedStatistic.isEmpty) return;

    setState(() {
      _isLoadingGemini = true;
      _geminiResponse = '';
      _hasError = false;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Clé API non configurée');
      }

      final usersSnapshot = await _firestore.collection('users').get();
      final animalsSnapshot = await _firestore.collection('animals').get();
      final alertsSnapshot = await _firestore.collection('alertes').count().get();

      String prompt;
      
      if (_selectedStatistic == 'Nourriture') {
        prompt = '''
En tant que spécialiste en nutrition animale, fournis une analyse professionnelle de la consommation alimentaire avec:
1. Évaluation de consommation faible/elvée ou Moyenne par jour 
2. Comparaison avec les standards avicoles
3. Recommandations précises
4. Conseils d'optimisation
en bref
DONNÉES ACTUELLES:
- Total consommé: ${_totalFood.toStringAsFixed(0)} g
- Moyenne journalière: ${(_totalFood / 30).toStringAsFixed(0)} g
- Dernière mise à jour: ${_lastUpdate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_lastUpdate!) : 'N/A'}
''';
      } else { // Eau
        prompt = '''
En tant qu'expert en hydratation animale, fournis une analyse professionnelle de la consommation d'eau avec:
1. Évaluation de consommation  faible/elvée ou Moyenne par jour 
2. Comparaison avec les besoins standards
3. Signes vitaux à surveiller
4. Conseils d'optimisation
en bref
DONNÉES ACTUELLES:
- Total consommé: ${_totalWater.toStringAsFixed(0)} ml
- Moyenne journalière: ${(_totalWater / 30).toStringAsFixed(0)} ml
- Ratio nourriture/eau: ${(_totalFood/_totalWater).toStringAsFixed(2)}
- Dernière mise à jour: ${_lastUpdate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_lastUpdate!) : 'N/A'}
''';
      }

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 1500,
          temperature: 0.3,
          topP: 0.8,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        ],
        systemInstruction: Content.text('''
              Tu es un assistant professionnel pour éleveurs avicoles. Fournis des analyses techniques structurées avec:
              1. Titre clair 
              2. Points clés sous forme de puces
              3. Recommandations actionnables
              4. Niveau d'urgence si pertinent
              Utilise un style concis et professionnel avec emojis pertinents.
              '''),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      
      setState(() {
        _geminiResponse = response.text ?? 'Aucune analyse disponible';
      });

    } catch (e) {
      setState(() {
        _geminiResponse = 'Erreur technique: Impossible de générer l\'analyse';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoadingGemini = false;
      });
    }
  }

  Widget _buildConsumptionCard({required String title, required Color color}) {
    final isFood = title == 'Nourriture';
    final totalValue = isFood ? _totalFood : _totalWater;
    final unit = isFood ? 'g' : 'ml';
    
    final maxValue = isFood ? 100000.0 : 100000.0;
    final progressValue = (totalValue / maxValue).clamp(0.0, 1.0);

    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.grey[100],
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _showGeminiPanel = true;
              _selectedStatistic = title;
              _geminiResponse = '';
            });
            _askGemini(autoAnalysis: true);
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 350;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 10),
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    SizedBox(
                      width: isSmallScreen ? 80 : 100,
                      height: isSmallScreen ? 80 : 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progressValue,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            strokeWidth: 10,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${totalValue.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                unit,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(
                      'Total consommé',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('consommation')
                        .orderBy('date', descending: true)
                        .limit(1)
                        .snapshots(),
                      builder: (context, snapshot) {
                        final lastUpdate = snapshot.hasData && snapshot.data!.docs.isNotEmpty
                            ? (snapshot.data!.docs.first.data() as Map<String, dynamic>)['date'] as Timestamp?
                            : null;
                        
                        return Text(
                          lastUpdate != null 
                              ? ' ${DateFormat('dd/MM HH:mm').format(lastUpdate.toDate())}'
                              : 'Chargement...',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(enabled: true),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 1: return Text('Lun', style: TextStyle(fontSize: 12));
                    case 2: return Text('Mar', style: TextStyle(fontSize: 12));
                    case 3: return Text('jeu', style: TextStyle(fontSize: 12));
                    case 4: return Text('Jeu', style: TextStyle(fontSize: 12));
                    default: return Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}',
                    style: TextStyle(fontSize: 12));
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color.fromARGB(255, 192, 192, 191)!),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(1, 2.5), 
                FlSpot(2, 3.0), 
                FlSpot(3, 2.8), 
                FlSpot(4, 3.5)
              ],
              isCurved: false,
              color: Colors.orange,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: [
                FlSpot(1, 1.5), 
                FlSpot(2, 2.0), 
                FlSpot(3, 2.5), 
                FlSpot(4, 3.0)
              ],
              isCurved: false,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonWithIcon({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.orange),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<DocumentSnapshot> _getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _firestore.collection('admin').doc(user.uid).get();
    }
    throw Exception('Administrateur non connecté');
  }

  Widget _buildDrawer(BuildContext context, String firstName, String lastName, String email, String profileImageUrl) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text('$firstName $lastName', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: profileImageUrl.isNotEmpty 
                  ? NetworkImage(profileImageUrl) 
                  : null,
              child: profileImageUrl.isEmpty 
                  ? Text('${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                  : null,
            ),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 190, 190, 190),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: const Color.fromARGB(255, 8, 8, 8)),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Text("🐔", style: TextStyle(fontSize: 24)),
            title: Text('Gérer les Animaux'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnimalListScreen()),
              );
            },
          ),
          
          ListTile(
            leading: Icon(Icons.article, color: const Color.fromARGB(255, 8, 8, 8)),
            title: Text('Articles Santé & Consultation IA'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatVetPage()),
              );                     
            },
          ),ListTile(
            leading: Icon(Icons.history, color: const Color.fromARGB(255, 8, 8, 8)), 
            title: Text('Historique'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>HistoriqueAdmin()),
              );                     
            },
          ),ListTile(
            leading: Icon(Icons.notifications, color: const Color.fromARGB(255, 8, 8, 8)),
            title: Text('Alertes'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Alerteadmin()),
              );                     
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: const Color.fromARGB(255, 8, 8, 8)),
            title: Text('Profil'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Profileadmin()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.people_alt, color: const Color.fromARGB(255, 8, 8, 8)),
            title: Text('Gérer les Utilisateurs'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GererUtilisateursScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Color.fromARGB(255, 8, 8, 8)),
            title: Text('Déconnexion'),
            onTap: () async {
              bool confirmLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirmer la déconnexion'),
                    content: Text('Es-tu sûr de vouloir te déconnecter ?'),
                    actions: [
                      TextButton(
                        child: Text('Annuler'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text('Déconnexion'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                await _auth.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          )
        ],
      ),
    );
  }
  
  int _currentIndex = 2; // 2 pour AdminAcPage

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.push(context, MaterialPageRoute(builder: (context) => Alerteadmin()));
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatVetPage()));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAcPage()));
              break;
            case 3:
              Navigator.push(context, MaterialPageRoute(builder: (context) => HistoriqueAdmin()));
              break;
            case 4:
              Navigator.push(context, MaterialPageRoute(builder: (context) => Profileadmin()));
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 50, height: 50),
          ],
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _calculateTotals();
              _loadInitialData();
            },
          ),
        ],
      ),
      drawer: FutureBuilder<DocumentSnapshot>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Drawer(child: Center(child: CircularProgressIndicator()));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Drawer(backgroundColor: Colors.white,child: Center(child: Text('Données utilisateur non trouvées')));
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';
          final email = userData['email'] ?? '';
          final profileImageUrl = userData['profileImageUrl'] ?? '';
          return _buildDrawer(context, firstName, lastName, email, profileImageUrl);
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Smart ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                Text('Feeder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
            SizedBox(height: 16),
            Text('Statistiques de Consommation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildConsumptionCard(title: 'Nourriture', color: Colors.orange),
                _buildConsumptionCard(title: 'Eau', color: Colors.blue),
              ],
            ),
            
            if (_showGeminiPanel) ...[
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.orange[700], size: 24),
                              SizedBox(width: 8),
                              Text(
                                'ANALYSE PROFESSIONNELLE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 20),
                            onPressed: () => setState(() {
                              _showGeminiPanel = false;
                            }),
                          ),
                        ],
                      ),
                      Divider(color: Colors.grey[300], height: 24),
                      if (_isLoadingGemini)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Génération de l\'analyse...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_geminiResponse.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[200]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.verified_user, color: Colors.orange, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'SMARTFEEDER AI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              SelectableText(
                                _geminiResponse,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (_hasError)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[100]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Service temporairement indisponible. Veuillez réessayer plus tard.',
                                  style: TextStyle(color: Colors.red[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 24),
            Text('Etat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      child: _buildLineChart(),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            Text("Type D'alimentation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            FutureBuilder<Map<String, int>>(
              future: _calculateFoodDistribution(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucune donnée disponible'),
                    ),
                  );
                }
                
                final foodDistribution = snapshot.data!;
                final total = foodDistribution.values.reduce((a, b) => a + b);
                final sortedEntries = foodDistribution.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.grey[100],
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 600;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isSmallScreen ? 10 :5,
                              child: Container(
                                height: isSmallScreen ? 180 : 220,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: PieChart(
                                    PieChartData(
                                      sections: sortedEntries.map((entry) {
                                        final rank = sortedEntries.indexOf(entry) + 1;
                                        final percentage = (entry.value / total) * 100;
                                        return PieChartSectionData(
                                          value: percentage,
                                          color: _getFoodColorByRank(rank),
                                          title: '${percentage.toStringAsFixed(0)}%',
                                          radius: 60,
                                          titleStyle: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }).toList(),
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            Expanded(
                              flex: isSmallScreen ? 5 : 2,
                              child: Padding(
                                padding: EdgeInsets.only(left: isSmallScreen ? 8 : 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: sortedEntries.map((entry) {
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: _getFoodColorByRank(sortedEntries.indexOf(entry) + 1),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entry.key,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${entry.value}g ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    int userCount = snapshot.data!.docs.length;
                    return _buildButtonWithIcon(
                      icon: Icons.people,
                      label: '$userCount',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GererUtilisateursScreen())),
                    );
                  },
                ),
                _buildButtonWithIcon(
                  icon: Icons.notifications,
                  label: '5',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Alerteadmin())),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}