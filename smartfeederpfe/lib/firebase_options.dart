// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4Ixob4bqvb4wvE0WOJTHg2MppCM1gJQg',
    appId: '1:334148448396:web:e3da959a1c046770354ba9',
    messagingSenderId: '334148448396',
    projectId: 'smartfeederpfe',
    authDomain: 'smartfeederpfe.firebaseapp.com',
    storageBucket: 'smartfeederpfe.firebasestorage.app',
    measurementId: 'G-2777Y9TFPH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYBH1y3KPBjtuzUnc7pcj0_YbIQ2048SA',
    appId: '1:334148448396:android:c21fc9338456e466354ba9',
    messagingSenderId: '334148448396',
    projectId: 'smartfeederpfe',
    storageBucket: 'smartfeederpfe.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCNMzxKrv3O5QEOHQHuztiIu20qR_BLHIQ',
    appId: '1:334148448396:ios:e4e368b08643c81b354ba9',
    messagingSenderId: '334148448396',
    projectId: 'smartfeederpfe',
    storageBucket: 'smartfeederpfe.firebasestorage.app',
    iosBundleId: 'com.example.smartfeederpfe',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCNMzxKrv3O5QEOHQHuztiIu20qR_BLHIQ',
    appId: '1:334148448396:ios:e4e368b08643c81b354ba9',
    messagingSenderId: '334148448396',
    projectId: 'smartfeederpfe',
    storageBucket: 'smartfeederpfe.firebasestorage.app',
    iosBundleId: 'com.example.smartfeederpfe',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA4Ixob4bqvb4wvE0WOJTHg2MppCM1gJQg',
    appId: '1:334148448396:web:6c91c9fd95631212354ba9',
    messagingSenderId: '334148448396',
    projectId: 'smartfeederpfe',
    authDomain: 'smartfeederpfe.firebaseapp.com',
    storageBucket: 'smartfeederpfe.firebasestorage.app',
    measurementId: 'G-YJMNHLGEWT',
  );
}
