
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

// Silencia avisos de "source/target 8 is obsolete" en tareas Java
subprojects {
    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        // No cambiamos compatibilidades; solo suprimimos el warning
        options.compilerArgs.add("-Xlint:-options")
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

