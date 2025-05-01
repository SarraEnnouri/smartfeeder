import 'package:flutter/material.dart';
import 'ajustermode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _poidsStream;
  late Stream<QuerySnapshot> _eauStream;
  double poids = 0;
  double valeur = 0;
  int _selectedTopTabIndex = 0;
  int _selectedBottomIndex = 2;
  String _selectedSpecies = '';
  List<String> _speciesList = [];
  bool _isLoadingSpecies = true;
  File? _profileImageFile;

  // User data
  String firstName = 'Chargement...';
  String lastName = '';
  String email = 'chargement...';
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchSpecies();
    _setupRealtimeListeners();
    _loadUserData();
    initializeDateFormatting('fr_FR', null);
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          firstName = userDoc.data()?['firstName'] ?? 'Prénom';
          lastName = userDoc.data()?['lastName'] ?? 'Nom';
          email = user.email ?? 'email@example.com';
          profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';
        });
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
      // Ici vous devriez aussi uploader l'image vers Firebase Storage
      // et mettre à jour l'URL dans Firestore
    }
  }

  Future<void> _fetchSpecies() async {
    try {
      final querySnapshot = await _firestore.collection('animals').get();
      final species = querySnapshot.docs
          .map((doc) => doc['species'].toString())
          .toSet()
          .toList();
      setState(() {
        _speciesList = species;
        _isLoadingSpecies = false;
        if (_speciesList.isNotEmpty) {
          _selectedSpecies = _speciesList.first;
        }
      });
    } catch (e) {
      print('Erreur lors du chargement des espèces: $e');
      setState(() {
        _isLoadingSpecies = false;
      });
    }
  }

  void _setupRealtimeListeners() {
    _poidsStream = _firestore
        .collection('hx711')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
    _eauStream = _firestore
        .collection('eau')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  Widget _buildRealtimeListener(String label, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<QuerySnapshot>(
      stream: label == "Nourriture" ? _poidsStream : _eauStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final double currentValue = label == "Nourriture"
              ? (data['poids'] as num).toDouble()
              : (data['valeur'] as num).toDouble();

          if (label == "Nourriture") {
            poids = currentValue;
          } else {
            valeur = currentValue;
          }

          return Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
            ),],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: currentValue / (label == "Nourriture" ? 1000 : 100),
                        backgroundColor: Colors.grey[300],
                        color: label == "Nourriture" ? Colors.orange : Colors.blue,
                        minHeight: screenWidth * 0.03,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      label == "Nourriture" ? "g" : "ML",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "${currentValue.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text("Erreur: ${snapshot.error}");
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<Map<String, dynamic>> _fetchConsumptionData(String date) async {
    try {
      final docSnapshot = await _firestore.collection('consommation').doc(date).get();
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Erreur lors du chargement des données de consommation: $e');
    }
    return {};
  }

  List<FlSpot> _generateChartData(Map<String, dynamic> consumptionData) {
    List<FlSpot> spots = [];
    if (consumptionData.isNotEmpty) {
      if (consumptionData.containsKey('nourriture')) {
        final nourriture = consumptionData['nourriture'];
        spots.add(FlSpot(0, nourriture.toDouble()));
      }
      if (consumptionData.containsKey('eau')) {
        final eau = consumptionData['eau'];
        spots.add(FlSpot(1, eau.toDouble()));
      }
    }
    return spots;
  }

  Widget _getChartForTab(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchConsumptionData(DateFormat('yyyy-MM-dd').format(DateTime.now())),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Erreur: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("Aucune donnée disponible pour aujourd'hui"));
        }
        final consumptionData = snapshot.data!;
        final spots = _generateChartData(consumptionData);
        if (spots.isEmpty) {
          return Center(child: Text("Aucune donnée de consommation valide"));
        }

        return Container(
          height: screenWidth < 400 ? screenWidth * 0.8 : screenWidth * 0.6,
          padding: EdgeInsets.all(screenWidth * 0.05),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      switch (value.toInt()) {
                        case 0:
                          return Text('Nour.', style: TextStyle(fontSize: 16));
                        case 1:
                          return Text('Eau', style: TextStyle(fontSize: 16));
                        default:
                          return Text('');
                      }
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 50,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.orange,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedTopTabIndex = index;
    });
  }

  void _onBottomTabTapped(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/alertuser');
        break;
      case 1:
        Navigator.pushNamed(context, '/profiluser');
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamed(context, '/ajustermode');
        break;
      case 4:
        Navigator.pushNamed(context, '/historiqueuser');
        break;
      case 5:
        Navigator.pushNamed(context, '/calendrier');
        break;
    }
  }

  Widget _buildTab(String label, int index, BuildContext context) {
    final isSelected = _selectedTopTabIndex == index;
    final screenWidth = MediaQuery.of(context).size.width;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.orange : Colors.transparent,
                width: 3.0,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? Colors.orange : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: screenHeight * 0.3,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 218, 215, 215),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.12,
                        backgroundImage: _profileImageFile != null
                            ? FileImage(_profileImageFile!)
                            : (profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : AssetImage('assets/images/up.png') as ImageProvider),
                        backgroundColor: Colors.grey,
                      ),
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: screenWidth * 0.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerTile(
            icon: Icons.notification_add_outlined,
            title: 'Alerte',
            context: context,
            routeName: '/alertuser',
          ),
          _buildDrawerTile(
            icon: Icons.settings,
            title: 'Paramètre',
            context: context,
            routeName: '/profiluser',
          ),
          _buildDrawerTile(
            icon: Icons.home,
            title: 'Accueil',
            context: context,
            routeName: null,
          ),
          _buildDrawerTile(
            icon: Icons.food_bank,
            title: 'Ajuster Mode',
            context: context,
            routeName: '/ajustermode',
          ),
          _buildDrawerTile(
            icon: Icons.history,
            title: 'Historique',
            context: context,
            routeName: '/historiqueuser',
          ),
          _buildDrawerTile(
            icon: Icons.calendar_today,
            title: 'Calendrier',
            context: context,
            routeName: '/calendrier',
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red, size: screenWidth * 0.07),
            title: Text("Déconnexion",
                style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.red)),
            onTap: () async {
              await _auth.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required BuildContext context,
    String? routeName,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListTile(
      leading: Icon(icon, color: Colors.black, size: screenWidth * 0.07),
      title: Text(title,
          style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black)),
      onTap: () {
        Navigator.pop(context);
        if (routeName != null) {
          Navigator.pushNamed(context, routeName);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.1),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.black, size: 24),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          title: Column(
            children: [
              Image.asset('assets/images/logo.png',
                  height: screenHeight * 0.05),
              Text.rich(
                TextSpan(
                  text: 'Dash',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  children: [
                    TextSpan(
                      text: 'board',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Sélecteur de type d'animal - partie fixe
          Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.05,
              top: screenHeight * 0.02,
              right: screenWidth * 0.05,
              bottom: screenHeight * 0.01,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: screenWidth * 0.4,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSpecies.isNotEmpty ? _selectedSpecies : null,
                  underline: SizedBox(),
                  iconSize: screenWidth * 0.05,
                  style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.black),
                  items: _speciesList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecies = value!;
                    });
                  },
                ),
              ),
            ),
          ),
          
          // Partie défilable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                    ),],
                    ),
                    child: Row(
                      children: [
                        _buildTab("Nourriture", 0, context),
                        _buildTab("Eau", 1, context),
                        _buildTab("Système", 2, context),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    "Mois",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("10L", style: TextStyle(fontSize: 16)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.01,
                            vertical: screenHeight * 0.006),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        child: Text(
                          DateFormat.MMMM('fr_FR').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  _getChartForTab(context),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    "Niveau en temps réel",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildRealtimeListener("Nourriture", Icons.scale),
                  SizedBox(height: screenHeight * 0.02),
                  _buildRealtimeListener("Eau", Icons.water_drop),
                  SizedBox(height: screenHeight * 0.03),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AjusterModePage()),
                        );
                      },
                      child: Text("Ajuster Mode", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onTap: _onBottomTabTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: const Color.fromARGB(255, 4, 4, 4),
        backgroundColor: Color(0xFFF2F2F2),
        type: BottomNavigationBarType.fixed,
        iconSize: 24,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.notification_add_outlined),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "",
          ),
        ],
      ),
    );
  }
}