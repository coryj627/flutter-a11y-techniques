// L3 (tree) and L4 (TalkBack walk) for C06 Disclosure on Android.
// Spec: docs/specs/C06-disclosure.md.
//
// No example has a test identifier (TestId's MergeSemantics would take the
// open panel into the control), so the control is the clickable node whose
// name starts with its title. None of these widgets gives an expanded
// state (FL-264, FL-265, FL-267): where the tests read the expanded state, on
// Android 16 and later, they expect "undefined", so that they fail when
// Flutter starts to give one. Each test opens one example once.
package dev.fluttera11y.flutter_a11y_techniques

import android.os.Build
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

private const val BUTTON = "android.widget.Button"
private const val VIEW = "android.view.View"
private const val TITLE = "Details"
private const val PANEL_TEXT = "Orders ship in two days."
private const val PANEL_ACTION = "Change address"

@RunWith(AndroidJUnit4::class)
class C06DisclosureTest : TechniqueTest("C06") {
    override val countName: String get() = "press count"

    /**
     * Opens [slug] and scrolls its screen to the end, as a person scrolls
     * down to the example: on CI's 320 by 640 emulator the lines above it
     * can push it down. On a screen that does not scroll nothing moves.
     */
    private fun open(slug: String) {
        openExample(slug, By.desc(c06Titles.getValue(slug)), settleMillis = 300)
        scrollToEnd()
    }

    /** The control: the clickable node whose name starts with the title. */
    private fun control(): AccessibilityNodeInfo =
        all().firstOrNull { it.isClickable && it.name().startsWith(TITLE) }
            ?: throw AssertionError("no control named $TITLE: ${all().map { it.name() }}")

    /** The expanded state on Android 16 and later ("undefined" when there is none); null before. */
    private fun expandedState(node: AccessibilityNodeInfo): String? {
        if (Build.VERSION.SDK_INT < 36) return null
        return when (node.javaClass.getMethod("getExpandedState").invoke(node) as Int) {
            0 -> "undefined"
            1 -> "collapsed"
            2 -> "partial"
            3 -> "full"
            else -> "other"
        }
    }

    /** What the expanded state must be: no state ("undefined") on Android 16 and later, null before. */
    private val noState: String? get() = if (Build.VERSION.SDK_INT >= 36) "undefined" else null

    private fun hasAction(node: AccessibilityNodeInfo, action: Int) = node.actionList.any { it.id == action }

    /** The label of the node's click action, "" if it has none. */
    private fun clickLabel(node: AccessibilityNodeInfo): String =
        node.actionList.firstOrNull { it.id == AccessibilityNodeInfo.ACTION_CLICK }?.label?.toString().orEmpty()

    /** Whether any node shows [text], in its name or its text. */
    private fun shown(text: String) = anyWindowHas { it.name().contains(text) || it.text?.contains(text) == true }

    /** Waits up to 5 seconds for [condition]. */
    private fun waitFor(what: String, condition: () -> Boolean) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !condition()) Thread.sleep(100)
        assertTrue(what, condition())
    }

    /** The names of the example's nodes in tree order, from the control to the count, the count left out. */
    private fun reading(): List<String> {
        scrollToEnd()
        val names = all().map { it.name().ifEmpty { it.text?.toString().orEmpty() } }.filter { it.isNotEmpty() }
        val start = names.indexOfFirst { it.startsWith(TITLE) }
        val end = names.indexOfFirst { it.startsWith("Presses: ") }
        assertTrue("the control is in the tree: $names", start >= 0)
        assertTrue("the count comes last: $names", end > start)
        return names.subList(start, end)
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act (as in I01 and C05). */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /** The name of the node with input focus inside the app, or "(none)". */
    private fun focusName(): String =
        all().firstOrNull { it.isFocused && it.name().isNotEmpty() }?.name() ?: "(none)"

    /** Tab until the control has keyboard focus; the first Tab can be used up leaving touch mode. */
    private fun tabToControl() {
        for (i in 0 until 6) {
            key("TAB")
            if (focusName().startsWith(TITLE)) return
        }
        throw AssertionError("Tab did not reach the control; focus on ${focusName()}")
    }

    @Test
    fun goodMaterialIsAButtonWithTheStateOnlyInItsName() {
        open("good-material")
        val c = control()
        assertEquals(BUTTON, c.type())
        // The state is the tile's hint, at the end of the name (FL-039, FL-264).
        assertEquals("$TITLE, Collapsed", c.name())
        assertTrue(c.isFocusable)
        assertEquals("Expand for more details", clickLabel(c))
        assertEquals("no expanded state (FL-264)", noState, expandedState(c))
        assertFalse(hasAction(c, AccessibilityNodeInfo.ACTION_EXPAND))
        assertFalse(hasAction(c, AccessibilityNodeInfo.ACTION_COLLAPSE))
        // The tile's live region, which announces the change, says the same word.
        assertTrue("the live region", all().any { it.liveRegion != 0 && it.name() == "Collapsed" })
        // The control is the only clickable node but Back, and a closed panel is not in the tree.
        assertEquals(1, all().count { it.isClickable && it.name() != "Back" })
        assertFalse(shown(PANEL_TEXT))
        assertEquals(listOf("$TITLE, Collapsed"), reading())
    }

    @Test
    fun goodMaterialOpensByTheClickActionStraightAfterTheControl() {
        // ACTION_CLICK is what TalkBack performs on a double tap.
        open("good-material")
        assertTrue(control().performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitFor("the click action opens it") { shown(PANEL_TEXT) }
        waitFor("the name says Expanded") { control().name() == "$TITLE, Expanded" }
        waitFor("the click label says Collapse") { clickLabel(control()) == "Collapse" }
        assertEquals(BUTTON, control().type())
        assertEquals("still no expanded state", noState, expandedState(control()))
        assertTrue("the live region", all().any { it.liveRegion != 0 && it.name() == "Expanded" })
        assertEquals(listOf("$TITLE, Expanded", PANEL_TEXT, PANEL_ACTION), reading())
        assertTrue(control().performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitFor("a second click closes it") { !shown(PANEL_TEXT) }
        waitFor("the name says Collapsed again") { control().name() == "$TITLE, Collapsed" }
    }

    @Test
    fun goodMaterialOpensByATap() {
        open("good-material")
        val r = android.graphics.Rect().also { control().getBoundsInScreen(it) }
        assertTrue(device.click(r.centerX(), r.centerY()))
        waitFor("a tap opens it") { shown(PANEL_TEXT) }
    }

    private fun opensAndClosesByKey(name: String) {
        open("good-material")
        tabToControl()
        key(name)
        waitFor("$name opens it") { shown(PANEL_TEXT) }
        waitFor("focus stays on the control after $name") { focusName() == "$TITLE, Expanded" }
        key(name)
        waitFor("$name again closes it") { !shown(PANEL_TEXT) }
        waitFor("focus stays on the control") { focusName() == "$TITLE, Collapsed" }
    }

    @Test
    fun goodMaterialIsReachedByTabAndOpenedAndClosedByEnter() = opensAndClosesByKey("ENTER")

    @Test
    fun goodMaterialIsReachedByTabAndOpenedAndClosedBySpace() = opensAndClosesByKey("SPACE")

    @Test
    fun goodMaterialOpenPanelButtonIsTheNextTabStop() {
        open("good-material")
        tabToControl()
        key("ENTER")
        waitFor("Enter opens it") { shown(PANEL_TEXT) }
        key("TAB")
        waitFor("the next Tab goes to the panel's button") { focusName() == PANEL_ACTION }
        assertEquals(0, count("good-material"))
        key("ENTER")
        waitForCount("good-material", 1)
    }

    // Each bad example is asserted to have its named defect.

    @Test
    fun badExpansionTileIsNotAButton() {
        open("bad-expansion-tile")
        val c = control()
        assertEquals(VIEW, c.type())
        assertEquals("$TITLE, Collapsed", c.name())
        assertEquals(noState, expandedState(c))
        assertTrue(c.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        // The positive control: the click opened it.
        waitFor("the click opens it") { shown(PANEL_TEXT) }
        waitFor("the name says Expanded") { control().name() == "$TITLE, Expanded" }
        assertEquals(VIEW, control().type())
    }

    @Test
    fun badExpandIconHasNoStateInAnyWords() {
        open("bad-expand-icon")
        val c = control()
        assertEquals(BUTTON, c.type())
        assertEquals(TITLE, c.name())
        assertEquals("", c.stateDescription?.toString().orEmpty())
        assertEquals("", c.hintText?.toString().orEmpty())
        assertEquals(noState, expandedState(c))
        assertEquals("Expand", clickLabel(c))
        assertFalse("no live region", all().any { it.liveRegion != 0 })
        assertTrue(c.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        // The positive control: the click opened it.
        waitFor("the click opens it") { shown(PANEL_TEXT) }
        assertEquals(listOf(TITLE, PANEL_TEXT, PANEL_ACTION), reading())
        // Read for two seconds: the name, state, and click label stay as
        // they were. FL-280: the click label stays "Expand" once open (in
        // the widget tests it changes to "Collapse"). Written to fail when
        // it changes.
        val end = System.currentTimeMillis() + 2_000
        while (System.currentTimeMillis() < end) {
            val now = control()
            assertEquals(TITLE, now.name())
            assertEquals("", now.stateDescription?.toString().orEmpty())
            assertEquals(noState, expandedState(now))
            assertEquals("FL-280", "Expand", clickLabel(now))
            Thread.sleep(250)
        }
    }

    /** Shift+Tab from the emulator's keyboard, as I02's test sends it. */
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
     * One whole cycle of keyboard focus: Tab (Shift+Tab when [backwards])
     * until Back has had focus twice, at most eight presses, and the name of
     * the focused node after each, "(none)" where no node of the app has it.
     * Whether the control has focus is also read at each stop. It does not
     * stop at the first Back, so a control after Back in the cycle is
     * always visited. Fails when no whole cycle is made.
     */
    private fun focusCycle(backwards: Boolean): List<String> {
        val stops = mutableListOf<String>()
        var backs = 0
        for (i in 0 until 8) {
            if (backwards) shiftTab() else key("TAB")
            val name = focusName()
            stops.add(if (control().isFocused) "CONTROL $name" else name)
            if (name == "Back" && ++backs == 2) return stops
        }
        throw AssertionError("no whole focus cycle in eight presses: $stops")
    }

    @Test
    fun goodMaterialFocusCycleVisitsTheControl() {
        // The positive control for the Cupertino tests below: the same
        // cycle, forwards and backwards, does visit a control that takes
        // focus.
        open("good-material")
        val forwards = focusCycle(backwards = false)
        assertTrue("Tab visits the control: $forwards", forwards.any { it.startsWith("CONTROL $TITLE") })
        val backwards = focusCycle(backwards = true)
        assertTrue("Shift+Tab visits the control: $backwards", backwards.any { it.startsWith("CONTROL $TITLE") })
    }

    /**
     * A whole focus cycle, forwards or backwards: every stop in the app is
     * Back, the control never has focus, and the panel stays closed. Then,
     * with focus on Back, where the cycle ended, [name] leaves the example:
     * the key reached the app, the positive control.
     */
    private fun cupertinoTakesNoFocus(name: String, backwards: Boolean) {
        open("bad-cupertino-expansion-tile")
        val stops = focusCycle(backwards)
        assertTrue("every stop in the app is Back: $stops", stops.all { it == "Back" || it == "(none)" })
        assertFalse("the panel stayed closed", shown(PANEL_TEXT))
        assertTrue("focus is on Back", named("Back").isFocused)
        key(name)
        waitFor("$name on Back leaves the example") {
            !anyWindowHas { it.name() == c06Titles.getValue("bad-cupertino-expansion-tile") }
        }
    }

    @Test
    fun badCupertinoExpansionTileTakesNoKeyboardFocusEnter() = cupertinoTakesNoFocus("ENTER", backwards = false)

    @Test
    fun badCupertinoExpansionTileTakesNoKeyboardFocusSpace() = cupertinoTakesNoFocus("SPACE", backwards = false)

    @Test
    fun badCupertinoExpansionTileTakesNoKeyboardFocusShiftTab() = cupertinoTakesNoFocus("ENTER", backwards = true)

    @Test
    fun badCupertinoExpansionTileIsNoButtonAndHasNoState() {
        open("bad-cupertino-expansion-tile")
        val c = control()
        assertEquals(VIEW, c.type())
        assertEquals(TITLE, c.name())
        assertEquals(noState, expandedState(c))
        assertTrue(c.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitFor("the click opens it") { shown(PANEL_TEXT) }
        // Open, the panel's text joins the control's name (FL-265).
        waitFor("the panel's text joins the control") { control().name() == "$TITLE\n$PANEL_TEXT" }
        assertEquals(VIEW, control().type())
        assertEquals(noState, expandedState(control()))
    }

    /**
     * L4. For each example: TalkBack focus goes to the control (closed);
     * then, with focus left there, its ACTION_CLICK, which is what a double
     * tap sends, and what TalkBack says on the change (activated); then focus
     * goes to the panel's text (panel) and back to the control (open). In
     * C05's probe, focus cleared and put back on the same node read
     * nothing, so focus goes elsewhere first. Each step logs a marker;
     * tool/talkback.py reads the speech between markers from logcat and
     * judges each walk whole (STRICT). Skipped unless TalkBack is running.
     *
     * `bad-expand-icon` and `bad-cupertino-expansion-tile` have no state to
     * announce: their `-activated` rows are declared silent
     * (tool/talkback.py SILENT), logged once the click action has
     * returned. Nothing at all may be spoken in them, their capture must be
     * ended by the next marker, and the row after each, the panel's text
     * or Back, is its liveness control and must be right, so a lost
     * capture cannot pass for silence. The Cupertino tile merges its
     * open panel's text into the control, so focus goes to Back in place of
     * a panel node.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        val silentOnChange = setOf("bad-expand-icon", "bad-cupertino-expansion-tile")
        for (slug in c06Titles.keys) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            android.util.Log.i(talkBackTag, "FOCUS c06-$slug-closed")
            talkBackFocus("$slug closed") { control() }
            Thread.sleep(6_000)
            if (slug in silentOnChange) {
                // Declared silent (tool/talkback.py SILENT): the marker is
                // logged once the click action has returned, so the row
                // holds only what is said after the change; the row after
                // it, the panel's text or Back, is its liveness control.
                assertTrue("$slug click", control().performAction(AccessibilityNodeInfo.ACTION_CLICK))
                android.util.Log.i(talkBackTag, "FOCUS c06-$slug-activated")
            } else {
                android.util.Log.i(talkBackTag, "FOCUS c06-$slug-activated")
                assertTrue("$slug click", control().performAction(AccessibilityNodeInfo.ACTION_CLICK))
            }
            Thread.sleep(6_000)
            assertTrue("$slug: the click opened it", shown(PANEL_TEXT))
            if (slug == "bad-cupertino-expansion-tile") {
                android.util.Log.i(talkBackTag, "FOCUS c06-$slug-back")
                talkBackFocus("$slug back") { named("Back") }
            } else {
                android.util.Log.i(talkBackTag, "FOCUS c06-$slug-panel")
                talkBackFocus("$slug panel") {
                    all().first { it.name() == PANEL_TEXT || it.text?.toString() == PANEL_TEXT }
                }
            }
            Thread.sleep(6_000)
            android.util.Log.i(talkBackTag, "FOCUS c06-$slug-open")
            talkBackFocus("$slug open") { control() }
            Thread.sleep(6_000)
            android.util.Log.i(talkBackTag, "END $slug")
        }
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val c06Titles = linkedMapOf(
    "good-material" to "ExpansionTile as a button",
    "bad-expansion-tile" to "ExpansionTile as it comes",
    "bad-expand-icon" to "ExpandIcon beside a label",
    "bad-cupertino-expansion-tile" to "CupertinoExpansionTile",
)
