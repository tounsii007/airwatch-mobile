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
        // flutter_local_notifications requires core library desugaring
        // on Android API < 26 (uses java.time on the JVM-21 side). Without
        // this, `flutter build apk --release` aborts at the AAR metadata
        // check with:
        //   "Dependency ':flutter_local_notifications' requires core
        //    library desugaring to be enabled for :app."
        isCoreLibraryDesugaringEnabled = true
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
        // Lift the dex method limit; both flutter_local_notifications
        // and the Google Play Services pulled in by maps push the
        // shared-code count over 64 K.
        multiDexEnabled = true
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
            // key.properties OR env vars). When neither is configured the
            // build falls back to debug-signing so `flutter run --release`
            // keeps working on a clean dev machine.
            //
            // CI guard — the release pipeline (.github/workflows/release.yml)
            // sets RELEASE_BUILD=true. With that env var present we REFUSE
            // to fall back to debug-signing: shipping a debug-signed AAB
            // breaks the upgrade path forever (Play won't accept a
            // signature change), and an accidentally side-loaded debug-
            // signed APK is worse than a build failure.
            signingConfig = if (resolveStoreFile() != null) {
                signingConfigs.getByName("release")
            } else {
                if (System.getenv("RELEASE_BUILD") == "true") {
                    throw GradleException(
                        "RELEASE_BUILD=true but no upload keystore is " +
                        "configured. Set KEYSTORE_PATH + STORE_PASSWORD + " +
                        "KEY_ALIAS + KEY_PASSWORD env vars (CI), or place " +
                        "android/key.properties + android/app/upload-keystore.jks " +
                        "(local). Refusing to debug-sign a release build."
                    )
                }
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

// Pulls in the desugar_jdk_libs core library — required by the
// isCoreLibraryDesugaringEnabled flag above.
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // ─────────────────────────────────────────────────────────────────────
    // Force-pin androidx.glance:glance-appwidget to a stable 1.1.x.
    //
    // The home_widget 0.9.x Flutter plugin declares its Android dep as
    //   implementation "androidx.glance:glance-appwidget:1.+"
    // which Gradle resolves to the LATEST matching version — including
    // alphas. Right now that's 1.3.0-alpha01, which transitively requires
    //   * Android Gradle Plugin ≥ 9.1.0
    //   * compileSdk ≥ 37
    // We're on AGP 8.11.1 + compileSdk 36 (via flutter.compileSdkVersion),
    // so the AAR metadata check at the start of `assembleRelease` aborts
    // the build. The same alpha also pulls in
    // androidx.compose.remote:remote-creation-android:1.0.0-alpha11 which
    // has the same constraints.
    //
    // Pinning here keeps the toolchain bump as a separate, focused PR
    // (it requires Gradle wrapper + Java + Kotlin coordination). The
    // 1.1.1 release supports AGP 8.x and compileSdk 34+, which is
    // comfortable for our target.
    constraints {
        implementation("androidx.glance:glance-appwidget") {
            version {
                // `strictly` overrides home_widget's dynamic 1.+; a plain
                // constraint isn't enough — Gradle still resolves the
                // dynamic version to the highest available (1.3.0-alpha01
                // today) and merely emits a warning when the constraint
                // disagrees.
                strictly("1.1.1")
            }
            because(
                "home_widget 0.9.x uses dynamic 1.+; 1.2/1.3 alphas need " +
                "AGP 9.1 + compileSdk 37 which we haven't adopted yet."
            )
        }
    }
    // Belt-and-suspenders against future transitive bumps to dynamic
    // alpha versions of the same artifact.
    configurations.all {
        resolutionStrategy {
            force("androidx.glance:glance-appwidget:1.1.1")
        }
    }
}
