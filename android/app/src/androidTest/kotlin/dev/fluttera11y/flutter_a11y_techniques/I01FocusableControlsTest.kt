// L3 (tree, keyboard, and pointer) and L4 (TalkBack walk) for I01 Focusable
// and clickable controls on Android.
// Spec: docs/specs/I01-focusable-controls.md.
//
// The keyboard is driven with `input keyevent`, run through the UI
// Automator shell: the emulator has a hardware keyboard, and those events
// reach Flutter's focus system (docs/evidence/probes/i01/README.md). The
// node with Flutter's keyboard focus reports isFocused; isFocusable is true
// for every node with a name or an action, so it says nothing about the
// keyboard and is not asserted.
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val TRAIL = "Ridge trail"
private const val BUTTON = "android.widget.Button"
private const val VIEW = "android.view.View"

private val GOOD = listOf("good-material", "good-cupertino", "good-custom")
private val ALL = GOOD + listOf("bad-inkwell-no-role", "bad-no-focus", "bad-no-key-action", "bad-tap-down")
// Tab reaches these, and Enter and Space activate them.
private val KEYBOARD = GOOD + listOf("bad-inkwell-no-role", "bad-tap-down")
// These act when the pointer is let go over them.
private val ACT_ON_RELEASE = GOOD + listOf("bad-inkwell-no-role", "bad-no-focus", "bad-no-key-action")

@RunWith(AndroidJUnit4::class)
class I01FocusableControlsTest : TechniqueTest("I01") {
    private fun open(slug: String) = openExample(slug, By.res("i01-$slug-count"))

    private fun trail(slug: String): AccessibilityNodeInfo = node("i01-$slug-trail")

    /** Presses a key on the emulator's keyboard and gives Flutter time to act. */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /** The node, other than the window's own, that has keyboard focus; null if none. */
    private fun focused(): AccessibilityNodeInfo? =
        all().firstOrNull { it.isFocused && it.viewIdResourceName != null || it.isFocused && it.name().isNotEmpty() }

    /** Presses Tab until the control of [slug] has keyboard focus, at most [max] times. */
    private fun tabTo(slug: String, max: Int = 6): Boolean {
        for (i in 0 until max) {
            key("TAB")
            if (trail(slug).isFocused) return true
        }
        return false
    }

    private fun centre(slug: String): Pair<Int, Int> {
        val r = Rect().also { trail(slug).getBoundsInScreen(it) }
        return r.centerX() to r.centerY()
    }

    /** Wait a little, then expect the count of [slug] still to be [expected]. */
    private fun expectCountStays(slug: String, expected: Int) {
        Thread.sleep(1_000)
        assertEquals("activation count for $slug", expected, count(slug))
    }

    @Test
    fun everyControlHasItsNameClassAndClickAction() {
        for (slug in ALL) {
            open(slug)
            val node = trail(slug)
            assertEquals(slug, TRAIL, node.name())
            // bad-inkwell-no-role's defect: an InkWell is not a button.
            assertEquals(slug, if (slug == "bad-inkwell-no-role") VIEW else BUTTON, node.type())
            assertTrue(slug, node.isClickable)
            assertTrue(slug, node.hasClickAction())
            assertTrue(slug, node.isEnabled)
            assertFalse(slug, node.isFocused)
            // The name is on the control and on no other node.
            assertEquals(slug, 1, all().count { it.name().contains(TRAIL) })
            // The click action, which TalkBack and Switch Access use.
            assertTrue(slug, node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount(slug, 1)
        }
    }

    @Test
    fun aTapActivatesEveryControlOnce() {
        for (slug in ALL) {
            open(slug)
            val (x, y) = centre(slug)
            assertTrue(slug, device.click(x, y))
            waitForCount(slug, 1)
            expectCountStays(slug, 1)
        }
    }

    @Test
    fun tabReachesTheControlAndEnterAndSpaceEachActivateIt() {
        for (slug in KEYBOARD) {
            open(slug)
            assertTrue("$slug: Tab reaches the control", tabTo(slug))
            key("ENTER")
            waitForCount(slug, 1)
            assertTrue("$slug: focus stays after Enter", trail(slug).isFocused)
            key("SPACE")
            waitForCount(slug, 2)
            assertTrue("$slug: focus stays after Space", trail(slug).isFocused)
        }
    }

    @Test
    fun badNoFocusIsNeverReachedByTab() {
        open("bad-no-focus")
        var other = false
        for (i in 0 until 6) {
            key("TAB")
            assertFalse("Tab ${i + 1} reached the control", trail("bad-no-focus").isFocused)
            // The keys do arrive: Tab puts focus on Back.
            if (focused()?.name() == "Back") other = true
        }
        assertTrue("Tab never focused Back, so the keys may not have arrived", other)
        // Enter and Space are not pressed: focus is on Back.
        assertEquals(0, count("bad-no-focus"))
    }

    /**
     * The control for a key that did nothing: Tab on to Back, in the same
     * launch, and require [name] to act there, which leaves the screen. If
     * the key were not arriving, the screen would stay and this would fail.
     */
    private fun expectKeyActsOnBack(slug: String, name: String) {
        var onBack = false
        for (i in 0 until 3) {
            key("TAB")
            if (focused()?.name() == "Back") { onBack = true; break }
        }
        assertTrue("Tab did not reach Back after the card", onBack)
        key(name)
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && anyWindowHas { it.viewIdResourceName == "i01-$slug-count" }) {
            Thread.sleep(200)
        }
        assertFalse("$name on Back did not leave the screen, so the key may not have arrived",
            anyWindowHas { it.viewIdResourceName == "i01-$slug-count" })
    }

    @Test
    fun badNoKeyActionTakesFocusAndEnterDoesNothing() {
        open("bad-no-key-action")
        assertTrue("Tab reaches the control", tabTo("bad-no-key-action"))
        key("ENTER")
        expectCountStays("bad-no-key-action", 0)
        assertTrue("focus stays after Enter", trail("bad-no-key-action").isFocused)
        expectKeyActsOnBack("bad-no-key-action", "ENTER")
    }

    @Test
    fun badNoKeyActionTakesFocusAndSpaceDoesNothing() {
        open("bad-no-key-action")
        assertTrue("Tab reaches the control", tabTo("bad-no-key-action"))
        key("SPACE")
        expectCountStays("bad-no-key-action", 0)
        assertTrue("focus stays after Space", trail("bad-no-key-action").isFocused)
        expectKeyActsOnBack("bad-no-key-action", "SPACE")
    }

    @Test
    fun aPressThatSlidesOffDoesNothing() {
        for (slug in ACT_ON_RELEASE) {
            open(slug)
            val (x, y) = centre(slug)
            // 100 steps of about 5 ms: half a second from the control to 600
            // pixels below it.
            assertTrue(slug, device.swipe(x, y, x, y + 600, 100))
            expectCountStays(slug, 0)
        }
    }

    @Test
    fun badTapDownActsOnAPressThatSlidesOff() {
        open("bad-tap-down")
        val (x, y) = centre("bad-tap-down")
        assertTrue(device.swipe(x, y, x, y + 600, 100))
        waitForCount("bad-tap-down", 1)
        expectCountStays("bad-tap-down", 1)
    }

    /**
     * L4. Moves TalkBack focus to each control and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running. TalkBack reads every control the same way except
     * bad-inkwell-no-role: the keyboard and pointer defects are not heard.
     */
    @Test
    fun talkBackWalk() {
        val walk: List<Pair<String, List<Stop>>> = ALL.map { slug ->
            slug to listOf(Stop("i01-$slug-trail") { node("i01-$slug-trail") })
        }
        talkBackWalk(walk, open = ::open, dwellMillis = { 5_000 })
    }
}
