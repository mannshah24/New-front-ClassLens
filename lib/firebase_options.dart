// Firebase support is disabled for the desktop build so the Windows app can
// link and run without the native Firebase C++ SDK.
class DefaultFirebaseOptions {
  static const Object? currentPlatform = null;
}