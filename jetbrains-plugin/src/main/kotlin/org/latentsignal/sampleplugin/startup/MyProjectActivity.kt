package org.latentsignal.sampleplugin.startup

import com.intellij.openapi.diagnostic.thisLogger
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.ProjectManager
import com.intellij.openapi.project.ProjectManagerListener
import com.intellij.openapi.startup.ProjectActivity
import org.latentsignal.sampleplugin.PeriscopeProcessManager

/**
 * Starts the Periscope server when a project opens and stops it on project close.
 */
class MyProjectActivity : ProjectActivity {

    override suspend fun execute(project: Project) {
        thisLogger().info("Periscope: project opened — starting server")
        PeriscopeProcessManager.start(project)

        project.messageBus.connect().subscribe(
            ProjectManager.TOPIC,
            object : ProjectManagerListener {
                override fun projectClosing(closingProject: Project) {
                    if (closingProject === project) {
                        thisLogger().info("Periscope: project closing — stopping server")
                        PeriscopeProcessManager.stop(project)
                    }
                }
            },
        )
    }
}
