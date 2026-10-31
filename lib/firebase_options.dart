
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
    apiKey: 'AIzaSyDsL_5rIUfHejvhTZJ8uAYMEtZhxVVR29s',
    appId: '1:206334992637:web:547ab1ddd03b5197b9de94',
    messagingSenderId: '206334992637',
    projectId: 'food-ordering-app-5c822',
    authDomain: 'food-ordering-app-5c822.firebaseapp.com',
    storageBucket: 'food-ordering-app-5c822.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBbXShj5qXqcPKMRsSKyqrE6RG-h7RDclo',
    appId: '1:206334992637:android:46ca27c4f8d84d02b9de94',
    messagingSenderId: '206334992637',
    projectId: 'food-ordering-app-5c822',
    storageBucket: 'food-ordering-app-5c822.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3ghevzKbWCSjZzXQAhgplOPwg9RQAnFo',
    appId: '1:206334992637:ios:0db034c0c0f5828fb9de94',
    messagingSenderId: '206334992637',
    projectId: 'food-ordering-app-5c822',
    storageBucket: 'food-ordering-app-5c822.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication2',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA3ghevzKbWCSjZzXQAhgplOPwg9RQAnFo',
    appId: '1:206334992637:ios:0db034c0c0f5828fb9de94',
    messagingSenderId: '206334992637',
    projectId: 'food-ordering-app-5c822',
    storageBucket: 'food-ordering-app-5c822.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDsL_5rIUfHejvhTZJ8uAYMEtZhxVVR29s',
    appId: '1:206334992637:web:41e326f5c83b99a6b9de94',
    messagingSenderId: '206334992637',
    projectId: 'food-ordering-app-5c822',
    authDomain: 'food-ordering-app-5c822.firebaseapp.com',
    storageBucket: 'food-ordering-app-5c822.firebasestorage.app',
  );
}
