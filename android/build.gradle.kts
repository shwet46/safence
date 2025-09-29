allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

extra.apply {
    set("compileSdkVersion", 35)
    set("targetSdkVersion", 35)
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

subprojects {
    if (project.name == "phone_state") {
        project.plugins.withId("com.android.library") {
            val android = project.extensions.getByType<com.android.build.gradle.LibraryExtension>()
            android.namespace = "it.mainella.phone_state" 
        }
    }
}