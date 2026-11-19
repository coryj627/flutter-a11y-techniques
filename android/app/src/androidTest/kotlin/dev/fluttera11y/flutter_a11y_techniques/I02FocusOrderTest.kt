// L3 (tree and keyboard) and L4 (TalkBack walk) for I02 Keyboard focus
// order on Android.
// Spec: docs/specs/I02-focus-order.md.
//
// Every order is read stop by stop: after each key the test names the one
// node that reports isFocused, which follows Flutter's keyboard focus
// (docs/evidence/probes/i01/README.md). Tab, the arrows, and Space are sent
// with `input keyevent`. Shift+Tab is sent as four key events through
// Instrumentation.sendKeySync: Shift down, Tab down and up with the Shift
// meta state, then Shift up. A Tab with the Shift meta state and no Shift
// key event of its own arrives at Flutter as a plain Tab
// (docs/evidence/probes/i02/README.md).
package dev.fluttera11y.flutter_a11y_techniques

import android.os.SystemClock
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

private const val CHECKBOX = "android.widget.CheckBox"
private const val BUTTON = "android.widget.Button"

private val GOOD = listOf("good-material", "good-cupertino", "good-ordered")
private val ALL = GOOD + listOf("bad-columns-mixed", "bad-order-missing")
private val BOXES = listOf("map", "water", "aid", "weather", "closures")
private val NAMES = mapOf(
    "map" to "Map", "water" to "Water", "aid" to "First aid",
    "weather" to "Weather", "closures" to "Closures", "save" to "Save plan",
)
private val COLUMN_ORDER = listOf("map", "water", "aid", "weather", "closures", "save")

// Tab, from Back, in each example. The same orders as in the widget tests.
private val TAB_ORDER = mapOf(
    "good-material" to listOf("back") + COLUMN_ORDER,
    "good-cupertino" to listOf("back") + COLUMN_ORDER,
    "good-ordered" to listOf("back") + COLUMN_ORDER,
    "bad-columns-mixed" to listOf("back", "map", "weather", "water", "closures", "aid", "save"),
    "bad-order-missing" to listOf("back", "map", "water", "weather", "closures", "save", "aid"),
)

@RunWith(AndroidJUnit4::class)
class I02FocusOrderTest : TechniqueTest("I02") {
    override val countName: String get() = "save count"

    // CI's emulator is 320 by 640 at 160 dpi. There the example screens
    // scroll, and a node scrolled out of view is not in the tree that UI
    // Automator reads: the count of bad-columns-mixed, below its longer
    // defect text, was missing when the screen opened (measured with
    // `wm size 320x640` and `wm density 160` on the local emulator). So the
    // test waits for Map, near the top of every example, and finds a node
    // that may be out of view by scrolling to it.
    private fun open(slug: String) = openExample(slug, By.res("i02-$slug-map"))

    private fun find(id: String): AccessibilityNodeInfo? = all().firstOrNull { it.viewIdResourceName == id }

    private fun scrollView(): AccessibilityNodeInfo? = all().firstOrNull { it.isScrollable }

    private fun scroll(action: Int): Boolean {
        val moved = scrollView()?.performAction(action) ?: false
        if (moved) Thread.sleep(500)
        return moved
    }

    /**
     * The node with the test identifier [id], scrolling the screen to it if
     * it is out of view: forward first, then back. Scrolling moves no
     * keyboard focus.
     */
    private fun reveal(id: String): AccessibilityNodeInfo {
        find(id)?.let { return it }
        for (action in listOf(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD, AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD)) {
            for (i in 0 until 8) {
                if (!scroll(action)) break
                find(id)?.let { return it }
            }
        }
        throw AssertionError("no node with id $id, even after scrolling")
    }

    private fun control(slug: String, c: String): AccessibilityNodeInfo = reveal("i02-$slug-$c")

    private fun saves(slug: String): Int = control(slug, "count").name().substringAfter(": ").toInt()

    /** Waits up to 5 seconds for the save count of [slug] to be [expected]. */
    private fun waitForSaves(slug: String, expected: Int) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && saves(slug) != expected) Thread.sleep(200)
        assertEquals("save count for $slug", expected, saves(slug))
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act. */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
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
        Thread.sleep(600)
    }

    /**
     * The control with keyboard focus: "back", a control of the example by
     * the last part of its identifier, or "none". Fails if two nodes have it.
     */
    private fun stop(slug: String): String {
        val focused = all().filter { it.isFocused && (it.viewIdResourceName != null || it.name().isNotEmpty()) }
        if (focused.isEmpty()) return "none"
        assertEquals("nodes with focus: ${focused.map { it.viewIdResourceName ?: it.name() }}", 1, focused.size)
        val node = focused.single()
        if (node.name() == "Back") return "back"
        val id = node.viewIdResourceName.orEmpty()
        return if (id.startsWith("i02-$slug-")) id.removePrefix("i02-$slug-") else "other: $id ${node.name()}"
    }

    /**
     * Presses Tab until [c] has focus, at most [max] times. The first Tab
     * after the app opens is lost (docs/evidence/probes/i01/README.md), so
     * this allows for one more than the order needs.
     */
    private fun tabTo(slug: String, c: String, max: Int = 9): Boolean {
        for (i in 0 until max) {
            key("TAB")
            if (stop(slug) == c) return true
        }
        return false
    }

    private fun walk(slug: String, n: Int, press: () -> Unit): List<String> =
        (0 until n).map { press(); stop(slug) }

    @Test
    fun everyControlHasItsNameAndClass() {
        for (slug in ALL) {
            open(slug)
            for (box in BOXES) {
                val node = control(slug, box)
                assertEquals("$slug $box", NAMES[box], node.name())
                assertEquals("$slug $box", CHECKBOX, node.type())
                assertTrue("$slug $box", node.isCheckable)
                assertFalse("$slug $box", node.isChecked)
                assertFalse("$slug $box", node.isFocused)
            }
            val save = control(slug, "save")
            assertEquals(slug, "Save plan", save.name())
            assertEquals(slug, BUTTON, save.type())
            assertFalse(slug, save.isFocused)
        }
    }

    // The order of the nodes in the tree is the order the framework gives
    // for screen readers to follow: the engine adds a node's children in
    // their traversal order (read in the source: AccessibilityBridge.java).
    // It is the column order in every example. TalkBack's own moves are not
    // driven here: the TalkBack walk below puts its focus on each control.
    // On a screen where the example scrolls, the tree holds only the nodes
    // in view, so the order is read at each scroll position, from the top:
    // every reading must be in the column order, and together they must
    // hold every control.
    @Test
    fun theTreeHasTheControlsOneColumnThenTheOther() {
        for (slug in ALL) {
            open(slug)
            while (scroll(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD)) { /* to the top */ }
            val seen = mutableSetOf<String>()
            for (i in 0 until 8) {
                val order = all().mapNotNull { it.viewIdResourceName }
                    .filter { it.startsWith("i02-$slug-") && !it.endsWith("-count") }
                    .map { it.removePrefix("i02-$slug-") }
                assertEquals("$slug, at scroll step $i", COLUMN_ORDER.filter { it in order }, order)
                seen += order
                if (!scroll(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) break
            }
            assertEquals(slug, COLUMN_ORDER.toSet(), seen)
        }
    }

    @Test
    fun tabGoesInTheExamplesOrderThenRoundToBack() {
        for (slug in ALL) {
            val order = TAB_ORDER.getValue(slug)
            open(slug)
            assertTrue("$slug: Tab reaches Back", tabTo(slug, "back", 3))
            assertEquals(slug, order.drop(1) + "back", walk(slug, order.size) { key("TAB") })
        }
    }

    @Test
    fun shiftTabGoesTheSameWayBackwards() {
        for (slug in ALL) {
            val order = TAB_ORDER.getValue(slug)
            open(slug)
            assertTrue("$slug: Tab reaches ${order.last()}", tabTo(slug, order.last()))
            val back = order.reversed().drop(1)
            assertEquals(slug, back + order.last(), walk(slug, back.size + 1) { shiftTab() })
        }
    }

    @Test
    fun spaceChangesTheBoxThatHasFocus() {
        for (slug in ALL) {
            val order = TAB_ORDER.getValue(slug)
            open(slug)
            assertTrue("$slug: Tab reaches Back", tabTo(slug, "back", 3))
            val done = mutableListOf<String>()
            for (expected in order.drop(1)) {
                key("TAB")
                assertEquals(slug, expected, stop(slug))
                key("SPACE")
                if (expected == "save") {
                    waitForSaves(slug, 1)
                    continue
                }
                done += expected
                for (box in BOXES) {
                    assertEquals("$slug: after Space on $expected, $box", box in done, control(slug, box).isChecked)
                }
            }
        }
    }

    @Test
    fun eachArrowMovesToTheControlOnThatSide() {
        val moves = listOf(
            Triple("map", "DPAD_DOWN", "water"), Triple("water", "DPAD_UP", "map"),
            Triple("map", "DPAD_RIGHT", "weather"), Triple("weather", "DPAD_LEFT", "map"),
            Triple("weather", "DPAD_DOWN", "closures"), Triple("aid", "DPAD_DOWN", "save"),
        )
        for (slug in ALL) {
            open(slug)
            for ((from, arrow, to) in moves) {
                assertTrue("$slug: Tab reaches $from", tabTo(slug, from))
                key(arrow)
                assertEquals("$slug: $from $arrow", to, stop(slug))
            }
        }
    }

    /**
     * L4. Moves TalkBack focus to each control and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless
     * TalkBack is running. This records what is said at each control, not
     * the order: the walk puts TalkBack's focus on each in turn.
     */
    @Test
    fun talkBackWalk() {
        val walk: List<Pair<String, List<Stop>>> = ALL.map { slug ->
            slug to (BOXES + "save").map { c -> Stop("i02-$slug-$c") { reveal("i02-$slug-$c") } }
        }
        talkBackWalk(walk, open = ::open, dwellMillis = { 3_000 })
    }
}
