plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

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

    // ─────────────────────────────────────────────────────────────────────
    // Release signing — keystore credentials come from the environment so
    // they never land in version control. CI sets these via secrets;
    // locally, drop them in `~/.gradle/gradle.properties` or export them
    // before running `flutter build apk --release`.
    //
    // Required env vars:
    //   KEYSTORE_PATH   absolute or app-relative path to the .keystore/.jks
    //   KEY_ALIAS       key alias inside the store
    //   KEY_PASSWORD    password for the key
    //   STORE_PASSWORD  password for the keystore
    //
    // If any are missing we deliberately fall back to debug signing so
    // `flutter run --release` still works on a developer machine — but a
    // build that ends up on the Play Store MUST have all four set, or the
    // upload will be rejected (debug-signed APKs are not accepted).
    // ─────────────────────────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            val storePath = System.getenv("KEYSTORE_PATH")
            if (storePath != null) {
                storeFile = file(storePath)
                storePassword = System.getenv("STORE_PASSWORD") ?: ""
                keyAlias = System.getenv("KEY_ALIAS") ?: "airwatch"
                keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            }
        }
    }

    buildTypes {
        release {
            // Use the real release config when KEYSTORE_PATH is set, otherwise
            // fall back to debug so local `flutter run --release` keeps working.
            signingConfig = if (System.getenv("KEYSTORE_PATH") != null) {
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
