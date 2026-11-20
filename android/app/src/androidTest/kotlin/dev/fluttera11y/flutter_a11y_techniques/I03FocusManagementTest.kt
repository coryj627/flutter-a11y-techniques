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
// README.md).
//
// Every read of the screen goes through screen(), which reads the app's own
// window and fails unless that read holds the example or its question. So a
// read that found nothing (no active window, or a system overlay in front)
// can never pass for "no control has focus" or "nothing was asked", and a
// check that nothing was asked uses the same read and the same test for a
// question as the positive control that something was.
//
// The TalkBack walk reads where TalkBack's own focus is
// (AccessibilityNodeInfo.isAccessibilityFocused) after each step, and keeps
// reading after TalkBack has spoken: the step passes only if its focus is
// where it should be for the whole of a last interval, so a move that comes
// later (the framework's own, FL-442) cannot be missed. It logs a marker
// before each step so that tool/talkback.py can credit what TalkBack then
// said to it.
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

// How long the walk listens after TalkBack's focus has first settled. When
// a route closes TalkBack first reads the screen's title, which takes a few
// seconds, and only then the control its focus is on.
private const val SPEECH_MILLIS = 8_000L

// The last interval of each step, in which TalkBack's focus must stay put.
private const val STEADY_MILLIS = 2_000L

@RunWith(AndroidJUnit4::class)
class I03FocusManagementTest : TechniqueTest("I03") {
    override val countName: String get() = "saved count"

    private fun open(slug: String) = openExample(slug, By.res("i03-$slug-count"))

    private fun control(slug: String, part: String): AccessibilityNodeInfo = node("i03-$slug-$part")

    private fun nodesOf(root: AccessibilityNodeInfo?): List<AccessibilityNodeInfo> {
        val out = mutableListOf<AccessibilityNodeInfo>()
        fun visit(n: AccessibilityNodeInfo?) {
            if (n == null) return
            out.add(n)
            for (i in 0 until n.childCount) visit(n.getChild(i))
        }
        visit(root)
        return out
    }

    private fun isQuestion(n: AccessibilityNodeInfo): Boolean =
        n.name().endsWith("?") || n.text?.toString()?.endsWith("?") == true

    private fun questionOf(n: AccessibilityNodeInfo): String = n.name().ifEmpty { n.text?.toString().orEmpty() }

    /**
     * One read of the app's own window: every node, depth first. Of all the
     * windows on the screen, the active one first, it is the one that holds
     * a node of this example (one of its identifiers) or a question. Fails,
     * after five seconds of trying, when none does.
     */
    private fun screen(slug: String): List<AccessibilityNodeInfo> {
        val end = System.currentTimeMillis() + 5_000
        while (true) {
            val roots = listOfNotNull(automation.rootInActiveWindow) + automation.windows.mapNotNull { it.root }
            for (root in roots) {
                val nodes = nodesOf(root)
                if (nodes.any { it.viewIdResourceName?.startsWith("i03-$slug-") == true || isQuestion(it) }) {
                    return nodes
                }
            }
            if (System.currentTimeMillis() > end) throw AssertionError("no window holds the example $slug")
            Thread.sleep(250)
        }
    }

    /** The questions in one read of the screen. */
    private fun questions(nodes: List<AccessibilityNodeInfo>): List<String> =
        nodes.filter(::isQuestion).map(::questionOf)

    /**
     * Fails unless one read of the screen shows the example's list, all
     * three of its buttons, and no question. [context] names the check.
     */
    private fun assertNothingAsked(slug: String, context: String, parts: Collection<String> = NAMES.keys) {
        val nodes = screen(slug)
        val ids = nodes.mapNotNull { it.viewIdResourceName }
        for (part in parts) assertTrue("$context: the read holds $part", "i03-$slug-$part" in ids)
        assertEquals("$context: questions on the screen", emptyList<String>(), questions(nodes))
    }

    /** Waits up to five seconds for a read of the screen to show [question]. */
    private fun waitForQuestion(slug: String, question: String): Boolean {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            if (question in questions(screen(slug))) return true
            Thread.sleep(200)
        }
        return question in questions(screen(slug))
    }

    /** Waits up to five seconds for a read of the screen to show the list and no question. */
    private fun waitForNoQuestion(slug: String): Boolean {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            val nodes = screen(slug)
            if (questions(nodes).isEmpty() && nodes.any { it.viewIdResourceName == "i03-$slug-count" }) return true
            Thread.sleep(200)
        }
        return false
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
     * The control with keyboard focus, from one read of the screen: "back",
     * a part of the example by the last part of its identifier, or "none".
     * Fails if two nodes have it.
     */
    private fun stop(slug: String): String {
        val focused = screen(slug).filter { it.isFocused && (it.viewIdResourceName != null || it.name().isNotEmpty()) }
        if (focused.isEmpty()) return "none"
        assertEquals("nodes with focus: ${focused.map { it.viewIdResourceName ?: it.name() }}", 1, focused.size)
        val node = focused.single()
        if (node.name() == "Back") return "back"
        val id = node.viewIdResourceName.orEmpty()
        return if (id.startsWith("i03-$slug-")) id.removePrefix("i03-$slug-") else "other: $id ${node.name()}"
    }

    /**
     * The stop once it is [expected], or the last one read after three
     * seconds. Focus is reported a little after the screen that holds it:
     * one read straight after a question opens or closes can come too soon.
     */
    private fun stopWhen(slug: String, expected: String): String {
        val end = System.currentTimeMillis() + 3_000
        var last = stop(slug)
        while (last != expected && System.currentTimeMillis() < end) {
            Thread.sleep(200)
            last = stop(slug)
        }
        return last
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

    // 3.2.1. Each Tab alone, and no question in a read that holds the list;
    // then Enter, the positive control, asks, seen through the same read.
    @Test
    fun tabOntoRemoveButtonsAsksNothingAndEnterAsks() {
        for (slug in PRESS_TO_ASK) {
            open(slug)
            assertTrue("$slug: Tab reaches Back", tabTo(slug, "back", 3))
            for (part in listOf("remove-ridge", "remove-lake", "remove-summit")) {
                key("TAB")
                assertEquals(slug, part, stop(slug))
                assertNothingAsked(slug, "$slug: Tab onto $part")
            }
            key("ENTER")
            assertTrue("$slug: Enter asks", waitForQuestion(slug, "Remove Summit path?"))
        }
    }

    // The defect. Written to fail when focus no longer opens the question.
    @Test
    fun badOpensOnFocusAsksWhenTabReachesAButton() {
        val slug = "bad-opens-on-focus"
        open(slug)
        assertTrue("Tab reaches Back", tabTo(slug, "back", 3))
        assertNothingAsked(slug, "Tab onto Back")
        key("TAB")
        assertTrue("Tab onto Remove Ridge trail asks", waitForQuestion(slug, "Remove Ridge trail?"))
        // Cancel goes back to the button, which does not ask again; the next
        // Tab, to the next button, asks about it.
        assertTrue(tabTo(slug, "cancel", 4))
        key("ENTER")
        assertTrue(waitForNoQuestion(slug))
        assertEquals("remove-ridge", stopWhen(slug, "remove-ridge"))
        assertNothingAsked(slug, "focus back on Remove Ridge trail")
        key("TAB")
        assertTrue("Tab onto Remove Lake loop asks", waitForQuestion(slug, "Remove Lake loop?"))
    }

    @Test
    fun enterPutsFocusInTheQuestion() {
        for ((slug, stops) in OPENS) {
            openAtLake(slug)
            key("ENTER")
            assertTrue("$slug: the question opens", waitForQuestion(slug, "Remove Lake loop?"))
            assertEquals(slug, stops.first, stopWhen(slug, stops.first))
            // Where the question takes no focus there is nothing to wait
            // for, and on CI the Tab was pressed while the question was
            // still coming in and no stop followed it (run 44737768811).
            // The Tab is pressed once; only the read after it waits.
            device.waitForIdle()
            Thread.sleep(1_000)
            key("TAB")
            assertEquals(slug, stops.second, stopWhen(slug, stops.second))
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
        assertTrue("the question opens", waitForQuestion(slug, "Remove Lake loop?"))
        assertEquals("none", stop(slug))
        key("TAB")
        assertEquals("no control of the question has focus", "none", stop(slug))
        key("ENTER")
        assertTrue("Enter asks about Summit path: focus was on its button",
            waitForQuestion(slug, "Remove Summit path?"))
    }

    @Test
    fun badFocusLeftBehindReachesTheQuestionLast() {
        val slug = "bad-focus-left-behind"
        openAtLake(slug)
        key("ENTER")
        assertTrue(waitForQuestion(slug, "Remove Lake loop?"))
        // Remove Summit path, behind the question and out of the tree, then
        // Cancel.
        assertEquals(listOf("none", "cancel"), walk(slug, 2) { key("TAB") })
    }

    @Test
    fun cancelPutsFocusBackOnTheButton() {
        for (slug in GOOD) {
            openAtLake(slug)
            key("ENTER")
            assertTrue(waitForQuestion(slug, "Remove Lake loop?"))
            assertTrue("$slug: Tab reaches Cancel", tabTo(slug, "cancel", 4))
            key("ENTER")
            assertTrue(waitForNoQuestion(slug))
            assertEquals(slug, "remove-lake", stopWhen(slug, "remove-lake"))
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
        assertTrue(waitForQuestion(slug, "Remove Lake loop?"))
        assertTrue("Tab reaches Cancel", tabTo(slug, "cancel", 4))
        key("ENTER")
        assertTrue(waitForNoQuestion(slug))
        assertEquals("none", stop(slug))
        assertEquals(listOf("back"), walk(slug, 1) { key("TAB") })
    }

    @Test
    fun removePutsFocusOnTheNextButton() {
        for (slug in GOOD) {
            openAtLake(slug)
            key("ENTER")
            assertTrue(waitForQuestion(slug, "Remove Lake loop?"))
            assertTrue("$slug: Tab reaches Remove", tabTo(slug, "confirm", 4))
            key("ENTER")
            waitForCount(slug, 2)
            assertEquals(slug, "remove-summit", stopWhen(slug, "remove-summit"))
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

    /** Where TalkBack's focus was, in order and without repeats, over the next [ms]. */
    private fun talkBackOver(ms: Long): List<String> {
        val seen = mutableListOf<String>()
        val end = System.currentTimeMillis() + ms
        while (System.currentTimeMillis() < end) {
            val now = talkBackOn()
            if (seen.lastOrNull() != now) seen.add(now)
            Thread.sleep(200)
        }
        return seen
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
     * Remove. After each, the test waits for TalkBack's own focus to get
     * where it should, listens while TalkBack speaks, and then requires its
     * focus to stay there for the last interval. On Android the examples
     * only move keyboard focus after a removal, and TalkBack follows it. In
     * good-material the test then removes Ridge trail and about 400 ms later moves
     * keyboard focus on to Back: TalkBack must follow it, and not be pulled
     * back to Remove Summit path. In bad-opens-on-focus
     * TalkBack's focus on Remove Ridge trail asks nothing, and the click
     * action on it then asks, seen through the same read of the screen.
     * Every failure is collected, and the test fails at the end with all of
     * them.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        val failures = mutableListOf<String>()
        fun check(ok: Boolean, message: String) { if (!ok) failures += message }

        /** The last interval of a step: TalkBack's focus must stay where [ok] accepts. */
        fun steady(slug: String, step: String, ok: (String) -> Boolean): String {
            Thread.sleep(SPEECH_MILLIS)
            val seen = talkBackOver(STEADY_MILLIS)
            check(seen.size == 1 && ok(seen.single()), "$slug: $step: TalkBack's focus over the last interval: $seen")
            return seen.joinToString(" > ")
        }

        for (slug in PRESS_TO_ASK) {
            openExampleInAnyWindow(slug) { it.viewIdResourceName == "i03-$slug-count" }
            if (slug == "good-material") {
                // One key now, so that the key sent later in this example is
                // not the one lost to touch mode.
                key("TAB")
            }
            Thread.sleep(8_000)
            activate("i03-$slug-remove-lake", "i03-$slug-opened")
            val opened = talkBackSettlesOn(5_000) { inQuestion(slug, it) }
            check(inQuestion(slug, opened), "$slug: opened: TalkBack went to $opened")
            val openedLast = steady(slug, "opened") { inQuestion(slug, it) }
            Log.i(talkBackTag, "END $slug-opened")
            activate("i03-$slug-cancel", "i03-$slug-cancelled")
            val cancelled = talkBackSettlesOn(6_000) { it == "i03-$slug-remove-lake" }
            check(cancelled == "i03-$slug-remove-lake", "$slug: cancelled: TalkBack went to $cancelled")
            val cancelledLast = steady(slug, "cancelled") { it == "i03-$slug-remove-lake" }
            Log.i(talkBackTag, "END $slug-cancelled")
            activate("i03-$slug-remove-lake")
            Thread.sleep(3_000)
            activate("i03-$slug-confirm", "i03-$slug-removed")
            val removed = talkBackSettlesOn(8_000) { it == "i03-$slug-remove-summit" }
            check(removed == "i03-$slug-remove-summit", "$slug: removed: TalkBack went to $removed")
            val removedLast = steady(slug, "removed") { it == "i03-$slug-remove-summit" }
            Log.i(talkBackTag, "END $slug")
            Log.i("I03FOCUS", "$slug | opened: $opened, then $openedLast | cancelled: $cancelled, then $cancelledLast" +
                " | removed: $removed, then $removedLast")

            if (slug == "good-material") {
                // Ridge trail and Summit path are left. Removing Ridge trail
                // puts keyboard focus on Summit path, and the examples send
                // nothing more on Android. About 400 ms after the question's
                // Remove, Shift+Tab moves keyboard focus to Back: TalkBack
                // follows it there, and nothing may pull it back to Summit
                // path. Its focus must be on Back itself for the last
                // interval: lost focus ("none"), or focus anywhere else,
                // fails.
                activate("i03-$slug-remove-ridge")
                Thread.sleep(3_000)
                activate("i03-$slug-confirm", "i03-$slug-moved-on")
                Thread.sleep(400)
                shiftTab()
                val keyboard = stop(slug)
                check(keyboard == "back", "$slug: moved on: Shift+Tab put keyboard focus on $keyboard, not Back")
                val movedOn = steady(slug, "moved on") { it == "Back" }
                Log.i(talkBackTag, "END $slug-moved-on")
                Log.i("I03FOCUS", "$slug | moved on: keyboard $keyboard, TalkBack $movedOn")
            }
        }

        val slug = "bad-opens-on-focus"
        val ridge = "i03-$slug-remove-ridge"
        openExampleInAnyWindow(slug) { it.viewIdResourceName == "i03-$slug-count" }
        Thread.sleep(8_000)
        assertNothingAsked(slug, "before TalkBack's move")
        Log.i(talkBackTag, "FOCUS $ridge")
        talkBackFocus(ridge) { nodeInAnyWindow(ridge) }
        Thread.sleep(4_000)
        Log.i(talkBackTag, "END $slug")
        check(talkBackOn() == ridge, "$slug: TalkBack's focus is on ${talkBackOn()}, not Remove Ridge trail")
        try {
            assertNothingAsked(slug, "TalkBack's focus on Remove Ridge trail")
        } catch (e: AssertionError) {
            failures += "$slug: ${e.message}"
            // Close what was asked, so that the positive control below
            // starts from the list.
            nodeInAnyWindow("i03-$slug-cancel").performAction(AccessibilityNodeInfo.ACTION_CLICK)
            waitForNoQuestion(slug)
        }
        // The positive control, through the same read and the same test: the
        // click action, as a double tap, asks.
        assertTrue("click Remove Ridge trail", nodeInAnyWindow(ridge).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        check(waitForQuestion(slug, "Remove Ridge trail?"), "$slug: the click on Remove Ridge trail did not ask")

        assertTrue(failures.joinToString("\n"), failures.isEmpty())
    }
}
