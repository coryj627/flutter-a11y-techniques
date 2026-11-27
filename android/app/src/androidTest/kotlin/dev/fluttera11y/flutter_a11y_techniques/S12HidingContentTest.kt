// L3 (tree) and L4 (TalkBack walk) for S12 Hiding content from AT on
// Android. Spec: docs/specs/S12-hiding-content.md.
//
// Texts are found by their names (an identifier would be a node of its
// own); the controls and the counts by their test identifiers. Each count
// under an example says what its controls did.
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

private const val QUOTE = "Walk the ridge before the sun is up."
private const val SOURCE = "Trail guide"
private const val QUOTE_MARK = "❝"
private const val ORNAMENT = "✦ ✦ ✦"
private const val INBOX = "Inbox: 3 unread"
private const val TRACKING = "Tracking number: 1Z 999"
private const val SHOW = "Show tracking"
private const val COPY = "Copy number"

@RunWith(AndroidJUnit4::class)
class S12HidingContentTest : TechniqueTest("S12") {
    /** Waits for the example's own title. */
    private fun open(slug: String) = openExample(slug, By.desc(s12Titles.getValue(slug)), settleMillis = 500)

    /** Presses a key on the emulator's keyboard and gives Flutter time to act (as in I01). */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /** What the count [id] says: "Copies: 1"; null while it cannot be read. */
    private fun countNow(id: String): String? = try { revealed(id).name() } catch (e: AssertionError) { null }

    /** Waits up to 5 seconds for the count [id] to say [expected]; a miss is read again. */
    private fun waitForCount(what: String, id: String, expected: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            if (countNow(id) == expected) return
            Thread.sleep(100)
        }
        assertEquals(what, expected, countNow(id))
    }

    /** The count [id] stays [expected] for [millis]: read in a loop, never once. */
    private fun assertCountStays(what: String, id: String, expected: String, millis: Long = 2_000) {
        val end = System.currentTimeMillis() + millis
        while (System.currentTimeMillis() < end) {
            val now = countNow(id)
            if (now != null) assertEquals(what, expected, now)
            Thread.sleep(100)
        }
        assertEquals(what, expected, countNow(id))
    }

    private val isEnd = { n: AccessibilityNodeInfo ->
        n.viewIdResourceName?.matches(Regex("s12-.*-count")) == true
    }

    /**
     * The nodes of the example between the "Example" heading and its count
     * (or the end of the screen), in the tree's order, that have a name or
     * a click action. The screen is read from the top, then scrolled a step
     * at a time until the count is in the tree; each node is kept once.
     */
    private fun exampleNodes(): List<AccessibilityNodeInfo> {
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        val keys = mutableSetOf<String>()
        fun collect(n: AccessibilityNodeInfo?) {
            if (n == null) return
            if (keys.add("${n.name()}|${n.type()}|${n.viewIdResourceName}")) nodes.add(n)
            for (i in 0 until n.childCount) collect(n.getChild(i))
        }
        for (step in 0 until 8) {
            collect(automation.rootInActiveWindow)
            if (nodes.any(isEnd)) break
            val view = all().firstOrNull { it.isScrollable } ?: break
            if (!view.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) break
            Thread.sleep(500)
        }
        val start = nodes.indexOfFirst { it.name() == "Example" }
        assertTrue("the Example heading", start >= 0)
        val end = nodes.indexOfFirst(isEnd)
        return nodes.subList(start + 1, if (end < 0) nodes.size else end)
            .filter { it.name().isNotEmpty() || it.hasClickAction() }
    }

    private fun describe(n: AccessibilityNodeInfo): String = listOfNotNull(
        n.name(),
        n.type().substringAfterLast('.'),
        if (n.isCheckable) "checked=${n.isChecked}" else null,
        if (n.isClickable) "clickable" else null,
    ).joinToString(" | ")

    /** Every name on the screen, scrolled to its end first. */
    private fun allNames(): List<String> {
        scrollToEnd()
        return all().map { it.name() }.filter { it.isNotEmpty() }
    }

    /** The name of the node with input focus, or "(none)" if no node has it. */
    private fun focusedName(): String {
        val f = all().lastOrNull { it.isFocused } ?: return "(none)"
        return f.name().ifEmpty { "(${f.type()})" }
    }

    /** Tab until [id] has input focus; the first Tab can be used up leaving touch mode. */
    private fun tabTo(id: String) {
        for (i in 0 until 8) {
            key("TAB")
            if (revealed(id).isFocused) return
        }
        throw AssertionError("Tab did not reach $id")
    }

    @Test
    fun goodDecorationHasTheQuoteAndItsSourceAndNoOrnament() {
        open("good-decoration")
        assertEquals(listOf("$QUOTE | View", "$SOURCE | View"), exampleNodes().map(::describe))
        for (name in allNames()) {
            assertFalse(name, name.contains(QUOTE_MARK))
            assertFalse(name, name.contains("✦"))
        }
    }

    @Test
    fun goodBadgeHasTheWordsAloneAndNoNode3() {
        open("good-badge")
        assertEquals(listOf("$INBOX | View"), exampleNodes().map(::describe))
        assertEquals(listOf(INBOX), allNames().filter { it.contains("3") })
    }

    @Test
    fun goodVisibilityHiddenHasNoPanelNodeAndTheKeyboardDoesNotReachCopy() {
        open("good-visibility")
        assertEquals(listOf("$SHOW | Switch | checked=false | clickable"), exampleNodes().map(::describe))
        assertFalse(allNames().contains(TRACKING))
        assertFalse(allNames().contains(COPY))
        // A whole cycle of Tabs, from a fresh launch: the first Tab can be
        // used up leaving touch mode, so the cycle is read until a stop comes
        // round again. Copy is never focused, and no Tab leaves no node
        // focused (as a hidden control would).
        val stops = mutableListOf<String>()
        for (i in 0 until 7) {
            key("TAB")
            stops.add(focusedName())
        }
        assertTrue("the switch is a stop: $stops", stops.contains(SHOW))
        assertTrue("Back is a stop: $stops", stops.contains("Back"))
        assertTrue("only Back and the switch, after touch mode is left: $stops",
            stops.drop(1).all { it == "Back" || it == SHOW })
        // Positive control, in the same launch: shown, the panel is there,
        // and the keyboard reaches Copy, and Enter copies.
        assertTrue(node("s12-good-visibility-show").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !node("s12-good-visibility-show").isChecked) Thread.sleep(100)
        assertEquals(
            listOf("$SHOW | Switch | checked=true | clickable", "$TRACKING | View", "$COPY | Button | clickable"),
            exampleNodes().map(::describe),
        )
        tabTo("s12-good-visibility-copy")
        key("ENTER")
        waitForCount("good-visibility: Tab then Enter on Copy", "s12-good-visibility-count", "Copies: 1")
    }

    @Test
    fun goodVisibilityHiddenEnterAtEachStopCopiesNothing() {
        // Each stop from a fresh launch: Enter on Back leaves the screen,
        // Enter on the switch shows the panel. Neither copies.
        for (tabs in 1..3) {
            open("good-visibility")
            for (i in 0 until tabs) key("TAB")
            val on = focusedName()
            key("ENTER")
            if (on == "Back" || on == "(none)") continue
            assertEquals("after $tabs Tab(s)", SHOW, on)
            assertCountStays("good-visibility: Enter on the switch", "s12-good-visibility-count", "Copies: 0")
            // In the same launch, the panel shown: Tab to Copy and Enter copies.
            tabTo("s12-good-visibility-copy")
            key("ENTER")
            waitForCount("good-visibility: then Tab to Copy and Enter", "s12-good-visibility-count", "Copies: 1")
            return
        }
        throw AssertionError("no try of one to three Tabs landed on the switch")
    }

    @Test
    fun goodVisibilityShownCopyCopiesByTheClickActionAndATap() {
        open("good-visibility")
        assertTrue(node("s12-good-visibility-show").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !node("s12-good-visibility-show").isChecked) Thread.sleep(100)
        assertTrue(node("s12-good-visibility-copy").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("the click action on Copy", "s12-good-visibility-count", "Copies: 1")
        val r = Rect().also { node("s12-good-visibility-copy").getBoundsInScreen(it) }
        device.click(r.centerX(), r.centerY())
        waitForCount("a tap on Copy", "s12-good-visibility-count", "Copies: 2")
    }

    @Test
    fun badDecorationReadHasEachOrnamentAsANode() {
        open("bad-decoration-read")
        assertEquals(
            listOf("$QUOTE_MARK | View", "$QUOTE | View", "$SOURCE | View", "$ORNAMENT | View"),
            exampleNodes().map(::describe),
        )
    }

    @Test
    fun badHiddenControlHasNoShareNodeAndTheKeyboardRunsIt() {
        open("bad-hidden-control")
        assertEquals(listOf("$QUOTE | View"), exampleNodes().map(::describe))
        assertFalse(allNames().contains("Share"))
        assertEquals("no clickable node but Back", 0, all().count { it.isClickable && it.name() != "Back" })
        // From a fresh launch each, one to three Tabs then the key: one try
        // shares with focus reported on Back (no node for Share), and one
        // leaves the screen (Enter on Back, the positive control). The first
        // Tab can be used up leaving touch mode, so which try is which is
        // not fixed.
        for (k in listOf("ENTER", "SPACE")) {
            var shared = false
            var left = false
            for (tabs in 1..3) {
                open("bad-hidden-control")
                for (i in 0 until tabs) key("TAB")
                val on = focusedName()
                assertFalse("no node named Share has focus", on == "Share")
                key(k)
                Thread.sleep(1_500)
                when (countNow("s12-bad-hidden-control-count")) {
                    "Shares: 1" -> shared = true
                    null -> left = !anyWindowHas { it.name() == s12Titles.getValue("bad-hidden-control") }
                    else -> {}
                }
            }
            assertTrue("$k: one try shared", shared)
            assertTrue("$k: one try left the screen", left)
        }
    }

    @Test
    fun badHiddenControlATapWhereShareIsDrawnShares() {
        open("bad-hidden-control")
        val quote = Rect().also { named(QUOTE).getBoundsInScreen(it) }
        val count = Rect().also { node("s12-bad-hidden-control-count").getBoundsInScreen(it) }
        val y = (quote.bottom + count.top) / 2
        // Share is drawn after the ornament, on the line between the quote
        // and the count.
        for (x in listOf(0.30, 0.40, 0.50)) {
            device.click(quote.left + (quote.width() * x).toInt(), y)
            Thread.sleep(800)
            if (countNow("s12-bad-hidden-control-count") == "Shares: 1") return
        }
        throw AssertionError("no tap between the quote and the count shared")
    }

    @Test
    fun badOpacityHiddenHasNoPanelNodeAndTheKeyboardCopies() {
        open("bad-opacity")
        assertEquals(listOf("$SHOW | Switch | checked=false | clickable"), exampleNodes().map(::describe))
        assertFalse(allNames().contains(TRACKING))
        assertFalse(allNames().contains(COPY))
        for (k in listOf("ENTER", "SPACE")) {
            open("bad-opacity")
            tabTo("s12-bad-opacity-show")
            key("TAB")
            // Focus is on Copy, which has no node: the switch is still
            // reported as focused.
            key(k)
            waitForCount("bad-opacity: $k after the switch", "s12-bad-opacity-count", "Copies: 1")
            assertFalse("the switch is still off", node("s12-bad-opacity-show").isChecked)
        }
        // A tap where Copy is laid out: the lower part of the space between
        // the switch and the count, where the panel's button is. The screen
        // is scrolled to its end first and both bounds are read from that
        // one state (on CI's 320 by 640 screen the example is below the
        // fold); a few points down the gap are tried, and one must copy.
        open("bad-opacity")
        scrollToEnd()
        val s = Rect().also { all().single { it.viewIdResourceName == "s12-bad-opacity-show" }.getBoundsInScreen(it) }
        val c = Rect().also { all().single { it.viewIdResourceName == "s12-bad-opacity-count" }.getBoundsInScreen(it) }
        var copied = false
        for (fraction in listOf(0.60, 0.70, 0.80, 0.90)) {
            device.click(s.left + 40, s.bottom + ((c.top - s.bottom) * fraction).toInt())
            Thread.sleep(800)
            if (countNow("s12-bad-opacity-count") == "Copies: 1") {
                copied = true
                break
            }
        }
        assertTrue("a tap between the switch and the count, where Copy is laid out, copied", copied)
        assertFalse("the switch is still off", node("s12-bad-opacity-show").isChecked)
    }

    @Test
    fun badMaintainHiddenHasThePanelNodesAndTheKeyboardCopies() {
        open("bad-maintain")
        assertEquals(
            listOf("$SHOW | Switch | checked=false | clickable", "$TRACKING | View", "$COPY | Button | clickable"),
            exampleNodes().map(::describe),
        )
        tabTo("s12-bad-maintain-copy")
        key("ENTER")
        waitForCount("bad-maintain: Tab then Enter on Copy", "s12-bad-maintain-count", "Copies: 1")
        assertFalse("the switch is still off", node("s12-bad-maintain-show").isChecked)
        assertTrue(node("s12-bad-maintain-copy").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("bad-maintain: the click action on Copy", "s12-bad-maintain-count", "Copies: 2")
    }

    /**
     * L4. Moves TalkBack focus to each part of each example and logs
     * markers; tool/talkback.py reads the speech from logcat and judges the
     * walk whole. Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val byName = { marker: String, name: String -> Stop(marker) { all().single { it.name() == name } } }
        val byId = { marker: String, id: String -> Stop(marker) { node(id) } }
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-decoration" to listOf(
                byName("s12-good-decoration-quote", QUOTE),
                byName("s12-good-decoration-source", SOURCE),
            ),
            "good-badge" to listOf(byName("s12-good-badge-inbox", INBOX)),
            "good-visibility" to listOf(
                byId("s12-good-visibility-show", "s12-good-visibility-show"),
                byId("s12-good-visibility-count", "s12-good-visibility-count"),
            ),
            "bad-decoration-read" to listOf(
                byName("s12-bad-decoration-read-mark", QUOTE_MARK),
                byName("s12-bad-decoration-read-quote", QUOTE),
                byName("s12-bad-decoration-read-source", SOURCE),
                byName("s12-bad-decoration-read-ornament", ORNAMENT),
            ),
            "bad-hidden-control" to listOf(
                byName("s12-bad-hidden-control-quote", QUOTE),
                byId("s12-bad-hidden-control-count", "s12-bad-hidden-control-count"),
            ),
            "bad-opacity" to listOf(
                byId("s12-bad-opacity-show", "s12-bad-opacity-show"),
                byId("s12-bad-opacity-count", "s12-bad-opacity-count"),
            ),
            "bad-maintain" to listOf(
                byId("s12-bad-maintain-show", "s12-bad-maintain-show"),
                byName("s12-bad-maintain-tracking", TRACKING),
                byId("s12-bad-maintain-copy", "s12-bad-maintain-copy"),
                byId("s12-bad-maintain-count", "s12-bad-maintain-count"),
            ),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val s12Titles = mapOf(
    "good-decoration" to "Ornaments hidden from AT",
    "good-badge" to "Repeated count hidden from AT",
    "good-visibility" to "Panel hidden from everyone",
    "bad-decoration-read" to "Ornaments read aloud",
    "bad-hidden-control" to "Button hidden with an ornament",
    "bad-opacity" to "Panel hidden by opacity",
    "bad-maintain" to "Panel hidden only from sight",
)
