// L3 (tree and keyboard) and L4 (TalkBack) for I03 Focus management on
// Android.
// Spec: docs/specs/I03-focus-management.md.
//
// Every keyboard stop is named: after each key the test names the one node
// that reports isFocused, which follows Flutter's keyboard focus
// (docs/evidence/probes/i01/README.md). A stop that is not in the tree,
// because it is behind the question, is named by what Enter does there.
// Tab and Enter are sent with `input keyevent`; Shift+Tab as four key
// events through Instrumentation.sendKeySync (docs/evidence/probes/i02/
// README.md). The TalkBack walk reads where TalkBack's own focus is
// (AccessibilityNodeInfo.isAccessibilityFocused) after each step, and logs
// a marker before the step so that tool/talkback.py can credit what
// TalkBack then said to it.
package dev.fluttera11y.flutter_a11y_techniques

import android.os.SystemClock
import android.util.Log
import android.view.InputDevice
import android.view.KeyCharacterMap
import android.view.KeyEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"

private val GOOD = listOf("good-material", "good-cupertino", "good-widgets")
private val ALL = GOOD + listOf("bad-focus-left-behind", "bad-opens-on-focus")

// The examples whose question is opened by pressing a Remove button.
private val PRESS_TO_ASK = GOOD + "bad-focus-left-behind"
private val NAMES = mapOf(
    "remove-ridge" to "Remove Ridge trail",
    "remove-lake" to "Remove Lake loop",
    "remove-summit" to "Remove Summit path",
)

// Enter on Remove Lake loop: the stop it leaves focus on ("none" while it
// is on the question's own scope, which has no node), and the next Tab's.
private val OPENS = mapOf(
    "good-material" to ("none" to "cancel"),
    "good-cupertino" to ("none" to "confirm"),
    "good-widgets" to ("cancel" to "confirm"),
)

@RunWith(AndroidJUnit4::class)
class I03FocusManagementTest : TechniqueTest("I03") {
    override val countName: String get() = "saved count"

    private fun open(slug: String) = openExample(slug, By.res("i03-$slug-count"))

    private fun control(slug: String, part: String): AccessibilityNodeInfo = node("i03-$slug-$part")

    /** Whether a node named [name] is on the screen. */
    private fun shows(name: String): Boolean = all().any { it.name() == name || it.text?.toString() == name }

    /** Waits up to five seconds for a node named [name] to be there, or gone. */
    private fun waitFor(name: String, there: Boolean = true): Boolean {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            if (shows(name) == there) return true
            Thread.sleep(200)
        }
        return shows(name) == there
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act. */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(700)
    }

    private fun shiftTab() {
        val t = SystemClock.uptimeMillis()
        val shift = KeyEvent.META_SHIFT_ON or KeyEvent.META_SHIFT_LEFT_ON
        fun event(time: Long, action: Int, code: Int, meta: Int) = KeyEvent(
            time, time, action, code, 0, meta, KeyCharacterMap.VIRTUAL_KEYBOARD, 0, 0,
            InputDevice.SOURCE_KEYBOARD)
        inst.sendKeySync(event(t, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_SHIFT_LEFT, shift))
        inst.sendKeySync(event(t + 10, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_TAB, shift))
        inst.sendKeySync(event(t + 20, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_TAB, shift))
        inst.sendKeySync(event(t + 30, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_SHIFT_LEFT, 0))
        Thread.sleep(700)
    }

    /**
     * The control with keyboard focus: "back", a part of the example by the
     * last part of its identifier, or "none". Fails if two nodes have it.
     */
    private fun stop(slug: String): String {
        val focused = all().filter { it.isFocused && (it.viewIdResourceName != null || it.name().isNotEmpty()) }
        if (focused.isEmpty()) return "none"
        assertEquals("nodes with focus: ${focused.map { it.viewIdResourceName ?: it.name() }}", 1, focused.size)
        val node = focused.single()
        if (node.name() == "Back") return "back"
        val id = node.viewIdResourceName.orEmpty()
        return if (id.startsWith("i03-$slug-")) id.removePrefix("i03-$slug-") else "other: $id ${node.name()}"
    }

    /**
     * Presses Tab until [part] has focus, at most [max] times. The first Tab
     * after the app opens is lost (docs/evidence/probes/i01/README.md), so
     * this allows for one more than the order needs.
     */
    private fun tabTo(slug: String, part: String, max: Int = 6): Boolean {
        for (i in 0 until max) {
            if (stop(slug) == part) return true
            key("TAB")
        }
        return stop(slug) == part
    }

    private fun walk(slug: String, n: Int, press: () -> Unit): List<String> =
        (0 until n).map { press(); stop(slug) }

    /** Opens [slug] and tabs to Back, then on to Remove Lake loop, naming each stop. */
    private fun openAtLake(slug: String) {
        open(slug)
        assertTrue("$slug: Tab reaches Back", tabTo(slug, "back", 3))
        assertEquals(slug, listOf("remove-ridge", "remove-lake"), walk(slug, 2) { key("TAB") })
    }

    @Test
    fun everyExampleHasItsButtonsAndCount() {
        for (slug in ALL) {
            open(slug)
            for ((part, name) in NAMES) {
                val node = control(slug, part)
                assertEquals("$slug $part", name, node.name())
                assertEquals("$slug $part", BUTTON, node.type())
                assertTrue("$slug $part", node.hasClickAction())
                assertFalse("$slug $part", node.isFocused)
            }
            assertEquals(slug, 3, count(slug))
        }
    }

    // 3.2.1. Each Tab alone, and no question; then Enter, the positive
    // control, asks.
    @Test
    fun tabOntoRemoveButtonsAsksNothingAndEnterAsks() {
        for (slug in PRESS_TO_ASK) {
            open(slug)
            assertTrue("$slug: Tab reaches Back", tabTo(slug, "back", 3))
            for (part in listOf("remove-ridge", "remove-lake", "remove-summit")) {
                key("TAB")
                assertEquals(slug, part, stop(slug))
                assertFalse("$slug: Tab onto $part asked", all().any { it.name().endsWith("?") })
            }
            key("ENTER")
            assertTrue("$slug: Enter asks", waitFor("Remove Summit path?"))
        }
    }

    // The defect. Written to fail when focus no longer opens the question.
    @Test
    fun badOpensOnFocusAsksWhenTabReachesAButton() {
        val slug = "bad-opens-on-focus"
        open(slug)
        assertTrue("Tab reaches Back", tabTo(slug, "back", 3))
        assertFalse("Tab onto Back asked", all().any { it.name().endsWith("?") })
        key("TAB")
        assertTrue("Tab onto Remove Ridge trail asks", waitFor("Remove Ridge trail?"))
        // Cancel goes back to the button, which does not ask again; the next
        // Tab, to the next button, asks about it.
        assertTrue(tabTo(slug, "cancel", 4))
        key("ENTER")
        assertTrue(waitFor("Remove Ridge trail?", there = false))
        assertEquals("remove-ridge", stop(slug))
        key("TAB")
        assertTrue("Tab onto Remove Lake loop asks", waitFor("Remove Lake loop?"))
    }

    @Test
    fun enterPutsFocusInTheQuestion() {
        for ((slug, stops) in OPENS) {
            openAtLake(slug)
            key("ENTER")
            assertTrue("$slug: the question opens", waitFor("Remove Lake loop?"))
            assertEquals(slug, stops.first, stop(slug))
            assertEquals(slug, listOf(stops.second), walk(slug, 1) { key("TAB") })
        }
    }

    // The defect. The Remove buttons are out of the tree while the question
    // is up, so the first Tab's stop is named by what Enter does there: it
    // asks about Summit path. Written to fail when the question starts to
    // take focus.
    @Test
    fun badFocusLeftBehindTabGoesBehindTheQuestion() {
        val slug = "bad-focus-left-behind"
        openAtLake(slug)
        key("ENTER")
        assertTrue("the question opens", waitFor("Remove Lake loop?"))
        assertEquals("none", stop(slug))
        key("TAB")
        assertEquals("no control of the question has focus", "none", stop(slug))
        key("ENTER")
        assertTrue("Enter asks about Summit path: focus was on its button", waitFor("Remove Summit path?"))
    }

    @Test
    fun badFocusLeftBehindReachesTheQuestionLast() {
        val slug = "bad-focus-left-behind"
        openAtLake(slug)
        key("ENTER")
        assertTrue(waitFor("Remove Lake loop?"))
        // Remove Summit path, behind the question and out of the tree, then
        // Cancel.
        assertEquals(listOf("none", "cancel"), walk(slug, 2) { key("TAB") })
    }

    @Test
    fun cancelPutsFocusBackOnTheButton() {
        for (slug in GOOD) {
            openAtLake(slug)
            key("ENTER")
            assertTrue(waitFor("Remove Lake loop?"))
            assertTrue("$slug: Tab reaches Cancel", tabTo(slug, "cancel", 4))
            key("ENTER")
            assertTrue(waitFor("Remove Lake loop?", there = false))
            assertEquals(slug, "remove-lake", stop(slug))
            assertEquals(slug, listOf("remove-summit"), walk(slug, 1) { key("TAB") })
        }
    }

    // The same defect on the way out. Written to fail when focus comes back
    // to Remove Lake loop.
    @Test
    fun badFocusLeftBehindCancelLeavesFocusOnNoControl() {
        val slug = "bad-focus-left-behind"
        openAtLake(slug)
        key("ENTER")
        assertTrue(waitFor("Remove Lake loop?"))
        assertTrue("Tab reaches Cancel", tabTo(slug, "cancel", 4))
        key("ENTER")
        assertTrue(waitFor("Remove Lake loop?", there = false))
        assertEquals("none", stop(slug))
        assertEquals(listOf("back"), walk(slug, 1) { key("TAB") })
    }

    @Test
    fun removePutsFocusOnTheNextButton() {
        for (slug in GOOD) {
            openAtLake(slug)
            key("ENTER")
            assertTrue(waitFor("Remove Lake loop?"))
            assertTrue("$slug: Tab reaches Remove", tabTo(slug, "confirm", 4))
            key("ENTER")
            waitForCount(slug, 2)
            assertEquals(slug, "remove-summit", stop(slug))
            assertEquals(slug, listOf("remove-ridge"), walk(slug, 1) { shiftTab() })
        }
    }

    /** TalkBack's focus: the identifier or name of the node that has it, or "none". */
    private fun talkBackOn(): String {
        val n = automation.findFocus(AccessibilityNodeInfo.FOCUS_ACCESSIBILITY) ?: return "none"
        // A node with no test identifier reports an empty one, not none.
        return n.viewIdResourceName?.ifEmpty { null }
            ?: n.name().ifEmpty { n.text?.toString().orEmpty() }.ifEmpty { "(${n.type()})" }
    }

    /**
     * Whether [where], as [talkBackOn] gives it, is in the question about
     * Lake loop: its title, its message, or one of its buttons. The title
     * and message can be read as one node, or as two.
     */
    private fun inQuestion(slug: String, where: String): Boolean =
        where.startsWith("Remove Lake loop?") || where.startsWith("It goes from your saved trails") ||
            where == "i03-$slug-cancel" || where == "i03-$slug-confirm"

    /** Waits up to [ms] for TalkBack's focus to satisfy [ok]; returns where it is. */
    private fun talkBackSettlesOn(ms: Long, ok: (String) -> Boolean): String {
        val end = System.currentTimeMillis() + ms
        var now = talkBackOn()
        while (!ok(now) && System.currentTimeMillis() < end) {
            Thread.sleep(250)
            now = talkBackOn()
        }
        return now
    }

    /**
     * Puts TalkBack's focus on [id], lets it read the control, then logs
     * [marker] (when given) and activates the control, as a double tap
     * does. What TalkBack says after the marker is what it read where its
     * focus went next.
     */
    private fun activate(id: String, marker: String? = null) {
        talkBackFocus(id) { nodeInAnyWindow(id) }
        Thread.sleep(2_500)
        if (marker != null) Log.i(talkBackTag, "FOCUS $marker")
        assertTrue("click $id", nodeInAnyWindow(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
    }

    /**
     * L4. Skips unless TalkBack is running. In each example TalkBack
     * activates Remove Lake loop, then Cancel, then Remove Lake loop and
     * Remove; after each, the test reads where TalkBack's own focus went
     * and logs a marker, so that tool/talkback.py credits what TalkBack
     * said then to that step. In bad-opens-on-focus TalkBack's focus is
     * moved onto Remove Ridge trail, which asks nothing: TalkBack's focus is
     * not keyboard focus.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        for (slug in PRESS_TO_ASK) {
            openExampleInAnyWindow(slug) { it.viewIdResourceName == "i03-$slug-count" }
            Thread.sleep(8_000)
            activate("i03-$slug-remove-lake", "i03-$slug-opened")
            val opened = talkBackSettlesOn(5_000) { inQuestion(slug, it) }
            Thread.sleep(2_000)
            Log.i(talkBackTag, "END $slug-opened")
            activate("i03-$slug-cancel", "i03-$slug-cancelled")
            val cancelled = talkBackSettlesOn(6_000) { it == "i03-$slug-remove-lake" }
            Thread.sleep(2_000)
            Log.i(talkBackTag, "END $slug-cancelled")
            activate("i03-$slug-remove-lake")
            Thread.sleep(3_000)
            activate("i03-$slug-confirm", "i03-$slug-removed")
            val removed = talkBackSettlesOn(8_000) { it == "i03-$slug-remove-summit" }
            Thread.sleep(2_000)
            Log.i(talkBackTag, "END $slug")
            Log.i("I03FOCUS", "$slug | opened: $opened | cancelled: $cancelled | removed: $removed")
            assertTrue("$slug: TalkBack went into the question, to $opened",
                inQuestion(slug, opened))
            assertEquals("$slug: after Cancel", "i03-$slug-remove-lake", cancelled)
            assertEquals("$slug: after Remove", "i03-$slug-remove-summit", removed)
        }
        val slug = "bad-opens-on-focus"
        openExampleInAnyWindow(slug) { it.viewIdResourceName == "i03-$slug-count" }
        Thread.sleep(8_000)
        Log.i(talkBackTag, "FOCUS i03-$slug-remove-ridge")
        talkBackFocus("i03-$slug-remove-ridge") { nodeInAnyWindow("i03-$slug-remove-ridge") }
        Thread.sleep(4_000)
        Log.i(talkBackTag, "END $slug")
        assertFalse("TalkBack's focus on Remove Ridge trail asked", all().any { it.name().endsWith("?") })
        assertNotNull(nodeInAnyWindow("i03-$slug-remove-lake"))
    }
}
