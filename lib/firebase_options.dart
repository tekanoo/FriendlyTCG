import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

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
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwW7qUxnh7KGGMw1c-QPqXjYMwhYm2BPk',
    appId: '1:577013453059:web:860fe452da1095f6399936',
    messagingSenderId: '577013453059',
    projectId: 'friendlytcg-35fba',
    authDomain: 'friendly-tcg.com',
    storageBucket: 'friendlytcg-35fba.firebasestorage.app',
    measurementId: 'G-LBVM1XQZC9',
  );
}
