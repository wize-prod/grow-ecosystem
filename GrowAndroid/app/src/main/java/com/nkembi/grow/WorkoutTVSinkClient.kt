package com.nkembi.grow

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

/**
 * Japanese Thin-Client Receiver (Display Sink Client)
 * Polls or listens to the primary workout phone without executing heavy state engines.
 */
class WorkoutTVSinkClient {

    data class TVWorkoutTelemetry(
        val workoutTitle: String,
        val currentExercise: String,
        val restSecondsRemaining: Int,
        val isResting: Boolean,
        val timestamp: Double
    )

    suspend fun fetchTelemetry(hostIp: String, port: Int = 8765): Result<TVWorkoutTelemetry> = withContext(Dispatchers.IO) {
        try {
            val url = URL("http://$hostIp:$port/telemetry")
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 1000
            connection.readTimeout = 1000

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = reader.readText()
                reader.close()

                val json = JSONObject(response)
                val telemetry = TVWorkoutTelemetry(
                    workoutTitle = json.optString("workout", "Unbekannt"),
                    currentExercise = json.optString("currentExercise", "Bereit"),
                    restSecondsRemaining = json.optInt("restSeconds", 0),
                    isResting = json.optBoolean("isResting", false),
                    timestamp = json.optDouble("timestamp", 0.0)
                )
                Result.success(telemetry)
            } else {
                Result.failure(Exception("HTTP Status: ${connection.responseCode}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
