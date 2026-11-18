// L3 (tree) and L4 (TalkBack walk) for F10 Slider on Android.
// Spec: docs/specs/F10-slider.md.
//
// A Flutter slider is an android.widget.SeekBar with no RangeInfo. Its
// value and its name are both in the content description, "40%, Volume",
// which is what TalkBack reads. Flutter's increase and decrease actions are
// scroll forward and backward.
//
// The keyboard is not checked here: key events sent with UI Automator did
// not move Flutter's focus in a first try, so keyboard reach and the keys
// are asserted in the widget tests and on the web.
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val SEEK_BAR = "android.widget.SeekBar"
private const val BUTTON = "android.widget.Button"

@RunWith(AndroidJUnit4::class)
class F10SliderTest : TechniqueTest("F10") {
    private fun open(slug: String) = openExample(slug, By.res("f10-$slug-count"))

    override val countName = "change count"

    private fun sliderId(slug: String) =
        if (slug.endsWith("value-text") || slug.endsWith("percent-value")) "f10-$slug-rating" else "f10-$slug-volume"

    private fun slider(slug: String) = node(sliderId(slug))

    private fun waitForName(slug: String, expected: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && slider(slug).name() != expected) Thread.sleep(100)
        assertEquals("description of $slug", expected, slider(slug).name())
    }

    private fun increase(slug: String) =
        assertTrue(slug, slider(slug).performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD))

    private fun decrease(slug: String) =
        assertTrue(slug, slider(slug).performAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD))

    private fun bounds(node: AccessibilityNodeInfo) = Rect().also { node.getBoundsInScreen(it) }

    /**
     * Where a tap or a drag reaches the track, at [along] of its width. A
     * custom slider's node is the text above the track as well, inside a
     * focus ring; its track is the bottom 48 logical pixels inside the ring.
     */
    private fun trackPoint(slug: String, along: Double): Pair<Int, Int> {
        // The slider's place on the screen once it has stopped moving. A
        // tap on CI once left the value unchanged; a point worked out while
        // the screen was still arriving would miss the track, which is the
        // likely cause (not confirmed).
        var r = bounds(slider(slug))
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            Thread.sleep(250)
            val next = bounds(slider(slug))
            if (next == r) break
            r = next
        }
        val density = inst.targetContext.resources.displayMetrics.density
        return if (slug.contains("custom") || slug.contains("no-keyboard") || slug.contains("drag-only")) {
            val ring = (8 * density).toInt()
            Pair(r.left + ring + ((r.width() - 2 * ring) * along).toInt(), r.bottom - ring - (24 * density).toInt())
        } else {
            Pair(r.left + (r.width() * along).toInt(), r.centerY())
        }
    }

    // slug -> (description at the start, after one step up, after two steps
    // down from there).
    private val examples = linkedMapOf(
        "good-material" to Triple("40%, Volume", "50%, Volume", "30%, Volume"),
        "good-cupertino" to Triple("40%, Volume", "50%, Volume", "30%, Volume"),
        "good-custom" to Triple("40%, Volume", "50%, Volume", "30%, Volume"),
        "good-value-text" to Triple("4 out of 10, Rating", "5 out of 10, Rating", "3 out of 10, Rating"),
        "bad-unlabelled" to Triple("40%", "50%", "30%"),
        "bad-indicator-label" to Triple("40%, Volume\n4", "50%, Volume\n5", "30%, Volume\n3"),
        "bad-percent-value" to Triple("40%, Rating", "50%, Rating", "30%, Rating"),
        "bad-no-keyboard" to Triple("40%, Volume", "50%, Volume", "30%, Volume"),
        "bad-drag-only" to Triple("40%, Volume", "50%, Volume", "30%, Volume"),
    )

    @Test
    fun everySliderIsASeekBarWithItsValueAndName() {
        for ((slug, descriptions) in examples) {
            val (start, up, down) = descriptions
            open(slug)
            assertEquals(slug, 1, all().count { it.type() == SEEK_BAR })
            val node = slider(slug)
            assertEquals(slug, SEEK_BAR, node.type())
            assertEquals(slug, start, node.name())
            assertTrue(slug, node.isEnabled)
            assertTrue(slug, node.isFocusable)
            // Flutter 3.47.5 gives a SeekBar no RangeInfo; the value is
            // only in the description.
            assertNull(slug, node.rangeInfo)
            assertTrue(slug, node.stateDescription.isNullOrEmpty())
            assertEquals(slug, 0, node.childCount)
            // The bridge puts increasedValue in the description at once
            // (FL-038); an SDK slider and these custom ones compute it from
            // the value, so it is the right one.
            increase(slug)
            // The value is the new one before the rest of the description
            // is (bad-indicator-label read "50%, Volume\n4" once), as only
            // the value is guessed. The tree does not always show it on the
            // very next read (seen on CI for bad-percent-value), so it is
            // waited for, up to two seconds.
            val value = up.substringBefore(",")
            val end = System.currentTimeMillis() + 2_000
            while (System.currentTimeMillis() < end && !slider(slug).name().startsWith(value)) Thread.sleep(50)
            assertTrue("$slug: \"${slider(slug).name()}\" starts with $value", slider(slug).name().startsWith(value))
            waitForCount(slug, 1)
            waitForName(slug, up)
            // Each change is waited for in the app's count: the description
            // shows the guess at once, before the app has acted.
            decrease(slug)
            waitForCount(slug, 2)
            waitForName(slug, start)
            decrease(slug)
            waitForCount(slug, 3)
            waitForName(slug, down)
        }
    }

    @Test
    fun aTapOnTheTrackSetsTheValue() {
        for ((slug, expected) in listOf(
            "good-material" to "100%, Volume",
            "good-custom" to "100%, Volume",
            "good-value-text" to "10 out of 10, Rating",
        )) {
            open(slug)
            val (x, y) = trackPoint(slug, 0.99)
            assertTrue(slug, device.click(x, y))
            waitForName(slug, expected)
            waitForCount(slug, 1)
        }
    }

    @Test
    fun goodCupertinoIgnoresATapOnTheTrackAndHasStepButtons() {
        open("good-cupertino")
        // A CupertinoSlider answers a drag of its thumb only (FL-121).
        val (x, y) = trackPoint("good-cupertino", 0.95)
        device.click(x, y)
        Thread.sleep(1_000)
        assertEquals("40%, Volume", slider("good-cupertino").name())
        assertEquals(0, count("good-cupertino"))
        val up = node("f10-good-cupertino-up")
        val down = node("f10-good-cupertino-down")
        assertEquals(BUTTON, up.type())
        assertEquals("Volume up", up.name())
        assertEquals("Volume down", down.name())
        assertTrue(up.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForName("good-cupertino", "50%, Volume")
        val r = bounds(node("f10-good-cupertino-down"))
        device.click(r.centerX(), r.centerY())
        waitForName("good-cupertino", "40%, Volume")
    }

    // Each bad example is asserted to have its named defect.

    @Test
    fun badUnlabelledHasTheTextAsANodeOfItsOwn() {
        open("bad-unlabelled")
        assertEquals("40%", slider("bad-unlabelled").name())
        assertEquals(1, all().count { it.name() == "Volume" })
        assertFalse(named("Volume").type() == SEEK_BAR)
    }

    @Test
    fun badDragOnlyIgnoresATapAndFollowsADrag() {
        open("bad-drag-only")
        val (x, y) = trackPoint("bad-drag-only", 0.99)
        device.click(x, y)
        Thread.sleep(1_000)
        assertEquals("40%, Volume", slider("bad-drag-only").name())
        assertEquals(0, count("bad-drag-only"))
        val (from, _) = trackPoint("bad-drag-only", 0.4)
        assertTrue(device.swipe(from, y, x, y, 40))
        waitForName("bad-drag-only", "100%, Volume")
    }

    /**
     * L4. Moves TalkBack focus to each slider and logs markers;
     * tool/talkback.py reads the speech from logcat. To read the value after
     * a change, the slider is increased and focused a second time. Skipped
     * unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        // Focus is taken off the slider before it is changed, so that what
        // is logged is what TalkBack reads on arriving, not a change notice.
        fun afterIncrease(slug: String) = Stop("${sliderId(slug)}-changed", {
            node("f10-$slug-count").performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
            Thread.sleep(3_000)
            slider(slug).performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)
            Thread.sleep(2_000)
        }) { slider(slug) }
        fun walk(slug: String) = slug to listOf(Stop(sliderId(slug)) { slider(slug) }, afterIncrease(slug))
        val walk: List<Pair<String, List<Stop>>> = listOf(
            walk("good-material"),
            "good-cupertino" to listOf(
                Stop(sliderId("good-cupertino")) { slider("good-cupertino") },
                Stop("f10-good-cupertino-up") { node("f10-good-cupertino-up") }),
            walk("good-custom"),
            walk("good-value-text"),
            "bad-unlabelled" to listOf(
                Stop("f10-bad-unlabelled-text") { named("Volume") },
                Stop(sliderId("bad-unlabelled")) { slider("bad-unlabelled") }),
            walk("bad-indicator-label"),
            walk("bad-percent-value"),
            "bad-no-keyboard" to listOf(Stop(sliderId("bad-no-keyboard")) { slider("bad-no-keyboard") }),
            "bad-drag-only" to listOf(Stop(sliderId("bad-drag-only")) { slider("bad-drag-only") }),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}
