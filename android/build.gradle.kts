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

// Force every Flutter plugin (some still ship with compileSdk 31) to compile
// against SDK 36 — needed by androidx.navigationevent:1.0.2 and
// androidx.window.extensions:1.0.0. MUST come before evaluationDependsOn —
// otherwise the subproject is already evaluated when we try to hook in.
// We skip ":app" because the app module sets compileSdk = 36 itself and
// re-setting it here would clobber the explicit value with a stale read.
subprojects {
    if (project.name == "app") return@subprojects
    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            try {
                android.javaClass
                    .getMethod("setCompileSdkVersion", String::class.java)
                    .invoke(android, "android-36")
            } catch (_: Exception) { /* not an Android subproject */ }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
