plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.riff"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }


    signingConfigs {
        create("prodDebug") {
            storeFile = file("${System.getProperty("user.home")}/riff-prod-debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.riff"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Required by flutter_appauth — must match the redirect URI scheme
        // registered in spotify_auth_service.dart (com.riff.app://spotify-callback)
        manifestPlaceholders["appAuthRedirectScheme"] = "com.riff.app"
    }

    flavorDimensions += "default"
    productFlavors {
        create("development") {
            dimension = "default"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Riff Dev")
        }
        create("production") {
            dimension = "default"
            resValue("string", "app_name", "Riff")
            // Use a dedicated keystore for production debug builds so its SHA-1
            // can be registered in Firebase separately from the system debug key
            // (which is already claimed by another project).
            buildTypes.getByName("debug").signingConfig =
                signingConfigs.getByName("prodDebug")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
