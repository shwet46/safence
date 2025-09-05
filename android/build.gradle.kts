allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Provide legacy extra properties expected by some older Flutter/Android plugin
// build.gradle (Groovy) scripts (e.g. path_provider_android) that still read
// values from `rootProject.ext.compileSdkVersion` etc. The modern Kotlin DSL
// template doesn't define these, which leads to: "compileSdkVersion is not specified".
// Keeping them here is harmless for up-to-date plugins and unblocks older ones.
extra.apply {
    // Bump these cautiously; keep in sync with values used in app module.
    set("compileSdkVersion", 34)
    set("targetSdkVersion", 34)
    set("minSdkVersion", 21)
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
