plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// repo.maven.apache.org 在本机网络下连接超时，改用阿里云镜像代理 Maven Central。
repositories {
    google()
    maven { url = uri("https://maven.aliyun.com/repository/public") }
    maven { url = uri("https://maven.aliyun.com/repository/google") }
    mavenCentral()
}

android {
    namespace = "com.ledger.jizhang"
    // file_picker 13.x 要求 compileSdk >= 36。
    // 注：本机 platforms/android-36 曾安装不完整（缺 android.jar），已用
    // sdkmanager --uninstall / --install 重新拉取修复。
    compileSdk = 36
    buildToolsVersion = "36.0.0"
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ledger.jizhang"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // AGP 9.x 在本机（Gradle 9.3.1 + Flutter 3.47）下 minifyReleaseWithR8 会
            // 因输入 provider 缺值而失败；本项目无自定义 ProGuard 规则，直接关闭压缩。
            // Dart 代码本身由 AOT 编译，关闭 minify 不影响运行与体积表现。
            isMinifyEnabled = false
            isShrinkResources = false
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
