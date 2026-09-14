plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tibok" // Your app's namespace
    compileSdk = flutter.compileSdkVersion

    // Explicitly set to a stable installed NDK version (e.g., 26.1.10909125)
    // or set ndkVersion = flutter.ndkVersion
    ndkVersion = flutter.ndkVersion 

    defaultConfig {
        applicationId = "com.example.tibok"
        minSdk = 24 // Android 7.0 Nougat requirement
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
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
