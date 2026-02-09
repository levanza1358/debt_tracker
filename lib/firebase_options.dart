import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'FirebaseOptions belum dikonfigurasi untuk platform ini. '
          'Saat ini konfigurasi tersedia untuk Web.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCxLkswCY4S4Q0blzszTtNQDGsk1u9TTJA',
    appId: '1:820595368163:web:18984efb0d0a3e382565d6',
    messagingSenderId: '820595368163',
    projectId: 'debt-tracker-4686c',
    authDomain: 'debt-tracker-4686c.firebaseapp.com',
    storageBucket: 'debt-tracker-4686c.firebasestorage.app',
  );
}
