import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Archivo temporal de opciones de Firebase para compilar sin configurar FlutterFire.
/// Reemplaza estos valores con los reales cuando completes la configuración.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android; // Fallback a Android
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtzr2yqz75iBPiOsLEamTxjigBYl0EIT8',
    appId: '1:312050044667:web:4b56e387e7ac0dd46dea5e',
    messagingSenderId: '312050044667',
    projectId: 'concursoepis',
    authDomain: 'concursoepis.firebaseapp.com',
    storageBucket: 'concursoepis.firebasestorage.app',
    measurementId: 'G-RVR62182XE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRmLn9G6RtMSyu_wwzvxpSORAWCjwkpcM',
    appId: '1:312050044667:android:59bc6df0513e60066dea5e',
    messagingSenderId: '312050044667',
    projectId: 'concursoepis',
    storageBucket: 'concursoepis.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:ios:dummyappid',
    messagingSenderId: '000000000000',
    projectId: 'concursoepis',
    iosBundleId: 'com.example.concursoepis',
    storageBucket: 'concursoepis.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:macos:dummyappid',
    messagingSenderId: '000000000000',
    projectId: 'concursoepis',
    iosBundleId: 'com.example.concursoepis',
    storageBucket: 'concursoepis.appspot.com',
  );
}