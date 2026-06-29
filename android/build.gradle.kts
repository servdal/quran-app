allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.configureEach {
        resolutionStrategy {
            force("androidx.glance:glance-appwidget:1.2.0-rc01")
            force("androidx.work:work-runtime-ktx:2.10.0")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
        }
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
