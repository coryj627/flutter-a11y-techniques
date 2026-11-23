// L3 (tree) and L4 (TalkBack) for C26 Progress indicator on Android.
// Spec: docs/specs/C26-progress-indicator.md.
//
// Each example's task runs four steps of one second once its button is
// pressed (lib/techniques/c26_progress_indicator/examples.dart). Every
// reading after a press waits in a bounded loop for the state it expects.
package dev.fluttera11y.flutter_a11y_techniques

import android.util.Log
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityNodeInfo.RangeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val PROGRESS_BAR = "android.widget.ProgressBar"

@RunWith(AndroidJUnit4::class)
class C26ProgressIndicatorTest : TechniqueTest("C26") {
    private fun open(slug: String) = openExample(slug, By.desc(c26Titles.getValue(slug)), settleMillis = 500)

    private fun start(slug: String) = "c26-$slug-start"
    private fun status(slug: String) = "c26-$slug-status"

    private fun nodeOrNull(id: String): AccessibilityNodeInfo? =
        all().firstOrNull { it.viewIdResourceName == id }

    /** The status line's text: its content description, or its text. */
    private fun statusText(slug: String): String =
        node(status(slug)).let { it.contentDescription?.toString() ?: it.text?.toString().orEmpty() }

    /** Waits up to [ms] for [check] to be true, reading every 100 ms. */
    private fun waitFor(ms: Long, check: () -> Boolean): Boolean {
        val end = System.currentTimeMillis() + ms
        while (System.currentTimeMillis() < end) {
            if (check()) return true
            Thread.sleep(100)
        }
        return check()
    }

    private fun press(slug: String) =
        assertTrue("click on ${start(slug)}", node(start(slug)).performAction(AccessibilityNodeInfo.ACTION_CLICK))

    private fun expectStatus(slug: String, text: String, ms: Long = 3_000) {
        waitFor(ms) { statusText(slug) == text }
        assertEquals("$slug status", text, statusText(slug))
    }

    /** The bar's range as "type min..max cur", or "none". */
    private fun range(n: AccessibilityNodeInfo): String = n.rangeInfo?.let {
        val type = when (it.type) {
            RangeInfo.RANGE_TYPE_INT -> "int"
            RangeInfo.RANGE_TYPE_FLOAT -> "float"
            RangeInfo.RANGE_TYPE_PERCENT -> "percent"
            else -> "type ${it.type}"
        }
        "$type ${it.min}..${it.max} cur=${it.current}"
    } ?: "none"

    @Test
    fun goodLinearIsAProgressBarNamedWithItsValueAtEachStep() {
        open("good-linear")
        val bar = node("c26-good-linear-bar")
        assertEquals(PROGRESS_BAR, bar.type())
        // The value first, then the name (the C26 probe's p01).
        assertEquals("0, Report upload", bar.name())
        assertEquals("float 0.0..100.0 cur=0.0", range(bar))
        assertFalse("not clickable", bar.isClickable)
        // The words above the bar are not a node of their own.
        assertTrue(all().none { it.name() == "Report upload" || it.text?.toString() == "Report upload" })
        press("good-linear")
        val seen = mutableListOf<String>()
        for (cur in listOf("25.0", "50.0", "75.0", "100.0")) {
            waitFor(3_000) { range(node("c26-good-linear-bar")).endsWith("cur=$cur") }
            seen.add(range(node("c26-good-linear-bar")))
        }
        assertEquals(listOf("25.0", "50.0", "75.0", "100.0").map { "float 0.0..100.0 cur=$it" }, seen)
        assertEquals("100, Report upload", node("c26-good-linear-bar").name())
    }

    @Test
    fun goodStatusLinesArePoliteLiveRegionsThatSayHowItGoesAndThatItEnded() {
        for (slug in listOf("good-linear", "good-circular", "good-cupertino")) {
            open(slug)
            assertEquals("$slug live region", View.ACCESSIBILITY_LIVE_REGION_POLITE, node(status(slug)).liveRegion)
            val upload = slug == "good-linear"
            expectStatus(slug, if (upload) "Not started" else "Inbox not loaded")
            press(slug)
            if (upload) {
                expectStatus(slug, "Upload started", 1_500)
                expectStatus(slug, "Half uploaded")
                expectStatus(slug, "Upload complete")
            } else {
                expectStatus(slug, "Loading started", 1_500)
                expectStatus(slug, "Inbox loaded", 6_000)
            }
            assertEquals("$slug live region at the end", View.ACCESSIBILITY_LIVE_REGION_POLITE, node(status(slug)).liveRegion)
        }
    }

    @Test
    fun goodSpinnersAreThereOnlyWhileLoadingNamedWithNoRange() {
        for (slug in listOf("good-circular", "good-cupertino")) {
            open(slug)
            val id = "c26-$slug-spinner"
            assertNull("$slug: no spinner before", nodeOrNull(id))
            press(slug)
            assertTrue("$slug: spinner shown", waitFor(3_000) { nodeOrNull(id) != null })
            val spinner = nodeOrNull(id)!!
            assertEquals("$slug spinner name", "Loading inbox", spinner.name())
            assertNull("$slug: no range", spinner.rangeInfo)
            // FL-256: neither is a ProgressBar.
            assertEquals("$slug spinner class", "android.view.View", spinner.type())
            expectStatus(slug, "Inbox loaded", 6_000)
            assertTrue("$slug: spinner gone", waitFor(2_000) { nodeOrNull(id) == null })
        }
    }

    @Test
    fun tabReachesTheButtonAndNeverTheIndicator() {
        for (slug in listOf("good-linear", "good-circular", "good-cupertino")) {
            open(slug)
            press(slug)
            Thread.sleep(1_200)
            val stops = mutableListOf<String>()
            for (i in 0 until 4) {
                device.executeShellCommand("input keyevent KEYCODE_TAB")
                Thread.sleep(500)
                val f = all().lastOrNull { it.isFocused }
                stops.add(f?.viewIdResourceName ?: f?.name() ?: "(none)")
            }
            assertTrue("$slug: Tab reached the button: $stops", stops.contains(start(slug)))
            assertTrue("$slug: Tab never on the indicator: $stops", stops.none { it.contains("-bar") || it.contains("-spinner") })
        }
    }

    @Test
    fun enterOnTheButtonStartsTheTask() {
        open("good-linear")
        var reached = false
        for (i in 0 until 4) {
            device.executeShellCommand("input keyevent KEYCODE_TAB")
            Thread.sleep(500)
            if (node(start("good-linear")).isFocused) {
                reached = true
                break
            }
        }
        assertTrue("Tab reached the button", reached)
        device.executeShellCommand("input keyevent KEYCODE_ENTER")
        expectStatus("good-linear", "Upload started", 1_500)
    }

    @Test
    fun badNoLabelIsNamedByItsValueAlone() {
        open("bad-no-label")
        val bar = node("c26-bad-no-label-bar")
        assertEquals(PROGRESS_BAR, bar.type())
        assertEquals("0", bar.name())
        // The words are a node of their own.
        assertEquals(1, all().count { it.name() == "Report upload" })
        open("good-linear")
        assertEquals("0, Report upload", node("c26-good-linear-bar").name())
    }

    @Test
    fun badSilentEndHasNoLiveRegionAndGoodLinearHasOne() {
        open("bad-silent-end")
        press("bad-silent-end")
        expectStatus("bad-silent-end", "Upload complete", 7_000)
        assertEquals(View.ACCESSIBILITY_LIVE_REGION_NONE, node(status("bad-silent-end")).liveRegion)
        assertTrue("no live region anywhere", all().none { it.liveRegion != View.ACCESSIBILITY_LIVE_REGION_NONE })
        open("good-linear")
        assertEquals(View.ACCESSIBILITY_LIVE_REGION_POLITE, node(status("good-linear")).liveRegion)
    }

    @Test
    fun badAdaptiveIsMaterialsSpinnerOnAndroid() {
        // FL-257 is on iOS and in a browser on a Mac; on Android the
        // adaptive spinner is Material's, named.
        open("bad-adaptive")
        press("bad-adaptive")
        assertTrue(waitFor(3_000) { nodeOrNull("c26-bad-adaptive-spinner") != null })
        assertEquals("Loading inbox", nodeOrNull("c26-bad-adaptive-spinner")!!.name())
    }

    @Test
    fun badCupertinoBarExposesNoNameAndNoRange() {
        open("bad-cupertino-bar")
        fun check(when_: String) {
            val bar = nodeOrNull("c26-bad-cupertino-bar-bar")
            if (bar != null) {
                assertEquals("$when_: no name", "", bar.name())
                assertEquals("$when_: no text", "", bar.text?.toString().orEmpty())
                assertNull("$when_: no range", bar.rangeInfo)
                assertFalse("$when_: not a ProgressBar", bar.type() == PROGRESS_BAR)
            }
            assertTrue("$when_: no ProgressBar anywhere", all().none { it.type() == PROGRESS_BAR })
        }
        check("at rest")
        press("bad-cupertino-bar")
        expectStatus("bad-cupertino-bar", "Half uploaded", 4_000)
        check("while running")
    }

    /**
     * L4. For each example: TalkBack focus on its indicator, where it has
     * one at rest; then focus parked on the button and the button pressed
     * with the click action, and everything TalkBack says until the task
     * has ended (`-run`); for bad-silent-end, focus then moved to the
     * status line, which must be read, so that the silence before it is
     * not an empty capture (`-status`). tool/talkback.py reads the speech
     * between the markers.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        for (slug in c26Titles.keys) {
            openExampleInAnyWindow(slug) { it.name() == c26Titles.getValue(slug) }
            Thread.sleep(8_000)
            val bar = "c26-$slug-bar"
            if (slug in listOf("good-linear", "bad-no-label", "bad-silent-end")) {
                Log.i(talkBackTag, "FOCUS $bar")
                talkBackFocus(bar) { nodeInAnyWindow(bar) }
                Thread.sleep(4_000)
            }
            Log.i(talkBackTag, "FOCUS c26-$slug-start")
            talkBackFocus(start(slug)) { nodeInAnyWindow(start(slug)) }
            Thread.sleep(3_000)
            Log.i(talkBackTag, "FOCUS c26-$slug-run")
            assertTrue(nodeInAnyWindow(start(slug)).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            // The task ends 4 s after the press; TalkBack speaks a live
            // region's changes behind time (the probe's p18, where its
            // speech ran into the next marker), so the capture runs on.
            Thread.sleep(9_000)
            if (slug == "bad-silent-end") {
                Log.i(talkBackTag, "FOCUS c26-$slug-status")
                talkBackFocus(status(slug)) { nodeInAnyWindow(status(slug)) }
                Thread.sleep(4_000)
            }
            Log.i(talkBackTag, "END $slug")
        }
    }
}

private val c26Titles = mapOf(
    "good-linear" to "Material progress bar",
    "good-circular" to "Material spinner",
    "good-cupertino" to "Cupertino spinner",
    "bad-no-label" to "Progress bar with no name",
    "bad-silent-end" to "Upload that ends in silence",
    "bad-adaptive" to "Adaptive spinner",
    "bad-cupertino-bar" to "Cupertino progress bar",
)
