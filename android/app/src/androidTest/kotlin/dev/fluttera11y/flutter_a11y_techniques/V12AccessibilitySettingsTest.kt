// L3 (tree) and L4 (TalkBack walk) for V12 Detecting accessibility settings
// on Android. Spec: docs/specs/V12-accessibility-settings.md.
//
// Each example's lines say which settings the app was told are on. A
// setting is changed while an example is open through the device's own
// settings, from the test's shell (`cmd uimode night`, `settings put`), as
// the probe did (docs/evidence/probes/v12/). Every such test reads each
// setting it may change and night mode first, sets each to a checked
// baseline (off, 1.0), shows the example at it, turns the setting on and
// off with each turn checked, and puts every one back to what it was
// before, checked, whatever the test found (withBaseline). Each
// reading after a change is waited for in a bounded loop, and each change
// is made once. Where a line must not change, the witness that the change
// reached the app is on the same screen: the screen goes dark (the app's
// dark theme), or the line's own text is laid out wider. Bold text and the
// contrast level are not changed here: on this Android a change of either
// is followed by the app starting again (FL-504).
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

private const val FONT_SCALE = "system font_scale"
private const val INVERSION = "secure accessibility_display_inversion_enabled"
private const val HIGH_TEXT_CONTRAST = "secure high_text_contrast_enabled"

/** The accessibility service settings, which no test here changes. */
private val ACCESSIBILITY = listOf("secure enabled_accessibility_services", "secure accessibility_enabled")

/** Every setting a test may change, with its baseline value: off, 1.0. */
private val BASELINE = linkedMapOf(
    FONT_SCALE to "1.0",
    INVERSION to "0",
    HIGH_TEXT_CONTRAST to "0",
) + ANIMATION_SCALES.associate { "global $it" to "1.0" }

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

    /** Sets the setting [key] ("namespace name") to [value] and checks it reads so. */
    private fun put(key: String, value: String) {
        shell("settings put $key $value")
        assertEquals("$key set", value, shell("settings get $key"))
    }

    /** Sets night mode to [mode] ("yes" or "no") and checks it reads so. */
    private fun night(mode: String) {
        shell("cmd uimode night $mode")
        assertEquals("night mode set", "Night mode: $mode", shell("cmd uimode night"))
    }

    /**
     * Runs [body] from a checked baseline: every setting of BASELINE, and
     * night mode, read and kept first; then each set to its baseline value
     * (off, 1.0) and checked. Afterwards, however [body] ends, each is put
     * back to the value it had before (deleted if it was not set) and
     * checked. A test turns a setting on and off inside [body] with [put]
     * and [night], each checked.
     */
    private fun withBaseline(body: () -> Unit) {
        val original = BASELINE.keys.associateWith { shell("settings get $it") }
        val originalNight = shell("cmd uimode night").substringAfter(":").trim()
        // The accessibility services, TalkBack among them, are changed by no
        // test here (tool/talkback.py turns TalkBack on for the walk and puts
        // the services back itself); they are read so that a test that left
        // them changed would fail.
        val services = ACCESSIBILITY.associateWith { shell("settings get $it") }
        try {
            for ((key, value) in BASELINE) put(key, value)
            night("no")
            body()
        } finally {
            for ((key, value) in original) {
                if (value == "null") shell("settings delete $key") else shell("settings put $key $value")
            }
            shell("cmd uimode night $originalNight")
            for ((key, value) in original) assertEquals("$key put back", value, shell("settings get $key"))
            assertEquals("night mode put back", "Night mode: $originalNight", shell("cmd uimode night"))
            for ((key, value) in services) assertEquals("$key unchanged", value, shell("settings get $key"))
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
     * Opened at the checked baseline with no accessibility service on. The
     * test's own connection to the accessibility framework (UiAutomation) is
     * one: once it has read the screen, the engine reports accessible
     * navigation on, which good-media-query shows; bad-read-once read it as
     * its screen was first built, before any node had been read, and shows
     * off (FL-503).
     */
    @Test
    fun eachListSaysWhatTheAppWasToldWhenItOpens() = withBaseline {
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

    /**
     * A setting that is on when the example opens: colour inversion turned on
     * from the baseline before the app starts. Both lists open saying so
     * (bad-read-once does read, once); turned off, good-media-query follows.
     */
    @Test
    fun aSettingOnWhenTheExampleOpensIsShown() = withBaseline {
        put(INVERSION, "1")
        open("bad-read-once")
        assertEquals("Invert colours: on", line("bad-read-once", "invert"))
        open("good-media-query")
        expectLine("good-media-query", "invert", "Invert colours: on")
        put(INVERSION, "0")
        expectLine("good-media-query", "invert", "Invert colours: off")
    }

    // --- A setting changed while the example is open ----------------------------
    //
    // Each from the checked baseline, the example shown at it first; each
    // turn checked on the setting itself and, for a line that must change, on
    // the line; the settings put back to what they were before the test.

    @Test
    fun goodMediaQueryFollowsDarkModeAndBack() = withBaseline {
        open("good-media-query")
        assertEquals(opened("on"), lines("good-media-query"))
        night("yes")
        expectLine("good-media-query", "dark", "Dark mode: on")
        night("no")
        expectLine("good-media-query", "dark", "Dark mode: off")
    }

    @Test
    fun goodMediaQueryFollowsRemoveAnimationsAndBack() = withBaseline {
        open("good-media-query")
        expectLine("good-media-query", "animations", "Disable animations: off")
        for (scale in ANIMATION_SCALES) put("global $scale", "0")
        expectLine("good-media-query", "animations", "Disable animations: on")
        for (scale in ANIMATION_SCALES) put("global $scale", "1.0")
        expectLine("good-media-query", "animations", "Disable animations: off")
    }

    @Test
    fun goodMediaQueryFollowsColourInversionAndBack() = withBaseline {
        open("good-media-query")
        expectLine("good-media-query", "invert", "Invert colours: off")
        put(INVERSION, "1")
        expectLine("good-media-query", "invert", "Invert colours: on")
        put(INVERSION, "0")
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
     * itself: at 1.5, text of 14 was drawn at 22 in the probe (157%). The
     * line gives the scale at 14, so it is checked to have grown by at least
     * 30%, not for one number, which the curve of another Android version may
     * change.
     */
    @Test
    fun goodMediaQueryFollowsTheFontScaleAndBack() = withBaseline {
        open("good-media-query")
        expectLine("good-media-query", "scale", "Text scale: 100%")
        put(FONT_SCALE, "1.5")
        val n = waitForScale("good-media-query", 130)
        assertTrue("Text scale: $n%, at least 130%", n >= 130)
        put(FONT_SCALE, "1.0")
        expectLine("good-media-query", "scale", "Text scale: 100%")
    }

    /**
     * "High contrast text" sets no flag: the engine reads the contrast level
     * (API 34 and later), not this setting (FL-504). The setting is checked
     * to read on; the control that the line is read at all is the font
     * scale, changed after it on the same screen, which the line follows.
     */
    @Test
    fun highContrastTextLeavesHighContrastOff() = withBaseline {
        open("good-media-query")
        expectLine("good-media-query", "contrast", "High contrast: off")
        put(HIGH_TEXT_CONTRAST, "1")
        expectLineStays("good-media-query", "contrast", "High contrast: off")
        put(FONT_SCALE, "1.5")
        assertTrue("the scale line grew", waitForScale("good-media-query", 130) >= 130)
        assertEquals("High contrast: off", line("good-media-query", "contrast"))
    }

    @Test
    fun badReadOnceKeepsItsReadingWhenTheScreenGoesDark() = withBaseline {
        open("bad-read-once")
        assertEquals(opened("off"), lines("bad-read-once"))
        assertTrue("light screen", meanLuminance() > 0.5)
        night("yes")
        // The witness that the change reached the app: its dark theme is drawn.
        val end = System.currentTimeMillis() + 8_000
        while (meanLuminance() > 0.2 && System.currentTimeMillis() < end) Thread.sleep(200)
        assertTrue("dark screen", meanLuminance() <= 0.2)
        assertEquals(opened("off"), lines("bad-read-once"))
    }

    @Test
    fun badReadOnceKeepsItsReadingWhenTheTextGrows() = withBaseline {
        open("bad-read-once")
        assertEquals("Text scale: 100%", line("bad-read-once", "scale"))
        val before = widthOf("v12-bad-read-once-scale")
        put(FONT_SCALE, "1.5")
        // The witness that the change reached the app: the line's own text is
        // laid out wider.
        val end = System.currentTimeMillis() + 8_000
        while (widthOf("v12-bad-read-once-scale") < before * 1.3 && System.currentTimeMillis() < end) Thread.sleep(200)
        assertTrue("the line grew", widthOf("v12-bad-read-once-scale") >= before * 1.3)
        assertEquals("Text scale: 100%", line("bad-read-once", "scale"))
    }

    /**
     * On Android "Remove animations" sets disableAnimations and not
     * reduceMotion, so both motion examples say on: bad-animations-only's
     * defect is iOS's.
     */
    @Test
    fun bothMotionExamplesFollowRemoveAnimations() = withBaseline {
        for (slug in listOf("good-motion", "bad-animations-only")) {
            open(slug)
            expectLine(slug, "motion", "Reduce motion: off")
            for (scale in ANIMATION_SCALES) put("global $scale", "0")
            expectLine(slug, "motion", "Reduce motion: on")
            for (scale in ANIMATION_SCALES) put("global $scale", "1.0")
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
