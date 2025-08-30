import java.util.Properties

// Muat properti dari file key.properties jika ada
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    // Menggunakan .reader() yang merupakan cara yang benar di Kotlin DSL
    keyProperties.load(keyPropertiesFile.reader())
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quran_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.quran_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // #### BLOK YANG DIPERBARUI ADA DI SINI ####
    signingConfigs {
        create("release") {
            if (keyProperties.containsKey("storeFile")) {
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Mengarahkan build rilis untuk menggunakan kunci tanda tangan Anda
            signingConfig = signingConfigs.getByName("release")
        }
    }
    // #### AKHIR DARI BLOK YANG DIPERBARUI ####
}
flutter {
    source = "../.."
}
