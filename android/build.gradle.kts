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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// 🛠️ บล็อกแก้ปัญหาบังคับ SDK 36 แบบปลอดภัยสำหรับ Kotlin DSL
subprojects {
    val configureAndroid = {
        if (extensions.findByName("android") != null) {
            @Suppress("UNCHECKED_CAST")
            val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.compileSdkVersion(36)
        }
    }

    // ถ้าโปรเจกต์โดนเอาไปประมวลผลเสร็จแล้ว ให้รันเลย / ถ้ายังไม่เสร็จ ให้รอหลัง Evaluate
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate { configureAndroid() }
    }
}
