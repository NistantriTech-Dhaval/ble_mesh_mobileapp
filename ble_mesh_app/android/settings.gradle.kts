pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val path = properties.getProperty("flutter.sdk")
        require(path != null) { "flutter.sdk not set in local.properties" }
        path
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
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// -------------------- Include Nordic Mesh Library --------------------
// Use Groovy JsonSlurper from Gradle runtime
val flutterProjectRoot = rootDir.parentFile
val pluginsFile = File(flutterProjectRoot, ".flutter-plugins-dependencies")

if (pluginsFile.exists()) {
    val jsonSlurper = org.codehaus.groovy.runtime.InvokerHelper.invokeMethod(
        org.codehaus.groovy.runtime.DefaultGroovyMethods::class.java,
        "newInstance",
        arrayOf(Class.forName("groovy.json.JsonSlurper"))
    ) as groovy.json.JsonSlurper

    val json = jsonSlurper.parseText(pluginsFile.readText()) as Map<*, *>
    val androidPlugins = ((json["plugins"] as Map<*, *>)["android"] as List<Map<String, String>>)

    androidPlugins.forEach { plugin ->
        if (plugin["name"] == "nordic_nrf_mesh") {
            println("Including Nordic ADK v3")
            val pluginPath = plugin["path"]!!.replace("android", "")
            val meshLibPath = "$pluginPath/Android-nRF-Mesh-Library-1/mesh"
            include(":mesh")
            project(":mesh").projectDir = File(meshLibPath)
        }
    }
}
