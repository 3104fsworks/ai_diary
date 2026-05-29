pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // record_android 2.0.0 ships a buildscript block that declares AGP 9.2.1.
    // If our version differs, Gradle loads two separate AGP classloaders and
    // sourceSets API casts fail at config time. Pin to 9.2.1 to match.
    id("com.android.application") version "9.2.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // Firebase: declares the version once here, applied in app/build.gradle.kts.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
