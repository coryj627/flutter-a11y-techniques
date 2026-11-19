// L3 (tree, keyboard, Back, and the dismiss action) and L4 (TalkBack) for
// I08 Dismiss and escape on Android.
// Spec: docs/specs/I08-dismiss-and-escape.md.
//
// Every keyboard stop is named: after each key the test names the one node
// that reports isFocused, which follows Flutter's keyboard focus
// (docs/evidence/probes/i01/README.md). Tab and Escape are sent with
// `input keyevent`; Shift+Tab as four key events through
// Instrumentation.sendKeySync (docs/evidence/probes/i02/README.md). Back is
// the Back key (`input keyevent KEYCODE_BACK`), and the global Back action
// (`performGlobalAction(GLOBAL_ACTION_BACK)`), the call TalkBack's Back
// gesture makes.
//
// Every read of the screen goes through screen(), which reads the app's own
// window and fails unless that read holds this example, or the technique's
// own screen. So a read that found nothing can never pass for "the layers
// are still shown" or "the screen left", and each of those is positively
// identified: the layers by both switches, the example's screen by its
// count, the technique's screen by its title. Every check that a
// key or a command did nothing reads the screen again after a second, and
// in the same launch something else is shown to act.
package dev.fluttera11y.flutter_a11y_techniques

import android.accessibilityservice.AccessibilityService
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
private const val SWITCH = "android.widget.Switch"

private val GOOD = listOf("good-material", "good-cupertino", "good-widgets")
private val ALL = GOOD + listOf("bad-not-dismissible", "bad-no-escape", "bad-back-leaves")

// The examples whose layers are a route of their own: Enter leaves focus
// on the route's scope, and the next Tab is the first switch.
private val ROUTES = listOf("good-material", "good-cupertino", "bad-not-dismissible")
private val ESCAPE_CLOSES = GOOD + "bad-back-leaves"
private val BACK_CLOSES = GOOD + listOf("bad-not-dismissible", "bad-no-escape")

// What TalkBack reads for each example's barrier, the node with the
// dismiss action; bad-not-dismissible's has none.
private val BARRIER = mapOf(
    "good-material" to "Scrim",
    "good-cupertino" to "Dismiss",
    "good-widgets" to "Close map layers",
    "bad-no-escape" to "Close map layers",
    "bad-back-leaves" to "Close map layers",
)

// The technique's own screen, by its title in the app bar; an example's
// screen has the example's own title there.
private const val TECHNIQUE_SCREEN = "Dismiss and escape"

// How long the walk listens after a step, and the last interval of it, in
// which TalkBack's focus must stay put.
private const val SPEECH_MILLIS = 6_000L
private const val STEADY_MILLIS = 2_000L

@RunWith(AndroidJUnit4::class)
class I08DismissAndEscapeTest : TechniqueTest("I08") {
    override val countName: String get() = "closed count"

    private fun open(slug: String) = openExample(slug, By.res("i08-$slug-count"))

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

    private fun isTechniqueScreen(n: AccessibilityNodeInfo) =
        n.name() == TECHNIQUE_SCREEN || n.text?.toString() == TECHNIQUE_SCREEN

    /**
     * One read of the app's own window: every node, depth first. Of all the
     * windows on the screen, the active one first, it is the one that holds
     * a node of this example (one of its identifiers) or the technique's
     * own screen. Fails, after five seconds of trying, when none does.
     */
    private fun screen(slug: String): List<AccessibilityNodeInfo> {
        val end = System.currentTimeMillis() + 5_000
        while (true) {
            val roots = listOfNotNull(automation.rootInActiveWindow) + automation.windows.mapNotNull { it.root }
            for (root in roots) {
                val nodes = nodesOf(root)
                if (nodes.any { it.viewIdResourceName?.startsWith("i08-$slug-") == true || isTechniqueScreen(it) }) {
                    return nodes
                }
            }
            if (System.currentTimeMillis() > end) throw AssertionError("no window holds the example $slug")
            Thread.sleep(250)
        }
    }

    private fun ids(nodes: List<AccessibilityNodeInfo>) = nodes.mapNotNull { it.viewIdResourceName }

    /** What one read shows: "layers" (both switches), "screen" (the count and no switch), "technique", or "other". */
    private fun showing(slug: String): String {
        val nodes = screen(slug)
        val ids = ids(nodes)
        return when {
            "i08-$slug-contours" in ids && "i08-$slug-campsites" in ids -> "layers"
            "i08-$slug-count" in ids && ids.none { it == "i08-$slug-contours" || it == "i08-$slug-campsites" } -> "screen"
            nodes.any(::isTechniqueScreen) && ids.none { it.startsWith("i08-$slug-") } -> "technique"
            else -> "other: ${ids.filter { it.startsWith("i08-") }}"
        }
    }

    /** Waits up to five seconds for [showing] to be [expected]; returns the last. */
    private fun showingWhen(slug: String, expected: String): String {
        val end = System.currentTimeMillis() + 5_000
        var last = showing(slug)
        while (last != expected && System.currentTimeMillis() < end) {
            Thread.sleep(200)
            last = showing(slug)
        }
        return last
    }

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

    private fun globalBack() {
        assertTrue("global Back", automation.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK))
        Thread.sleep(700)
    }

    /**
     * A hardware keyboard's own Back: Meta and [code] together, which
     * Android's system shortcuts turn into Back (Meta+Escape and Meta+Left
     * in AOSP's InputGestureManager; measured on this emulator in docs/
     * evidence/probes/i08/android_round4.txt). Sent as four key events, as
     * Shift+Tab is.
     */
    private fun metaChord(code: Int) {
        val t = SystemClock.uptimeMillis()
        val meta = KeyEvent.META_META_ON or KeyEvent.META_META_LEFT_ON
        fun event(time: Long, action: Int, key: Int, state: Int) = KeyEvent(
            time, time, action, key, 0, state, KeyCharacterMap.VIRTUAL_KEYBOARD, 0, 0,
            InputDevice.SOURCE_KEYBOARD)
        inst.sendKeySync(event(t, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_META_LEFT, meta))
        inst.sendKeySync(event(t + 10, KeyEvent.ACTION_DOWN, code, meta))
        inst.sendKeySync(event(t + 20, KeyEvent.ACTION_UP, code, meta))
        inst.sendKeySync(event(t + 30, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_META_LEFT, 0))
        Thread.sleep(700)
    }

    private val keyboardBacks = listOf("Meta+Escape" to KeyEvent.KEYCODE_ESCAPE, "Meta+Left" to KeyEvent.KEYCODE_DPAD_LEFT)

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
        return if (id.startsWith("i08-$slug-")) id.removePrefix("i08-$slug-") else "other: $id ${node.name()}"
    }

    /** The stop once it is [expected], or the last one read after three seconds. */
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
     * after the app opens is sometimes lost (docs/evidence/probes/i01/
     * README.md), so this allows for one more than the order needs.
     */
    private fun tabTo(slug: String, part: String, max: Int = 4): Boolean {
        for (i in 0 until max) {
            if (stop(slug) == part) return true
            key("TAB")
        }
        return stop(slug) == part
    }

    private fun walk(slug: String, n: Int, press: () -> Unit): List<String> =
        (0 until n).map { press(); stop(slug) }

    /** Whether the switch [part] reports on. */
    private fun isOn(slug: String, part: String): Boolean =
        screen(slug).first { it.viewIdResourceName == "i08-$slug-$part" }.isChecked

    /**
     * Opens [slug], tabs to Map layers (Back first), and presses Enter; then
     * waits for the layers and Tabs on to the first switch where Enter left
     * focus on a route's scope.
     */
    private fun showByKeyboard(slug: String) {
        open(slug)
        Log.i("I08KEYS", "$slug | opened: ${showing(slug)}")
        // The app's window must be the active one: a key sent to another
        // window acts there. Says which window it is when it is not.
        val end = System.currentTimeMillis() + 5_000
        while (automation.rootInActiveWindow?.packageName?.toString() != inst.targetContext.packageName &&
            System.currentTimeMillis() < end) Thread.sleep(250)
        assertEquals("$slug: the active window's app; windows: ${automation.windows.map { "${it.title} (${it.type})" }}",
            inst.targetContext.packageName, automation.rootInActiveWindow?.packageName?.toString())
        revealed("i08-$slug-open")
        assertTrue("$slug: Tab reaches Map layers", tabTo(slug, "open"))
        key("ENTER")
        assertEquals("$slug: Enter shows the layers", "layers", showingWhen(slug, "layers"))
        if (slug in ROUTES) {
            assertEquals(slug, "none", stopWhen(slug, "none"))
            key("TAB")
        }
        assertEquals(slug, "contours", stopWhen(slug, "contours"))
    }

    /** Expects the layers closed on the example's screen, with focus back on Map layers. */
    private fun expectClosed(slug: String, how: String) {
        assertEquals("$slug: after $how", "screen", showingWhen(slug, "screen"))
        waitForCount(slug, 1)
        assertEquals("$slug: focus after $how", "open", stopWhen(slug, "open"))
    }

    /** Expects the layers still shown a second later, with focus still on [part]. */
    private fun expectStillShown(slug: String, part: String, how: String) {
        Thread.sleep(1_000)
        assertEquals("$slug: after $how", "layers", showing(slug))
        assertEquals("$slug: focus after $how", part, stop(slug))
    }

    @Test
    fun everyExampleHasItsButtonAndSwitches() {
        for (slug in ALL) {
            open(slug)
            val button = revealed("i08-$slug-open")
            assertEquals(slug, "Map layers", button.name())
            assertEquals(slug, BUTTON, button.type())
            assertTrue(slug, button.hasClickAction())
            assertEquals(slug, 0, count(slug))
            assertTrue("$slug: click", revealed("i08-$slug-open").performAction(AccessibilityNodeInfo.ACTION_CLICK))
            assertEquals(slug, "layers", showingWhen(slug, "layers"))
            for ((part, name, on) in listOf(Triple("contours", "Contour lines", true), Triple("campsites", "Campsites", false))) {
                val node = screen(slug).first { it.viewIdResourceName == "i08-$slug-$part" }
                assertEquals("$slug $part", name, node.name())
                assertEquals("$slug $part", SWITCH, node.type())
                assertEquals("$slug $part", on, node.isChecked)
            }
        }
    }

    @Test
    fun tabAndShiftTabGoRoundTheSwitches() {
        for (slug in ALL) {
            showByKeyboard(slug)
            assertEquals(slug, listOf("campsites", "contours", "campsites", "contours"), walk(slug, 4) { key("TAB") })
            assertEquals(slug, listOf("campsites", "contours", "campsites", "contours"), walk(slug, 4) { shiftTab() })
        }
    }

    @Test
    fun escapeClosesTheLayers() {
        for (slug in ESCAPE_CLOSES) {
            showByKeyboard(slug)
            key("ESCAPE")
            expectClosed(slug, "Escape")
        }
    }

    /** The good example each bad one is made from, by its title on the technique's screen. */
    private val goodOf = mapOf(
        "bad-not-dismissible" to ("good-material" to "A Material bottom sheet that can be dismissed"),
        "bad-no-escape" to ("good-widgets" to "Layers drawn in the overlay, closed by every dismiss command"),
    )

    /** The node of the technique's screen whose name starts with [title], scrolling to it. */
    private fun tile(slug: String, title: String): AccessibilityNodeInfo {
        fun find() = screen(slug).firstOrNull { it.name().startsWith(title) && it.isClickable }
        find()?.let { return it }
        for (i in 0 until 8) {
            val view = screen(slug).firstOrNull { it.isScrollable } ?: break
            if (!view.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) break
            Thread.sleep(500)
            find()?.let { return it }
        }
        throw AssertionError("no tile \"$title\" on the technique's screen")
    }

    // The defects. Escape alone, from each switch; a second later the layers
    // are still shown and focus has not moved; then Space on the stop turns
    // its layer, so keys arrive. Then, in the same launch, the positive
    // control for Escape itself: Back closes the layers and leaves the
    // screen, the good example the bad one is made from is opened from the
    // technique's screen, and the same Escape closes its layers. Written to
    // fail when Escape closes the bad example's layers.
    @Test
    fun escapeDoesNothingInTheBadExamples() {
        for (slug in listOf("bad-not-dismissible", "bad-no-escape")) {
            showByKeyboard(slug)
            for (part in listOf("contours", "campsites")) {
                if (part == "campsites") assertEquals(slug, listOf("campsites"), walk(slug, 1) { key("TAB") })
                val before = isOn(slug, part)
                key("ESCAPE")
                expectStillShown(slug, part, "Escape on $part")
                key("SPACE")
                Thread.sleep(500)
                assertEquals("$slug: Space on $part", !before, isOn(slug, part))
            }
            key("BACK")
            assertEquals("$slug: Back closes the layers", "screen", showingWhen(slug, "screen"))
            key("BACK")
            assertEquals("$slug: Back leaves the screen", "technique", showingWhen(slug, "technique"))
            val (good, title) = goodOf.getValue(slug)
            assertTrue("open $good", tile(slug, title).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            assertTrue("$good opens", device.wait(androidx.test.uiautomator.Until.hasObject(By.res("i08-$good-count")), 10_000))
            // Shown from the keyboard, as in the bad example, and closed on
            // its own screen: both switches gone, its count at 1, keyboard
            // focus back on its Map layers.
            revealed("i08-$good-open")
            assertTrue("$good: Tab reaches Map layers", tabTo(good, "open"))
            key("ENTER")
            assertEquals(good, "layers", showingWhen(good, "layers"))
            if (good in ROUTES) key("TAB")
            assertEquals(good, "contours", stopWhen(good, "contours"))
            key("ESCAPE")
            expectClosed(good, "Escape, the positive control in the launch of $slug")
        }
    }

    // bad-no-escape: Tab and Shift+Tab never leave the layers (the keyboard's
    // Back does: keyboardBackClosesTheLayers). Ten of each.
    @Test
    fun badNoEscapeNoKeyLeavesTheLayers() {
        val slug = "bad-no-escape"
        showByKeyboard(slug)
        val stops = walk(slug, 10) { key("TAB") } + walk(slug, 10) { shiftTab() }
        assertEquals(setOf("contours", "campsites"), stops.toSet())
        assertEquals("layers", showing(slug))
    }

    @Test
    fun backClosesTheLayers() {
        for (slug in BACK_CLOSES) {
            showByKeyboard(slug)
            key("BACK")
            expectClosed(slug, "Back")
        }
    }

    // As TalkBack's Back gesture does it, without TalkBack.
    @Test
    fun globalBackClosesTheLayers() {
        for (slug in BACK_CLOSES) {
            showByKeyboard(slug)
            globalBack()
            expectClosed(slug, "the global Back action")
        }
    }

    // A hardware keyboard's Back closes the layers where Back does, the
    // two bad examples that ignore Escape included: on Android a keyboard
    // user can leave them.
    @Test
    fun keyboardBackClosesTheLayers() {
        for (slug in BACK_CLOSES) {
            for ((name, code) in keyboardBacks) {
                showByKeyboard(slug)
                metaChord(code)
                expectClosed(slug, name)
                // One Back, not two: three seconds later the example's
                // screen is still there, with the layers closed.
                Thread.sleep(3_000)
                Log.i("I08KEYS", "$slug $name | 3 s after: ${showing(slug)}")
                assertEquals("$slug: three seconds after $name", "screen", showing(slug))
            }
        }
    }

    // The defect. First the positive control, in the same launch: Escape
    // closes the layers on the example's screen. Then Back with the layers
    // shown leaves the screen: the technique's own screen is read, and the
    // app is still in front. Written to fail when Back closes the layers.
    @Test
    fun badBackLeavesTheScreen() {
        val slug = "bad-back-leaves"
        val backs = listOf({ key("BACK") }, { globalBack() }) +
            keyboardBacks.map { (_, code) -> { metaChord(code) } }
        for (back in backs) {
            showByKeyboard(slug)
            key("ESCAPE")
            expectClosed(slug, "Escape")
            key("ENTER")
            assertEquals(slug, "layers", showingWhen(slug, "layers"))
            back()
            assertEquals(slug, "technique", showingWhen(slug, "technique"))
            assertEquals("the app is in front", inst.targetContext.packageName, device.currentPackageName)
        }
    }

    /** The nodes of one read that have the dismiss action, by name. */
    private fun dismissable(slug: String): List<AccessibilityNodeInfo> =
        screen(slug).filter { n -> n.actionList.any { it.id == AccessibilityNodeInfo.ACTION_DISMISS } }

    @Test
    fun theDismissActionClosesTheLayers() {
        for ((slug, barrier) in BARRIER) {
            showByKeyboard(slug)
            val nodes = dismissable(slug)
            val names = nodes.map { it.name() }
            assertTrue("$slug: $names", barrier in names)
            assertTrue("$slug: dismiss", nodes.first { it.name() == barrier }.performAction(AccessibilityNodeInfo.ACTION_DISMISS))
            expectClosed(slug, "the dismiss action on $barrier")
            if (slug in listOf("good-widgets", "bad-no-escape", "bad-back-leaves")) {
                // The layers themselves have the action too, with no name.
                key("ENTER")
                assertEquals(slug, "layers", showingWhen(slug, "layers"))
                val layers = dismissable(slug).single { it.name().isEmpty() }
                assertTrue("$slug: dismiss the layers", layers.performAction(AccessibilityNodeInfo.ACTION_DISMISS))
                assertEquals("$slug: after the dismiss action on the layers", "screen", showingWhen(slug, "screen"))
                waitForCount(slug, 2)
            }
        }
    }

    // The defect. The same read that shows the layers has no node with the
    // dismiss action. Written to fail when the barrier gets one.
    @Test
    fun badNotDismissibleHasNoDismissAction() {
        val slug = "bad-not-dismissible"
        showByKeyboard(slug)
        val nodes = screen(slug)
        assertTrue("the read holds the layers", "i08-$slug-contours" in ids(nodes))
        assertEquals(emptyList<String>(),
            nodes.filter { n -> n.actionList.any { it.id == AccessibilityNodeInfo.ACTION_DISMISS } }.map { it.name() })
    }

    /** TalkBack's focus: the identifier or name of the node that has it, or "none". */
    private fun talkBackOn(): String {
        val n = automation.findFocus(AccessibilityNodeInfo.FOCUS_ACCESSIBILITY) ?: return "none"
        return n.viewIdResourceName?.ifEmpty { null }
            ?: n.name().ifEmpty { n.text?.toString().orEmpty() }.ifEmpty { "(${n.type()})" }
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

    /** The node of the layers' barrier, by what TalkBack reads. */
    private fun barrierNode(name: String): AccessibilityNodeInfo {
        val end = System.currentTimeMillis() + 8_000
        while (true) {
            for (root in listOfNotNull(automation.rootInActiveWindow) + automation.windows.mapNotNull { it.root }) {
                nodesOf(root).firstOrNull { it.name() == name }?.let { return it }
            }
            if (System.currentTimeMillis() > end) throw AssertionError("no node named $name")
            Thread.sleep(250)
        }
    }

    /**
     * L4. Skips unless TalkBack is running. In each example TalkBack's
     * focus is put on Map layers, which is activated with the click action
     * as a double tap does; then on each switch and on the barrier, so that
     * what TalkBack reads for each is recorded. Then TalkBack's Back gesture
     * (the global Back action): the layers close and TalkBack's focus must
     * be on Map layers for the last interval; in bad-back-leaves the screen
     * leaves, and TalkBack's focus must be on the technique's screen.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        val failures = mutableListOf<String>()
        fun check(ok: Boolean, message: String) { if (!ok) failures += message }
        for (slug in ALL) {
            openExampleInAnyWindow(slug) { it.viewIdResourceName == "i08-$slug-count" }
            Thread.sleep(8_000)
            val opener = "i08-$slug-open"
            Log.i(talkBackTag, "FOCUS $opener")
            talkBackFocus(opener) { nodeInAnyWindow(opener) }
            Thread.sleep(3_000)
            assertTrue("click $opener", nodeInAnyWindow(opener).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            // Let TalkBack finish what it reads where its focus goes when
            // the layers open, which is logged.
            Thread.sleep(7_000)
            Log.i("I08FOCUS", "$slug | when the layers open: ${talkBackOn()}")
            // Campsites first: when the layers open, TalkBack's focus can
            // already be on Contour lines, and a move to where it is says
            // nothing new.
            for (part in listOf("campsites", "contours")) {
                val id = "i08-$slug-$part"
                Log.i(talkBackTag, "FOCUS $id")
                talkBackFocus(id) { nodeInAnyWindow(id) }
                Thread.sleep(3_000)
            }
            BARRIER[slug]?.let { name ->
                Log.i(talkBackTag, "FOCUS i08-$slug-barrier")
                talkBackFocus(name) { barrierNode(name) }
                Thread.sleep(3_000)
                // Back on a switch, so that the gesture is made from inside
                // the layers.
                talkBackFocus("i08-$slug-contours") { nodeInAnyWindow("i08-$slug-contours") }
                Thread.sleep(2_000)
            }
            Log.i(talkBackTag, "FOCUS i08-$slug-back")
            assertTrue("global Back", automation.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK))
            Thread.sleep(SPEECH_MILLIS)
            val last = talkBackOver(STEADY_MILLIS)
            Log.i(talkBackTag, "END $slug")
            Log.i("I08FOCUS", "$slug | after Back: $last")
            if (slug == "bad-back-leaves") {
                check(nodesOf(automation.rootInActiveWindow).any(::isTechniqueScreen),
                    "$slug: Back did not leave for the technique's screen")
                check(last.none { it.startsWith("i08-$slug-") }, "$slug: TalkBack is still on the example: $last")
            } else {
                check(last == listOf(opener), "$slug: TalkBack's focus over the last interval: $last")
            }
        }
        assertTrue(failures.joinToString("\n"), failures.isEmpty())
    }
}
