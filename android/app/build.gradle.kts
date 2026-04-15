import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
val isReleaseTask = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }

if (hasReleaseSigning) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun requireReleaseSigning(key: String): String {
    val value = keystoreProperties.getProperty(key)?.trim().orEmpty()
    if (value.isEmpty()) {
        throw GradleException("Release signing is required. Missing `$key` in ${keystorePropertiesFile.path}")
    }
    return value
}

android {
    namespace = "com.brosister.pillreminder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            if (isReleaseTask && !hasReleaseSigning) {
                throw GradleException(
                    "Release signing is required. Create `${keystorePropertiesFile.path}` (and a keystore file) before building release."
                )
            }

            if (hasReleaseSigning) {
                val storeFilePath = requireReleaseSigning("storeFile")
                val resolvedStoreFile = rootProject.file(storeFilePath)
                if (isReleaseTask && !resolvedStoreFile.exists()) {
                    throw GradleException("Release signing keystore file not found: ${resolvedStoreFile.path}")
                }
                storeFile = resolvedStoreFile
                storePassword = requireReleaseSigning("storePassword")
                keyAlias = requireReleaseSigning("keyAlias")
                keyPassword = requireReleaseSigning("keyPassword")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.brosister.pillreminder"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
