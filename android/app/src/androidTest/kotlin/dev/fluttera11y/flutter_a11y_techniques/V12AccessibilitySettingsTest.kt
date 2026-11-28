// L3 (tree) and L4 (TalkBack walk) for V12 Detecting accessibility settings
// on Android. Spec: docs/specs/V12-accessibility-settings.md.
//
// Each example's lines say which settings the app was told are on. A
// setting is changed while an example is open through the device's own
// settings, from the test's shell (`cmd uimode night`, `settings put`), as
// the probe did (docs/evidence/probes/v12/); every setting a test changes
// is read first and put back afterwards, whatever the test found. Each
// reading after a change is waited for in a bounded loop, and each change
// is made once. Where a line must not change, the witness that the change
// reached the app is on the same screen: the screen goes dark (the app's
// dark theme), or the line's own text is laid out wider. Bold text and the
// contrast level are not changed here: on this Android each change of them
// recreates the activity, and the app starts again (FL-504).
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Bitmap
import android.graphics.Rect
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private val KEYS = listOf("navigation", "bold", "contrast", "invert", "animations", "labels", "dark", "scale")

/** A settings list with nothing changed, accessible navigation [navigation]. */
private fun opened(navigation: String) = listOf(
    "Accessible navigation: $navigation", "Bold text: off", "High contrast: off", "Invert colours: off",
    "Disable animations: off", "Switch labels: off", "Dark mode: off", "Text scale: 100%",
)

/** The three animation scales that Android's "Remove animations" sets to 0. */
private val ANIMATION_SCALES = listOf("transition_animation_scale", "window_animation_scale", "animator_duration_scale")

@RunWith(AndroidJUnit4::class)
class V12AccessibilitySettingsTest : TechniqueTest("V12") {
    private fun open(slug: String) = openExample(slug, By.desc(v12Titles.getValue(slug)), settleMillis = 500)

    private fun shell(command: String): String = device.executeShellCommand(command).trim()

    private fun line(slug: String, key: String): String = node("v12-$slug-$key").name()

    private fun lines(slug: String): List<String> = KEYS.map { line(slug, it) }

    /** Waits up to [millis] for the line [key] of [slug] to say [want]; a missed lookup is retried. */
    private fun expectLine(slug: String, key: String, want: String, millis: Long = 8_000) {
        val end = System.currentTimeMillis() + millis
        var seen = ""
        while (System.currentTimeMillis() < end) {
            seen = try { line(slug, key) } catch (e: AssertionError) { "(no node: ${e.message})" }
            if (seen == want) return
            Thread.sleep(200)
        }
        assertEquals("$slug $key", want, seen)
    }

    /** Checks every 200 ms for [millis] that the line [key] of [slug] still says [want]. */
    private fun expectLineStays(slug: String, key: String, want: String, millis: Long = 4_000) {
        val end = System.currentTimeMillis() + millis
        do {
            assertEquals("$slug $key", want, line(slug, key))
            Thread.sleep(200)
        } while (System.currentTimeMillis() < end)
    }

    /**
     * Runs [body] with each setting of [changes] ("namespace name" to value)
     * set, and puts every one back as it was afterwards: deleted if it was
     * not set before.
     */
    private fun withSettings(changes: Map<String, String>, body: () -> Unit) {
        val original = changes.keys.associateWith { shell("settings get $it") }
        try {
            for ((key, value) in changes) shell("settings put $key $value")
            // The change took: each reads back as set.
            for ((key, value) in changes) assertEquals("$key set", value, shell("settings get $key"))
            body()
        } finally {
            for ((key, value) in original) {
                if (value == "null") shell("settings delete $key") else shell("settings put $key $value")
            }
            for ((key, value) in original) assertEquals("$key put back", value, shell("settings get $key"))
        }
    }

    /** Runs [body] in dark mode, and puts the night mode back as it was afterwards. */
    private fun withDarkMode(body: () -> Unit) {
        val original = shell("cmd uimode night").substringAfter(":").trim()
        try {
            shell("cmd uimode night yes")
            // The change took.
            assertEquals("night mode set", "Night mode: yes", shell("cmd uimode night"))
            body()
        } finally {
            shell("cmd uimode night $original")
            assertEquals("night mode put back", "Night mode: $original", shell("cmd uimode night"))
        }
    }

    /** The mean relative luminance of the screen, sampled every 8 pixels. */
    private fun meanLuminance(): Double {
        val shot: Bitmap = automation.takeScreenshot()
        fun lin(v: Int): Double { val s = v / 255.0; return if (s <= 0.04045) s / 12.92 else Math.pow((s + 0.055) / 1.055, 2.4) }
        var sum = 0.0
        var n = 0
        for (y in 0 until shot.height step 8) for (x in 0 until shot.width step 8) {
            val p = shot.getPixel(x, y)
            sum += 0.2126 * lin((p shr 16) and 255) + 0.7152 * lin((p shr 8) and 255) + 0.0722 * lin(p and 255)
            n++
        }
        return sum / n
    }

    private fun widthOf(id: String): Int = Rect().also { node(id).getBoundsInScreen(it) }.width()

    // --- When an example opens ------------------------------------------------

    /**
     * Opened with no accessibility service on. The test's own connection to
     * the accessibility framework (UiAutomation) is one: once it has read the
     * screen, the engine reports accessible navigation on, which
     * good-media-query shows; bad-read-once read it as its screen was first
     * built, before any node had been read, and shows off (FL-503).
     */
    @Test
    fun eachListSaysWhatTheAppWasToldWhenItOpens() {
        open("good-media-query")
        expectLine("good-media-query", "navigation", "Accessible navigation: on")
        assertEquals(opened("on"), lines("good-media-query"))
        open("bad-read-once")
        assertEquals(opened("off"), lines("bad-read-once"))
        for (slug in listOf("good-motion", "bad-animations-only")) {
            open(slug)
            assertEquals(slug, "Reduce motion: off", line(slug, "motion"))
        }
    }

    // --- A setting changed while the example is open ----------------------------

    @Test
    fun goodMediaQueryFollowsDarkModeAndBack() {
        open("good-media-query")
        withDarkMode { expectLine("good-media-query", "dark", "Dark mode: on") }
        expectLine("good-media-query", "dark", "Dark mode: off")
    }

    @Test
    fun goodMediaQueryFollowsRemoveAnimationsAndBack() {
        open("good-media-query")
        withSettings(ANIMATION_SCALES.associate { "global $it" to "0" }) {
            expectLine("good-media-query", "animations", "Disable animations: on")
        }
        expectLine("good-media-query", "animations", "Disable animations: off")
    }

    @Test
    fun goodMediaQueryFollowsColourInversionAndBack() {
        open("good-media-query")
        withSettings(mapOf("secure accessibility_display_inversion_enabled" to "1")) {
            expectLine("good-media-query", "invert", "Invert colours: on")
        }
        expectLine("good-media-query", "invert", "Invert colours: off")
    }

    /** The percentage the scale line of [slug] says, waited for until it is at least [least]. */
    private fun waitForScale(slug: String, least: Int, millis: Long = 8_000): Int {
        val end = System.currentTimeMillis() + millis
        var n = 0
        while (System.currentTimeMillis() < end) {
            n = line(slug, "scale").removePrefix("Text scale: ").removeSuffix("%").toIntOrNull() ?: 0
            if (n >= least) return n
            Thread.sleep(200)
        }
        return n
    }

    /**
     * Android 14 and later scale text by a curve, not by the font scale
     * itself: at 1.5, text of 14 points was drawn at 22 in the probe (157%).
     * The line gives the scale at 14 points, so it is checked to have grown
     * by at least 30%, not for one number, which the curve of another
     * Android version may change.
     */
    @Test
    fun goodMediaQueryFollowsTheFontScaleAndBack() {
        open("good-media-query")
        withSettings(mapOf("system font_scale" to "1.5")) {
            val n = waitForScale("good-media-query", 130)
            assertTrue("Text scale: $n%, at least 130%", n >= 130)
        }
        expectLine("good-media-query", "scale", "Text scale: 100%")
    }

    /**
     * "High contrast text" sets no flag: the engine reads the contrast level
     * (API 34 and later), not this setting (FL-504). The witness that the
     * line is read at all is the font scale, changed after it on the same
     * screen.
     */
    @Test
    fun highContrastTextLeavesHighContrastOff() {
        open("good-media-query")
        withSettings(mapOf("secure high_text_contrast_enabled" to "1")) {
            expectLineStays("good-media-query", "contrast", "High contrast: off")
            withSettings(mapOf("system font_scale" to "1.5")) {
                assertTrue("the scale line grew", waitForScale("good-media-query", 130) >= 130)
            }
        }
    }

    @Test
    fun badReadOnceKeepsItsReadingWhenTheScreenGoesDark() {
        open("bad-read-once")
        assertTrue("light screen", meanLuminance() > 0.5)
        withDarkMode {
            // The witness: the app's dark theme is drawn.
            val end = System.currentTimeMillis() + 8_000
            while (meanLuminance() > 0.2 && System.currentTimeMillis() < end) Thread.sleep(200)
            assertTrue("dark screen", meanLuminance() <= 0.2)
            assertEquals(opened("off"), lines("bad-read-once"))
        }
    }

    @Test
    fun badReadOnceKeepsItsReadingWhenTheTextGrows() {
        open("bad-read-once")
        val before = widthOf("v12-bad-read-once-scale")
        withSettings(mapOf("system font_scale" to "1.5")) {
            // The witness: the line's own text is laid out wider.
            val end = System.currentTimeMillis() + 8_000
            while (widthOf("v12-bad-read-once-scale") < before * 1.3 && System.currentTimeMillis() < end) Thread.sleep(200)
            assertTrue("the line grew", widthOf("v12-bad-read-once-scale") >= before * 1.3)
            assertEquals("Text scale: 100%", line("bad-read-once", "scale"))
        }
    }

    /**
     * On Android "Remove animations" sets disableAnimations and not
     * reduceMotion, so both motion examples say on: bad-animations-only's
     * defect is iOS's.
     */
    @Test
    fun bothMotionExamplesFollowRemoveAnimations() {
        for (slug in listOf("good-motion", "bad-animations-only")) {
            open(slug)
            withSettings(ANIMATION_SCALES.associate { "global $it" to "0" }) {
                expectLine(slug, "motion", "Reduce motion: on")
            }
            expectLine(slug, "motion", "Reduce motion: off")
        }
    }

    /**
     * L4. TalkBack is on before each example opens; focus is moved to each
     * line in turn, and tool/talkback.py reads what TalkBack says. Skips
     * unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val byId = { id: String -> Stop(id) { node(id) } }
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-media-query" to KEYS.map { byId("v12-good-media-query-$it") },
            "good-motion" to listOf(byId("v12-good-motion-motion")),
            "bad-read-once" to KEYS.map { byId("v12-bad-read-once-$it") },
            "bad-animations-only" to listOf(byId("v12-bad-animations-only-motion")),
        )
        talkBackWalk(
            walk,
            open = { slug -> open(slug) },
            dwellMillis = { 5_000 },
        )
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val v12Titles = mapOf(
    "good-media-query" to "Settings from MediaQuery",
    "good-motion" to "Reduce motion from both flags",
    "bad-read-once" to "Settings read once",
    "bad-animations-only" to "Reduce motion from one flag",
)
