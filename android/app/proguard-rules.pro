# ─── ProGuard / R8 rules for AirWatch Mobile ───
#
# Release builds run with isMinifyEnabled + isShrinkResources. Without these
# keep rules R8 strips reflection-loaded plugin glue and the app crashes on
# first launch with a NoClassDefFoundError.
#
# Add new keeps here when you add a plugin that uses reflection or native
# bindings. The Flutter plugin generally injects its own consumer rules,
# but a few common ones still need to be listed explicitly.

# Flutter wrapper — entry points and embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Kotlin metadata (Riverpod / freezed generated code reads it)
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Camera / sensors_plus / geolocator use reflection on plugin manifests
-keep class androidx.camera.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver

# flutter_local_notifications keeps its receivers via reflection
-keep class com.dexterous.** { *; }

# OkHttp (transitive via dio)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Strip verbose logging in release
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
}
