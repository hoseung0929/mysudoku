allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val buildDirPath = System.getenv("MYSUDOKU_BUILD_DIR") ?: "../../build"
val newBuildDir: Directory = rootProject.layout.dir(rootProject.provider { rootProject.file(buildDirPath) })
    .get()
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
