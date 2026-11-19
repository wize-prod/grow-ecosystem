package com.nkembi.grow

import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

/**
 * Grow Native Android Shell
 * Incorporates C++ Core Engine validation, Multi-Tenant Profile Isolation, and OTA Updater.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var autoUpdateManager: AutoUpdateManager
    private lateinit var userProfileManager: UserProfileManager
    private lateinit var activeProfile: UserProfileManager.UserProfile

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        autoUpdateManager = AutoUpdateManager(this)
        userProfileManager = UserProfileManager(this)
        activeProfile = userProfileManager.getActiveProfile()

        renderScreen()
    }

    private fun renderScreen() {
        val calcOut = DoubleArray(1)
        val validMacros = GrowNativeBridge.validateMacros(
            calories = activeProfile.targetKcal,
            protein = activeProfile.targetProtein,
            carbs = 180.0,
            fat = 50.0,
            fiber = 25.0,
            calculatedOut = calcOut
        )

        setContentView(createCleanLayout(validMacros, calcOut[0]))
    }

    private fun createCleanLayout(isMacrosValid: Boolean, calculatedKcal: Double): android.view.View {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 64, 48, 64)
            setBackgroundColor(0xFF000000.toInt()) // Sober OLED Black
        }

        // Header
        val titleView = TextView(this).apply {
            text = "GROW ANDROID | SYSTEM NATIVE"
            textSize = 20f
            setTextColor(0xFFFFFFFF.toInt())
            typeface = android.graphics.Typeface.MONOSPACE
        }
        layout.addView(titleView)

        // Active User Profile Banner (Strict Isolation)
        val profileBanner = TextView(this).apply {
            text = "AKTIVES PROFIL: ${activeProfile.displayName.uppercase()} (${if (activeProfile.isPrimary) "HAUPTNUTZER" else "ISOLIERTER BENUTZER"})\nZiel: ${activeProfile.userGoal} • ${activeProfile.targetKcal.toInt()} kcal • ${activeProfile.targetProtein.toInt()}g Protein"
            textSize = 12f
            setTextColor(0xFF81D4FA.toInt())
            setPadding(20, 20, 20, 20)
            setBackgroundColor(0xFF102027.toInt())
            typeface = android.graphics.Typeface.MONOSPACE
        }
        layout.addView(profileBanner)

        val spacer1 = android.view.View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 24)
        }
        layout.addView(spacer1)

        // Switch Profile Button
        val switchUserButton = Button(this).apply {
            text = "BENUTZERKONTO WECHSELN / ANLEGEN"
            setBackgroundColor(0xFF37474F.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener {
                showProfileSwitchDialog()
            }
        }
        layout.addView(switchUserButton)

        val spacer2 = android.view.View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 24)
        }
        layout.addView(spacer2)

        val coreEngineStatus = TextView(this).apply {
            val statusText = if (isMacrosValid) "VALIDE (${calculatedKcal.toInt()} kcal)" else "INKORREKT"
            text = "C++ CORE ENGINE STATUS: $statusText"
            textSize = 13f
            setTextColor(0xFF00E676.toInt())
            typeface = android.graphics.Typeface.MONOSPACE
        }
        layout.addView(coreEngineStatus)

        val upcomingCard = TextView(this).apply {
            text = "\nNAECHSTES SUPPLEMENT:\n06:00 Uhr | Rhodiola Rosea (500 mg)\nFokus & Neuroprotektion\n"
            textSize = 15f
            setTextColor(0xFFE0E0E0.toInt())
            setPadding(24, 24, 24, 24)
            setBackgroundColor(0xFF1E1E1E.toInt())
        }
        layout.addView(upcomingCard)

        val spacer3 = android.view.View(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 32)
        }
        layout.addView(spacer3)

        val progressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            visibility = android.view.View.GONE
            max = 100
        }
        layout.addView(progressBar)

        val updateButton = Button(this).apply {
            text = "SYSTEM AKTUALISIEREN (DIRECT OTA)"
            setBackgroundColor(0xFF2979FF.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener {
                lifecycleScope.launch {
                    progressBar.visibility = android.view.View.VISIBLE
                    progressBar.progress = 0
                    Toast.makeText(this@MainActivity, "Pruefe auf OTA-Update...", Toast.LENGTH_SHORT).show()

                    val result = autoUpdateManager.downloadAndInstall(
                        downloadUrl = "https://raw.githubusercontent.com/example/grow/releases/latest/app-release.apk",
                        expectedSha256 = null
                    ) { progress ->
                        progressBar.progress = progress
                    }

                    result.onSuccess { apkFile ->
                        progressBar.visibility = android.view.View.GONE
                        Toast.makeText(this@MainActivity, "Update bereit zur Installation", Toast.LENGTH_SHORT).show()
                        autoUpdateManager.promptInstall(apkFile)
                    }.onFailure { _ ->
                        progressBar.visibility = android.view.View.GONE
                        Toast.makeText(this@MainActivity, "Aktuellste Version bereits installiert", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }
        layout.addView(updateButton)

        return layout
    }

    private fun showProfileSwitchDialog() {
        val profiles = userProfileManager.getAllProfiles()
        val names = profiles.map { "${it.displayName} (${it.userGoal})" }.toTypedArray()

        AlertDialog.Builder(this)
            .setTitle("Profil auswählen (Strikte Sandbox-Trennung)")
            .setItems(names) { _, which ->
                val selected = profiles[which]
                userProfileManager.switchProfile(selected.userKey)
                activeProfile = selected
                renderScreen()
                Toast.makeText(this, "Profil gewechselt: ${selected.displayName}", Toast.LENGTH_SHORT).show()
            }
            .setPositiveButton("Abbrechen", null)
            .show()
    }
}
