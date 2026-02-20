## Flutter Local Notifications - GSON ProGuard rules
## Required for flutter_local_notifications v18 to prevent
## "Missing type parameter" errors in release builds

# Keep GSON TypeToken and its subclasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep generic signatures for GSON
-keepattributes Signature
-keepattributes *Annotation*

# Keep flutter_local_notifications models
-keep class com.dexterous.** { *; }
