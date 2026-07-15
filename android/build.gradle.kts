import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val trustStorePath = localProperties.getProperty("javax.net.ssl.trustStore")
if (trustStorePath != null) {
    System.setProperty("javax.net.ssl.trustStore", trustStorePath)
}
val trustStorePassword = localProperties.getProperty("javax.net.ssl.trustStorePassword")
if (trustStorePassword != null) {
    System.setProperty("javax.net.ssl.trustStorePassword", trustStorePassword)
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
