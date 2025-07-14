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
    apiKey: 'AIzaSyCgZGh8jQBpfVvU02nrIpOezEmJTRfETLw',
    appId: '1:217482368976:web:5975f19910a42cc4d30bd5',
    messagingSenderId: '217482368976',
    projectId: 'mekaqr-2121',
    authDomain: 'mekaqr-2121.firebaseapp.com',
    storageBucket: 'mekaqr-2121.firebasestorage.app',
    measurementId: 'G-DYR9JEPKD6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9HBL6ycpQWyp6tDoZpN5X2yHzy9oB30c',
    appId: '1:217482368976:android:fe7c4f02e493b052d30bd5',
    messagingSenderId: '217482368976',
    projectId: 'mekaqr-2121',
    storageBucket: 'mekaqr-2121.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAz6cCTMdVOoQOLZfbL-o_FWwJgV_XQBuE',
    appId: '1:123456789:ios:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'masamenu-app',
    storageBucket: 'masamenu-app.appspot.com',
    iosBundleId: 'com.example.masamenu',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAz6cCTMdVOoQOLZfbL-o_FWwJgV_XQBuE',
    appId: '1:123456789:macos:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'masamenu-app',
    storageBucket: 'masamenu-app.appspot.com',
    iosBundleId: 'com.example.masamenu',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAz6cCTMdVOoQOLZfbL-o_FWwJgV_XQBuE',
    appId: '1:123456789:windows:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'masamenu-app',
    storageBucket: 'masamenu-app.appspot.com',
  );
}
