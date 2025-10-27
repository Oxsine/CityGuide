allprojects {
    repositories {
        google()
        mavenCentral()
        // Добавьте зеркала с правильным синтаксисом Kotlin DSL
        maven {
            url = uri("https://maven.aliyun.com/repository/google")
            isAllowInsecureProtocol = true
        }
        maven {
            url = uri("https://maven.aliyun.com/repository/public")
            isAllowInsecureProtocol = true
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newBuildDir.dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}