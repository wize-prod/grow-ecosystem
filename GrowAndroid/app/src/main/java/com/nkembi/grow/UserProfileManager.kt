package com.nkembi.grow

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Chinese & Japanese Multi-Tenant Profile Isolation Engine
 * Ensures complete local data separation for distinct users (e.g. Mother vs. Primary).
 */
class UserProfileManager(private val context: Context) {

    data class UserProfile(
        val id: String,
        val displayName: String,
        val email: String,
        val userGoal: String,
        val targetKcal: Double,
        val targetProtein: Double,
        val targetWaterMl: Double,
        val isPrimary: Boolean
    ) {
        val userKey: String
            get() {
                val clean = email.trim().lowercase()
                return when {
                    clean.isEmpty() || clean == "wize.prod6878@gmail.com" -> "primary_wize_prod"
                    else -> "user_" + clean.replace("@", "_at_").replace(".", "_")
                }
            }
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences("grow_user_profiles_v1", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_ACTIVE_USER = "active_user_key"
        private const val KEY_PROFILES_JSON = "registered_profiles_json"
    }

    fun getActiveProfile(): UserProfile {
        val activeKey = prefs.getString(KEY_ACTIVE_USER, "user_mama") ?: "user_mama"
        val profiles = getAllProfiles()
        return profiles.find { it.userKey == activeKey } ?: defaultMotherProfile()
    }

    fun defaultMotherProfile(): UserProfile {
        return UserProfile(
            id = "profile_mama",
            displayName = "Mama",
            email = "mama.grow@gmail.com",
            userGoal = "Vitalität & Mobilität",
            targetKcal = 1600.0,
            targetProtein = 80.0,
            targetWaterMl = 2000.0,
            isPrimary = false
        )
    }

    fun getAllProfiles(): List<UserProfile> {
        val raw = prefs.getString(KEY_PROFILES_JSON, null) ?: return listOf(defaultMotherProfile())
        val list = mutableListOf<UserProfile>()
        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    UserProfile(
                        id = obj.getString("id"),
                        displayName = obj.getString("displayName"),
                        email = obj.optString("email", ""),
                        userGoal = obj.optString("userGoal", "Gesundheit"),
                        targetKcal = obj.optDouble("targetKcal", 1600.0),
                        targetProtein = obj.optDouble("targetProtein", 80.0),
                        targetWaterMl = obj.optDouble("targetWaterMl", 2000.0),
                        isPrimary = obj.optBoolean("isPrimary", false)
                    )
                )
            }
        } catch (_: Exception) {
            return listOf(defaultMotherProfile())
        }
        return list
    }

    fun saveProfile(profile: UserProfile, makeActive: Boolean = true) {
        val current = getAllProfiles().toMutableList()
        current.removeAll { it.userKey == profile.userKey }
        current.add(profile)

        val array = JSONArray()
        for (p in current) {
            val obj = JSONObject().apply {
                put("id", p.id)
                put("displayName", p.displayName)
                put("email", p.email)
                put("userGoal", p.userGoal)
                put("targetKcal", p.targetKcal)
                put("targetProtein", p.targetProtein)
                put("targetWaterMl", p.targetWaterMl)
                put("isPrimary", p.isPrimary)
            }
            array.put(obj)
        }

        prefs.edit().apply {
            putString(KEY_PROFILES_JSON, array.toString())
            if (makeActive) {
                putString(KEY_ACTIVE_USER, profile.userKey)
            }
            apply()
        }

        // Ensure isolated directory exists
        getUserStorageDirectory(profile.userKey)
    }

    fun switchProfile(userKey: String): UserProfile? {
        val target = getAllProfiles().find { it.userKey == userKey } ?: return null
        prefs.edit().putString(KEY_ACTIVE_USER, target.userKey).apply()
        return target
    }

    fun getUserStorageDirectory(userKey: String): File {
        val dir = File(context.filesDir, "userData/$userKey")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }
}
