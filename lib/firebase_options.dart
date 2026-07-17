import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Firebase support is disabled for the desktop build so the Windows app can
// link and run without the native Firebase C++ SDK.
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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCAOk5xfJEL7-CzkEmSO4vHGnm1gZN7124',
    appId: '1:475989075398:web:c8c729e587fe0e12b51af1',
    messagingSenderId: '475989075398',
    projectId: 'claens-5a3e5',
    authDomain: 'claens-5a3e5.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAOk5xfJEL7-CzkEmSO4vHGnm1gZN7124',
    appId: '1:475989075398:android:6bee282c535238afffbec7',
    messagingSenderId: '475989075398',
    projectId: 'claens-5a3e5',
    storageBucket: 'claens-5a3e5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCAOk5xfJEL7-CzkEmSO4vHGnm1gZN7124',
    appId: '1:475989075398:ios:7d56ef152162c8fdb51af1',
    messagingSenderId: '475989075398',
    projectId: 'claens-5a3e5',
    storageBucket: 'claens-5a3e5.firebasestorage.app',
  );
}