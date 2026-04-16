import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions looma diyaarin platform-kan.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCSSnGIaaCjf63nJoehTBLXADWZPmjNlrs',
    appId: '1:573642272367:web:40a3c61dd2133fd927679a',
    messagingSenderId: '573642272367',
    projectId: 'caruurkaabai',
    authDomain: 'caruurkaabai.firebaseapp.com',
    storageBucket: 'caruurkaabai.firebasestorage.app',
    measurementId: 'G-MRTC9F0NKG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA0auQPFAZiUdL3Gllar3JTf5kDrWJ-7OE',
    appId: '1:573642272367:android:bb9c004676dfa57a27679a',
    messagingSenderId: '573642272367',
    projectId: 'caruurkaabai',
    storageBucket: 'caruurkaabai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2B3qlF0H_q0gGinaaPHsonUVySwO7qD0',
    appId: '1:573642272367:ios:7a9afbcec969a32827679a',
    messagingSenderId: '573642272367',
    projectId: 'caruurkaabai',
    storageBucket: 'caruurkaabai.firebasestorage.app',
    iosBundleId: 'com.example.caruurkaabAi',
  );
}
