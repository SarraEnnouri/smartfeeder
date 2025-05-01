import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartfeeder/admin/gereuser.dart';
import 'package:smartfeeder/firebase_options.dart';
// user file 
import 'user/ajustermode.dart';
import 'user/alertuser.dart';
import 'user/historiqueuser.dart';
import 'user/userac.dart';
import 'user/calendrier.dart';
import 'user/profiluser.dart';
// admin file
import 'admin/adminac.dart';
import 'admin/ajoutanimal.dart';
import 'admin/alertadmin.dart';
import 'admin/chat.dart';
import 'admin/gestionanimal.dart';
import 'admin/historiqueadmin.dart';
import 'admin/modifieranimal.dart';
import 'admin/profiladmin.dart';

// pour le deux 
import 'home.dart';
import 'signup.dart';
import 'login.dart';
import 'password.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialisation nécessaire avant d'appeler Firebase
  WidgetsFlutterBinding.ensureInitialized(); // Assure que les bindings sont initialisés avant Firebase
  await initializeDateFormatting('fr_FR') ; 
  

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await dotenv.load(fileName: ".env"); // Chargement du fichier .env
    
    runApp(MyApp()); // Lancement de l'application
  } catch (e, stacktrace) {
    print("Erreur lors de l'initialisation de Firebase: $e");
    print("Stacktrace: $stacktrace"); // Utile pour le debug si besoin
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final speciesName = 'poule'; // Déclarée ici, et non comme getter

    // Vérifier si la clé est disponible
    {     
    }

    return MaterialApp(
      title: 'Smart Feeder',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inknut',
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/login': (context) => Login(),
        '/signup': (context) => SignUpScreen(),
        '/password': (context) => Password(), 
        '/adminac': (context) => AdminAcPage(),
        '/userac': (context) => DashboardPage(),
        '/alertuser': (context) => Alertuser(),
        '/alertadmin': (context) => Alerteadmin(),
       '/chat': (context) => ChatVetPage(),
        '/profiluser': (context) => Profileuser(),
        '/profiladmin': (context) => Profileadmin(),
        '/gereuser': (context) => GererUtilisateursScreen(),
        '/ajout': (context) => AnimalAddScreen(),
        '/modifieranimal': (context) => AnimalEditScreen(speciesName: speciesName),
        '/ajustermode': (context) => AjusterModePage(),
        '/calendrier': (context) => CalendarPage(),
        '/historiqueuser': (context) => Historiqueuser(),
      },
    );
  }
}