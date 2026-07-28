package org.latentsignal.sampleplugin

import com.intellij.notification.NotificationGroupManager
import com.intellij.notification.NotificationType
import com.intellij.openapi.diagnostic.thisLogger
import com.intellij.openapi.project.Project
import java.io.File
import java.net.HttpURLConnection
import java.net.ServerSocket
import java.net.URI
import java.net.URL
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

/**
 * PeriscopeProcessManager — ref-counted lifecycle manager for the Periscope server.
 *
 * Starts the periscope binary (falling back to legacy agentsview) on project open and
 * stops it when the last project closes. Multiple IDE projects share one server process.
 */
object PeriscopeProcessManager {

    private val logger = thisLogger()

    private const val DEFAULT_PORT = 8080

    /** Legacy notification group id — retained for installed-plugin update continuity. */
    private const val NOTIFICATION_GROUP = "AgentsView"
    private const val READINESS_TIMEOUT_MS = 10_000L
    private const val READINESS_POLL_MS = 100L
    private const val READINESS_CONNECT_TIMEOUT_MS = 500

    private val refCount = AtomicInteger(0)
    private val processRef = AtomicReference<Process?>(null)

    @Volatile
    private var resolvedPort: Int = DEFAULT_PORT

    fun start(project: Project) {
        refCount.incrementAndGet()
        if (processRef.get() != null) {
            logger.info("periscope: already running on port $resolvedPort")
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

    internal fun binaryNames(): List<String> {
        val isWindows = System.getProperty("os.name").lowercase().contains("win")
        return if (isWindows) {
            listOf("periscope.exe", "agentsview.exe")
        } else {
            listOf("periscope", "agentsview")
        }
    }

    private fun launchProcess(project: Project) {
        val binary = resolveBinary()
        if (binary == null) {
            notify(
                project,
                "Periscope binary not found. Install periscope and ensure it is on your PATH.",
                NotificationType.WARNING,
            )
            return
        }

        resolvedPort = findFreePort(DEFAULT_PORT)
        val cmd = listOf(binary.absolutePath, "serve", "--port", resolvedPort.toString())
        logger.info("periscope: launching ${cmd.joinToString(" ")}")

        try {
            val process = ProcessBuilder(cmd)
                .redirectErrorStream(true)
                .start()

            processRef.set(process)

            Thread {
                process.inputStream.bufferedReader().use { reader ->
                    reader.lines().forEach { line ->
                        logger.debug("periscope: $line")
                    }
                }
                processRef.set(null)
                logger.info("periscope: process exited (port $resolvedPort)")
            }.also {
                it.isDaemon = true
                it.name = "periscope-stdout-drain"
                it.start()
            }

            logger.info("periscope: started on port $resolvedPort (pid ${process.pid()})")
            notifyWhenReady(project, resolvedPort)
        } catch (e: Exception) {
            logger.warn("periscope: failed to start", e)
            processRef.set(null)
            notify(project, "Failed to start Periscope: ${e.message}", NotificationType.ERROR)
        }
    }

    private fun notifyWhenReady(project: Project, port: Int) {
        Thread {
            val ready = waitForServerReady(port)
            when {
                ready -> notify(
                    project,
                    "Periscope ready on port $port",
                    NotificationType.INFORMATION,
                )
                processRef.get()?.isAlive == true -> notify(
                    project,
                    "Periscope started on port $port (still starting…)",
                    NotificationType.WARNING,
                )
            }
        }.also {
            it.isDaemon = true
            it.name = "periscope-readiness-wait"
            it.start()
        }
    }

    private fun waitForServerReady(port: Int): Boolean {
        val deadline = System.currentTimeMillis() + READINESS_TIMEOUT_MS
        val healthUrl = URI("http://localhost:$port/api/v1/health").toURL()

        while (System.currentTimeMillis() < deadline) {
            if (processRef.get()?.isAlive != true) {
                return false
            }
            if (probeHealth(healthUrl)) {
                return true
            }
            Thread.sleep(READINESS_POLL_MS)
        }
        return false
    }

    private fun probeHealth(healthUrl: URL): Boolean {
        val connection = healthUrl.openConnection() as HttpURLConnection
        return try {
            connection.connectTimeout = READINESS_CONNECT_TIMEOUT_MS
            connection.readTimeout = READINESS_CONNECT_TIMEOUT_MS
            connection.requestMethod = "GET"
            connection.responseCode in 200..299
        } catch (_: Exception) {
            false
        } finally {
            connection.disconnect()
        }
    }

    private fun stopProcess() {
        val process = processRef.getAndSet(null) ?: return
        logger.info("periscope: stopping process")
        process.destroy()
        if (!process.waitFor(3, TimeUnit.SECONDS)) {
            process.destroyForcibly()
        }
        logger.info("periscope: stopped")
    }

    /**
     * Locate the Periscope binary. Prefers `periscope`, then legacy `agentsview`.
     * Tries PATH first, then common install locations.
     */
    private fun resolveBinary(): File? {
        for (name in binaryNames()) {
            findOnPath(name)?.let { return it }
        }

        val homeDir = System.getProperty("user.home")
        val relativePaths = listOf(
            "bin",
            ".local/bin",
        )
        for (name in binaryNames()) {
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
        for (name in binaryNames()) {
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
            logger.info("periscope notification ($type): $message")
        }
    }
}
