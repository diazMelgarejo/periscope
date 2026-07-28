package org.latentsignal.sampleplugin

import com.intellij.notification.NotificationGroupManager
import com.intellij.notification.NotificationType
import com.intellij.openapi.diagnostic.thisLogger
import com.intellij.openapi.project.Project
import java.io.File
import java.net.ServerSocket
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

/**
 * PeriscopeProcessManager — ref-counted lifecycle manager for the agentsview server.
 *
 * Starts the agentsview binary on project open and stops it when the last project
 * closes. Multiple IDE projects share one server process.
 */
object PeriscopeProcessManager {

    private val logger = thisLogger()

    private const val DEFAULT_PORT = 8080
    private const val NOTIFICATION_GROUP = "AgentsView"

    private val refCount = AtomicInteger(0)
    private val processRef = AtomicReference<Process?>(null)

    @Volatile
    private var resolvedPort: Int = DEFAULT_PORT

    fun start(project: Project) {
        refCount.incrementAndGet()
        if (processRef.get() != null) {
            logger.info("agentsview: already running on port $resolvedPort")
            return
        }
        synchronized(this) {
            if (processRef.get() != null) return
            launchProcess(project)
        }
    }

    fun stop(project: Project) {
        val remaining = refCount.decrementAndGet()
        if (remaining <= 0) {
            refCount.set(0)
            stopProcess()
        }
    }

    fun serverUrl(): String = "http://localhost:$resolvedPort/"

    private fun launchProcess(project: Project) {
        val binary = resolveBinary()
        if (binary == null) {
            notify(
                project,
                "AgentsView binary not found. Install agentsview and ensure it is on your PATH.",
                NotificationType.WARNING,
            )
            return
        }

        resolvedPort = findFreePort(DEFAULT_PORT)
        val cmd = listOf(binary.absolutePath, "serve", "--port", resolvedPort.toString())
        logger.info("agentsview: launching ${cmd.joinToString(" ")}")

        try {
            val process = ProcessBuilder(cmd)
                .redirectErrorStream(true)
                .start()

            processRef.set(process)

            Thread {
                process.inputStream.bufferedReader().use { reader ->
                    reader.lines().forEach { line ->
                        logger.debug("agentsview: $line")
                    }
                }
                processRef.set(null)
                logger.info("agentsview: process exited (port $resolvedPort)")
            }.also {
                it.isDaemon = true
                it.name = "agentsview-stdout-drain"
                it.start()
            }

            logger.info("agentsview: started on port $resolvedPort (pid ${process.pid()})")
            notify(project, "AgentsView started on port $resolvedPort", NotificationType.INFORMATION)
        } catch (e: Exception) {
            logger.warn("agentsview: failed to start", e)
            processRef.set(null)
            notify(project, "Failed to start AgentsView: ${e.message}", NotificationType.ERROR)
        }
    }

    private fun stopProcess() {
        val process = processRef.getAndSet(null) ?: return
        logger.info("agentsview: stopping process")
        process.destroy()
        if (!process.waitFor(3, TimeUnit.SECONDS)) {
            process.destroyForcibly()
        }
        logger.info("agentsview: stopped")
    }

    /**
     * Locate the agentsview binary. Tries PATH first, then common install locations.
     * Legacy `periscope` binary names are accepted as a fallback.
     */
    private fun resolveBinary(): File? {
        val isWindows = System.getProperty("os.name").lowercase().contains("win")
        val binaryNames = if (isWindows) {
            listOf("agentsview.exe", "periscope.exe")
        } else {
            listOf("agentsview", "periscope")
        }

        for (name in binaryNames) {
            findOnPath(name)?.let { return it }
        }

        val homeDir = System.getProperty("user.home")
        val relativePaths = listOf(
            "bin",
            ".local/bin",
        )
        for (name in binaryNames) {
            for (relative in relativePaths) {
                val candidate = File(homeDir, "$relative/$name")
                if (candidate.exists() && candidate.canExecute()) {
                    return candidate
                }
            }
        }

        val systemPaths = listOf(
            "/usr/local/bin",
            "/opt/homebrew/bin",
        )
        for (name in binaryNames) {
            for (dir in systemPaths) {
                val candidate = File(dir, name)
                if (candidate.exists() && candidate.canExecute()) {
                    return candidate
                }
            }
        }

        return null
    }

    private fun findOnPath(name: String): File? {
        val path = System.getenv("PATH") ?: return null
        return path.split(File.pathSeparator)
            .map { File(it, name) }
            .firstOrNull { it.exists() && it.canExecute() }
    }

    private fun findFreePort(preferred: Int): Int {
        return try {
            ServerSocket(preferred).use { preferred }
        } catch (_: Exception) {
            ServerSocket(0).use { it.localPort }
        }
    }

    private fun notify(project: Project, message: String, type: NotificationType) {
        try {
            NotificationGroupManager.getInstance()
                .getNotificationGroup(NOTIFICATION_GROUP)
                .createNotification(message, type)
                .notify(project)
        } catch (e: Exception) {
            logger.info("agentsview notification ($type): $message")
        }
    }
}
