package com.nkembi.grow

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * Chinese OTA Self-Deployment Engine (Tencent/Sophix Pattern)
 * Bypasses Google Play Store dependencies entirely for direct, zero-cost family distribution.
 */
class AutoUpdateManager(private val context: Context) {

    data class UpdatePayload(
        val versionCode: Int,
        val versionName: String,
        val downloadUrl: String,
        val expectedSha256: String?
    )

    sealed class UpdateState {
        object Idle : UpdateState()
        object Checking : UpdateState()
        data class Available(val payload: UpdatePayload) : UpdateState()
        data class Downloading(val progressPercent: Int) : UpdateState()
        data class ReadyToInstall(val apkFile: File) : UpdateState()
        data class Error(val message: String) : UpdateState()
    }

    suspend fun downloadAndInstall(
        downloadUrl: String,
        expectedSha256: String?,
        onProgress: (Int) -> Unit
    ): Result<File> = withContext(Dispatchers.IO) {
        try {
            val url = URL(downloadUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 15000
            connection.readTimeout = 30000
            connection.connect()

            if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                return@withContext Result.failure(Exception("HTTP Fehler: ${connection.responseCode}"))
            }

            val fileLength = connection.contentLength
            val cacheDir = File(context.cacheDir, "updates")
            if (!cacheDir.exists()) cacheDir.mkdirs()

            val apkFile = File(cacheDir, "grow_release_latest.apk")
            if (apkFile.exists()) apkFile.delete()

            connection.inputStream.use { input ->
                FileOutputStream(apkFile).use { output ->
                    val data = ByteArray(8192)
                    var total: Long = 0
                    var count: Int
                    while (input.read(data).also { count = it } != -1) {
                        total += count.toLong()
                        output.write(data, 0, count)
                        if (fileLength > 0) {
                            val progress = ((total * 100) / fileLength).toInt()
                            onProgress(progress)
                        }
                    }
                }
            }

            // Poka-Yoke Integrity Gate: SHA-256 verification if provided
            if (!expectedSha256.isNullOrBlank()) {
                val actualSha256 = calculateSha256(apkFile)
                if (!actualSha256.equals(expectedSha256, ignoreCase = true)) {
                    apkFile.delete()
                    return@withContext Result.failure(Exception("Poka-Yoke Integritaetspruefung fehlgeschlagen: SHA-256 Mismatch"))
                }
            }

            Result.success(apkFile)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun promptInstall(apkFile: File) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!context.packageManager.canRequestPackageInstalls()) {
                val settingsIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(settingsIntent)
                return
            }
        }

        val apkUri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            apkFile
        )

        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
        }
        context.startActivity(installIntent)
    }

    private fun calculateSha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { stream ->
            val buffer = ByteArray(8192)
            var read: Int
            while (stream.read(buffer).also { read = it } != -1) {
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }
}
