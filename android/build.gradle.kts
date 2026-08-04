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

// --- Fix: namespace, compileSdk, and JVM target compatibility for old plugins ---
subprojects {
    if (project.state.executed) {
        configureAndroidCompat(project, alreadyEvaluated = true)
    } else {
        project.afterEvaluate {
            configureAndroidCompat(project, alreadyEvaluated = false)
        }
    }
}

fun configureAndroidCompat(project: Project, alreadyEvaluated: Boolean) {
    if (!alreadyEvaluated) {
        // Namespace + compileSdk for library modules
        project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { lib ->
            if (lib.namespace == null) {
                lib.namespace = "com.example.${project.name.replace("-", "_")}"
            }
            if ((lib.compileSdk ?: 0) < 34) {
                lib.compileSdk = 34
            }
        }
        // Namespace for application modules (compileSdk normally already set correctly)
        project.extensions.findByType(com.android.build.gradle.AppExtension::class.java)?.let { app ->
            if (app.namespace == null) {
                app.namespace = "com.example.${project.name.replace("-", "_")}"
            }
        }

        // Java compile options
        project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.let { android ->
            try {
                android.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            } catch (e: Exception) {
                // Already finalized, safe to ignore.
            }
        }

        project.tasks.withType<JavaCompile>().configureEach {
            try {
                sourceCompatibility = JavaVersion.VERSION_17.toString()
                targetCompatibility = JavaVersion.VERSION_17.toString()
            } catch (e: Exception) {
                // Already finalized, safe to ignore.
            }
        }
    }

    // Kotlin compile target — safe to set regardless of evaluation state.
    project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}