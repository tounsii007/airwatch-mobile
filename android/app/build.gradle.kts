import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────────────────────
// Two ways to feed the upload-key credentials in:
//
//   1. `android/key.properties` — the conventional Flutter workflow. Local
//      devs copy `key.properties.example` and fill it in; the file is
//      gitignored. Format:
//
//          storeFile=upload-keystore.jks   (relative to android/app/)
//          storePassword=…
//          keyAlias=airwatch
//          keyPassword=…
//
//   2. Environment variables — what CI uses, since secrets aren't files:
//
//          KEYSTORE_PATH=/abs/path/to/upload.jks
//          STORE_PASSWORD=…
//          KEY_ALIAS=airwatch
//          KEY_PASSWORD=…
//
// `key.properties` wins if both are provided. If NEITHER is configured, the
// release build falls back to debug signing so `flutter run --release` keeps
// working on a clean machine — but a build heading for the Play Store MUST
// have one of them, or the upload will be rejected (debug-signed AABs are
// not accepted).
// ─────────────────────────────────────────────────────────────────────────────

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun resolveStoreFile(): java.io.File? {
    val fromProps = keystoreProperties["storeFile"] as String?
    if (fromProps != null) {
        // Resolve relative to android/app/ (Flutter docs convention) so devs
        // can drop the .jks next to this build script.
        return file(fromProps)
    }
    val fromEnv = System.getenv("KEYSTORE_PATH")
    return if (fromEnv != null) file(fromEnv) else null
}

fun resolveProp(propsKey: String, envKey: String, fallback: String = ""): String =
    (keystoreProperties[propsKey] as String?) ?: (System.getenv(envKey) ?: fallback)

android {
    namespace = "com.airwatch.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.airwatch.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFileResolved = resolveStoreFile()
            if (storeFileResolved != null) {
                storeFile = storeFileResolved
                storePassword = resolveProp("storePassword", "STORE_PASSWORD")
                keyAlias = resolveProp("keyAlias", "KEY_ALIAS", "airwatch")
                keyPassword = resolveProp("keyPassword", "KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Use the real release config when a keystore is configured (via
            // key.properties OR env vars), otherwise fall back to debug so
            // local `flutter run --release` keeps working without the upload
            // key being checked out.
            signingConfig = if (resolveStoreFile() != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
