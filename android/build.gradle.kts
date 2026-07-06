allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Remove evaluationDependsOn to fix already-evaluated issue with subprojects config

fun parseSdkToInt(sdkVersion: Any?): Int {
    if (sdkVersion == null) return 0
    val sdkStr = sdkVersion.toString()
    return if (sdkStr.startsWith("android-")) {
        sdkStr.substringAfter("android-").toIntOrNull() ?: 0
    } else {
        sdkStr.toIntOrNull() ?: 0
    }
}

fun configureAndroid(
    android: com.android.build.gradle.BaseExtension,
    compileSdkLimit: Int,
    minSdkLimit: Int? = null
) {
    // compileSdk の比較と上書き
    val currentSdk = parseSdkToInt(android.compileSdkVersion)
    val targetSdkVal = maxOf(currentSdk, 36)
    android.compileSdkVersion = "android-$targetSdkVal"

    // targetSdk の適用
    val currentTargetSdk = android.defaultConfig.targetSdk ?: 0
    android.defaultConfig.targetSdk = maxOf(currentTargetSdk, targetSdkVal)

    // minSdk の適用 (指定がある場合のみ)
    if (minSdkLimit != null) {
        val currentMinSdk = android.defaultConfig.minSdkVersion?.apiLevel ?: 0
        android.defaultConfig.minSdkVersion(maxOf(currentMinSdk, minSdkLimit))
    }
}

subprojects {
    val project = this
    
    project.afterEvaluate {
        val android = project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        if (android != null) {
            if (android is com.android.build.gradle.AppExtension) {
                // アプリ本体への適用 (minSdkの引き上げを含む)
                configureAndroid(android, compileSdkLimit = 36, minSdkLimit = 21)
            } else if (android is com.android.build.gradle.LibraryExtension) {
                // プラグインライブラリへの適用
                configureAndroid(android, compileSdkLimit = 36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
