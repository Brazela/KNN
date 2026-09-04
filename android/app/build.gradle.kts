import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.knn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.knn"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val dartDefines = (project.findProperty("dart-defines") as? String)
            ?.split(",")
            ?.mapNotNull { encoded ->
                runCatching { String(Base64.getDecoder().decode(encoded)) }.getOrNull()
            }
            ?.mapNotNull { entry ->
                val idx = entry.indexOf('=')
                if (idx > 0) entry.substring(0, idx) to entry.substring(idx + 1) else null
            }
            ?.toMap()
            ?: emptyMap()
        // Fall back to the bundled default key so the native map widget works
        // even when --dart-define is not passed (Android Studio runs, plain
        // `flutter build apk`, etc.).
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            dartDefines["GOOGLE_MAPS_API_KEY"]
                ?: "AIzaSyCwHiN8ZHF35vGGxYfvid1mR_bD_6Ay1zk"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
