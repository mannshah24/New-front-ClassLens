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
    apiKey: 'AIzaSyCSO5SXSZCF2StCMdsxQnd7vZgXb_yd2YM',
    appId: '1:548993477348:web:c8c729e587fe0e12b51af1',
    messagingSenderId: '548993477348',
    projectId: 'claens-f7490',
    authDomain: 'claens-f7490.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCSO5SXSZCF2StCMdsxQnd7vZgXb_yd2YM',
    appId: '1:548993477348:android:946ceea916948bb2b51af1',
    messagingSenderId: '548993477348',
    projectId: 'claens-f7490',
    storageBucket: 'claens-f7490.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCSO5SXSZCF2StCMdsxQnd7vZgXb_yd2YM',
    appId: '1:548993477348:ios:7d56ef152162c8fdb51af1',
    messagingSenderId: '548993477348',
    projectId: 'claens-f7490',
    storageBucket: 'claens-f7490.appspot.com',
  );
}