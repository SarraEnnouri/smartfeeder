import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUser = _auth.currentUser;
    _updateUserStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserStatus(false);
    super.dispose();
  }

  Future<void> _updateUserStatus(bool isActive) async {
    if (_currentUser != null) {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'isActive': isActive,
        'lastSeen': DateTime.now(),
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _updateUserStatus(false);
        break;
      case AppLifecycleState.resumed:
        _updateUserStatus(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Widget _buildResponsiveImage(String assetPath, double height) {
    return Image.asset(
      assetPath,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Widget _buildText(String text, Color color, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inknut',
      ),
    );
  }

  TextSpan _buildTextSpan(String text, Color color, double fontSize) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inknut',
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final padding = mediaQuery.padding;
    final screenHeight = size.height - padding.top - padding.bottom;

    final isSmallScreen = screenHeight < 600;
    final isMediumScreen = screenHeight >= 600 && screenHeight <= 800;
    final isLargeScreen = screenHeight > 800;

    return Scaffold(backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top decorative image (20% of screen height)
                      _buildResponsiveImage(
                        'assets/images/deco1.png',
                        screenHeight * 0.2,
                      ),

                      // Main content area
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.05,
                            vertical: isSmallScreen ? 10 : 20,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo with responsive sizing
                              Image.asset(
                                'assets/images/logo.png',
                                height: isSmallScreen
                                    ? screenHeight * 0.08
                                    : isMediumScreen
                                        ? screenHeight * 0.1
                                        : screenHeight * 0.12,
                                fit: BoxFit.contain,
                              ),

                              SizedBox(height: isSmallScreen ? 10 : 20),

                              // App title with colored parts
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildText(
                                      'Smart',
                                      Colors.orange,
                                      isSmallScreen ? 24 : 30,
                                    ),
                                    _buildText(
                                      ' Feeder',
                                      Colors.black,
                                      isSmallScreen ? 24 : 30,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 15 : 30),

                              // Description text
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    _buildTextSpan(
                                      "Optimisez l'alimentation et l'hydratation de votre poule avec Smart Feeder !\n\n",
                                      Colors.black,
                                      isSmallScreen ? 14 : 18,
                                    ),
                                    _buildTextSpan(
                                      "Automatisez, programmez et surveillez leur bien-être en toute simplicité.",
                                      Colors.orange,
                                      isSmallScreen ? 14 : 18,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 20 : 40),

                              // Start button
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 12 : 15,
                                    horizontal: isSmallScreen ? 30 : 40,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.black.withOpacity(0.3),
                                ),
                                child: _buildText(
                                  'Commencer',
                                  Colors.white,
                                  isSmallScreen ? 16 : 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom decorative image (20% of screen height)
                      _buildResponsiveImage(
                        'assets/images/deco2.png',
                        screenHeight * 0.2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}