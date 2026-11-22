// L3 (tree) and L4 (TalkBack walk) for C05 Accordion on Android.
// Spec: docs/specs/C05-accordion.md.
//
// Flutter passes `expanded` to Android only from Android 16 (API 36): there
// the header node has an expanded state (FL-261). Below it, the node has no
// expanded state and no expand or collapse action, which the tests assert
// there, so that they fail when that changes. CI's emulator is API 35 and
// the local one API 37, so each runs one side only.
package dev.fluttera11y.flutter_a11y_techniques

import android.os.Build
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
private const val SHIPPING = "Shipping"
private const val RETURNS = "Returns"
private const val SHIPPING_TEXT = "Orders ship in two days."
private const val SHIPPING_ACTION = "Track a parcel"

@RunWith(AndroidJUnit4::class)
class C05AccordionTest : TechniqueTest("C05") {
    private fun open(slug: String) = openExample(slug, By.desc(c05Titles.getValue(slug)), settleMillis = 300)

    /**
     * Opens a good example and scrolls its screen to the end, as a person
     * scrolls down to the example: each good example is a custom solution,
     * whose note above the example (docs/custom-solutions.md) can leave the
     * accordion below the view, on CI's 320 by 640 emulator all of it (in a
     * widget test at that size, with the test font, the first header starts
     * about 200 pixels below the screen). On a screen that does not scroll
     * nothing moves.
     */
    private fun openGood(slug: String) {
        open(slug)
        scrollToEnd()
    }

    /**
     * The bounds of [id] on the screen once they have stopped changing: the
     * same in two readings 250 ms apart, within 5 seconds (as C04's test).
     */
    private fun settledBounds(id: String): android.graphics.Rect {
        var last = android.graphics.Rect().also { node(id).getBoundsInScreen(it) }
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            Thread.sleep(250)
            val now = android.graphics.Rect().also { node(id).getBoundsInScreen(it) }
            if (now == last) return now
            last = now
        }
        throw AssertionError("$id: its bounds were still changing after 5 seconds")
    }

    private fun id(slug: String, key: String) = "c05-$slug-$key"

    /** "collapsed", "full", or "undefined" on Android 16 and later; null before. */
    private fun expandedState(node: AccessibilityNodeInfo): String? {
        if (Build.VERSION.SDK_INT < 36) return null
        return when (node.javaClass.getMethod("getExpandedState").invoke(node) as Int) {
            1 -> "collapsed"
            3 -> "full"
            0 -> "undefined"
            else -> "other"
        }
    }

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

    /**
     * The names of the example's nodes in tree order, from the first header
     * to the count. The screen is scrolled to its end first, so that the
     * count, below the view under a custom solution's note, is in the tree
     * with the headers (a node out of view is not).
     */
    private fun reading(): List<String> {
        scrollToEnd()
        val names = all().map { it.name().ifEmpty { it.text?.toString().orEmpty() } }.filter { it.isNotEmpty() }
        val start = names.indexOfFirst { it.startsWith(SHIPPING) }
        val end = names.indexOfFirst { it.startsWith("Presses: ") }
        assertTrue("the first header is in the tree: $names", start >= 0)
        assertTrue("the count comes last: $names", end > start)
        return names.subList(start, end)
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act (as in I01 and C03). */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /** The name of the node with input focus inside the app, or "(none)". */
    private fun focusName(): String =
        all().firstOrNull { it.isFocused && it.name().isNotEmpty() }?.name() ?: "(none)"

    /** Tab until [id] has keyboard focus; the first Tab can be used up leaving touch mode. */
    private fun tabTo(id: String) {
        for (i in 0 until 6) {
            key("TAB")
            if (revealed(id).isFocused) return
        }
        throw AssertionError("Tab did not reach $id")
    }

    private val good = listOf("good-material", "good-cupertino", "good-custom")

    /** The expanded state the header must show: [open] on Android 16 and later, nothing before. */
    private fun expectState(node: AccessibilityNodeInfo, open: Boolean, what: String) {
        if (Build.VERSION.SDK_INT >= 36) {
            assertEquals("$what expanded state", if (open) "full" else "collapsed", expandedState(node))
            // onExpand while closed, onCollapse while open.
            assertEquals("$what expand action", !open, hasAction(node, AccessibilityNodeInfo.ACTION_EXPAND))
            assertEquals("$what collapse action", open, hasAction(node, AccessibilityNodeInfo.ACTION_COLLAPSE))
        } else {
            // FL-261: before Android 16 Flutter gives the node no state and
            // no expand or collapse action.
            assertFalse("$what: no expand action before Android 16", hasAction(node, AccessibilityNodeInfo.ACTION_EXPAND))
            assertFalse("$what: no collapse action before Android 16", hasAction(node, AccessibilityNodeInfo.ACTION_COLLAPSE))
        }
    }

    @Test
    fun goodHeadersAreHeadingButtonsThatSayTheyExpand() {
        for (slug in good) {
            openGood(slug)
            for ((key, name) in listOf("shipping" to SHIPPING, "returns" to RETURNS)) {
                val node = node(id(slug, key))
                val what = "$slug $key"
                assertEquals("$what class", BUTTON, node.type())
                assertEquals("$what name", name, node.name())
                assertTrue("$what heading", node.isHeading)
                assertTrue("$what clickable", node.isClickable)
                assertTrue("$what focusable", node.isFocusable)
                // onTapHint: what TalkBack says a double tap does.
                assertEquals("$what click label", "expand", clickLabel(node))
                expectState(node, false, what)
            }
            // The two headers are the only controls but Back, and a closed
            // panel is not in the tree.
            assertEquals("$slug: clickable nodes but Back", 2, all().count { it.isClickable && it.name() != "Back" })
            assertFalse("$slug: closed panel", shown(SHIPPING_TEXT))
            assertEquals(listOf(SHIPPING, RETURNS), reading())
        }
    }

    @Test
    fun goodHeadersOpenByTheClickActionStraightAfterTheHeader() {
        // ACTION_CLICK is what TalkBack performs on a double tap.
        for (slug in good) {
            openGood(slug)
            val id = id(slug, "shipping")
            assertTrue("$slug click", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitFor("$slug: the click action opens Shipping") { shown(SHIPPING_TEXT) }
            waitFor("$slug: the click label says collapse") { clickLabel(node(id)) == "collapse" }
            expectState(node(id), true, "$slug shipping, open")
            expectState(node(id(slug, "returns")), false, "$slug returns, still closed")
            assertEquals(listOf(SHIPPING, SHIPPING_TEXT, SHIPPING_ACTION, RETURNS), reading())
            assertTrue("$slug click again", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitFor("$slug: a second click closes it") { !shown(SHIPPING_TEXT) }
            expectState(node(id), false, "$slug shipping, closed again")
        }
    }

    @Test
    fun goodHeadersOpenAndCloseByTheExpandAndCollapseActions() {
        // Android 16 and later only: before it the node has neither action
        // (FL-261), which expectState asserts.
        org.junit.Assume.assumeTrue("expand and collapse need Android 16", Build.VERSION.SDK_INT >= 36)
        for (slug in good) {
            openGood(slug)
            val id = id(slug, "shipping")
            assertTrue("$slug expand", node(id).performAction(AccessibilityNodeInfo.ACTION_EXPAND))
            waitFor("$slug: ACTION_EXPAND opens Shipping") { shown(SHIPPING_TEXT) }
            waitFor("$slug: then it can collapse") { hasAction(node(id), AccessibilityNodeInfo.ACTION_COLLAPSE) }
            assertTrue("$slug collapse", node(id).performAction(AccessibilityNodeInfo.ACTION_COLLAPSE))
            waitFor("$slug: ACTION_COLLAPSE closes it") { !shown(SHIPPING_TEXT) }
        }
    }

    @Test
    fun goodHeadersOpenByATap() {
        for (slug in good) {
            openGood(slug)
            // A person taps the header once it is in view and has stopped
            // moving (openGood scrolled to it).
            val r = settledBounds(id(slug, "shipping"))
            assertTrue("$slug tap", device.click(r.centerX(), r.centerY()))
            waitFor("$slug: a tap opens Shipping") { shown(SHIPPING_TEXT) }
        }
    }

    @Test
    fun goodHeadersAreReachedByTabAndOpenedByEnterAndBySpace() {
        for (slug in good) {
            for (name in listOf("ENTER", "SPACE")) {
                openGood(slug)
                val id = id(slug, "shipping")
                tabTo(id)
                key(name)
                waitFor("$slug: $name opens Shipping") { shown(SHIPPING_TEXT) }
                assertTrue("$slug: focus stays on the header after $name", revealed(id).isFocused)
                key(name)
                waitFor("$slug: $name again closes it") { !shown(SHIPPING_TEXT) }
            }
        }
    }

    @Test
    fun goodPanelsAreInTheFocusOrderOnlyWhileOpen() {
        for (slug in good) {
            openGood(slug)
            val shipping = id(slug, "shipping")
            tabTo(shipping)
            key("TAB")
            assertEquals("$slug: Tab after a closed Shipping", RETURNS, focusName())
            assertTrue(node(shipping).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitFor("$slug: Shipping opens") { shown(SHIPPING_TEXT) }
            tabTo(shipping)
            key("TAB")
            assertEquals("$slug: Tab after an open Shipping", SHIPPING_ACTION, focusName())
            key("TAB")
            assertEquals("$slug: then Returns", RETURNS, focusName())
        }
    }

    // Each bad example is asserted to have its named defect.

    @Test
    fun badNoStateHeadersHaveNoState() {
        open("bad-no-state")
        val id = id("bad-no-state", "shipping")
        assertEquals(BUTTON, node(id).type())
        assertTrue(node(id).isHeading)
        assertEquals("", clickLabel(node(id)))
        assertEquals("before", if (Build.VERSION.SDK_INT >= 36) "undefined" else null, expandedState(node(id)))
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        // The positive control: the click opened the section.
        waitFor("the click opens Shipping") { shown(SHIPPING_TEXT) }
        assertEquals("after", if (Build.VERSION.SDK_INT >= 36) "undefined" else null, expandedState(node(id)))
        assertFalse(hasAction(node(id), AccessibilityNodeInfo.ACTION_COLLAPSE))
    }

    @Test
    fun badHeadingOnButtonIsAHeadingButtonOnAndroid() {
        // The defect is on the web only (web_tests/c05_accordion.spec.js).
        open("bad-heading-on-button")
        val node = node(id("bad-heading-on-button", "shipping"))
        assertEquals(BUTTON, node.type())
        assertTrue(node.isHeading)
        expectState(node, false, "bad-heading-on-button")
    }

    @Test
    fun badNoHeadingHeadersAreNotHeadings() {
        open("bad-no-heading")
        for (key in listOf("shipping", "returns")) {
            val node = node(id("bad-no-heading", key))
            assertEquals(BUTTON, node.type())
            assertFalse("$key heading", node.isHeading)
            expectState(node, false, "bad-no-heading $key")
        }
        // No node of the example is a heading; the screen's own headings
        // ("Example") are above the first header.
        assertEquals(0, all().count { it.isHeading && (it.name() == SHIPPING || it.name() == RETURNS) })
    }

    @Test
    fun badHiddenPanelButtonsTakeFocusWhileClosed() {
        open("bad-hidden-panel")
        assertFalse("closed panel text", shown(SHIPPING_TEXT))
        assertFalse("closed panel button", shown(SHIPPING_ACTION))
        tabTo(id("bad-hidden-panel", "shipping"))
        key("TAB")
        assertEquals(RETURNS, focusName())
        // The next Tab goes to a hidden button, which has no node: the tree
        // still reports Returns as focused (the probe, android-keys.txt,
        // p02 and p14). What Enter then does tells the two apart: on
        // Returns it would open Returns; on the hidden button it presses
        // the button, and nothing opens.
        key("TAB")
        assertEquals(0, count("bad-hidden-panel"))
        key("ENTER")
        waitForCount("bad-hidden-panel", 1)
        assertFalse("Shipping still closed", shown(SHIPPING_TEXT))
        assertFalse("Returns still closed", shown("Return items within 30 days."))
    }

    @Test
    fun badHiddenPanelHeaderOpensWithEnter() {
        // The positive control for the test above: Enter on a header, sent
        // the same way, opens it and presses nothing.
        open("bad-hidden-panel")
        tabTo(id("bad-hidden-panel", "returns"))
        key("ENTER")
        waitFor("Enter opens Returns") { shown("Return items within 30 days.") }
        assertEquals(0, count("bad-hidden-panel"))
    }

    @Test
    fun badExpansionTileHeaderIsNoButtonAndHasNoState() {
        open("bad-expansion-tile")
        val header = all().first { it.name().startsWith(SHIPPING) && it.isClickable }
        // The state is the hint, which Android puts at the end of the name
        // (FL-039).
        assertEquals("$SHIPPING, Collapsed", header.name())
        assertEquals(VIEW, header.type())
        assertFalse(header.isHeading)
        assertEquals("Expand for more details", clickLabel(header))
        assertEquals(if (Build.VERSION.SDK_INT >= 36) "undefined" else null, expandedState(header))
        assertTrue(header.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitFor("the click opens Shipping") { shown(SHIPPING_TEXT) }
        val after = all().first { it.name().startsWith(SHIPPING) && it.isClickable }
        assertEquals("$SHIPPING, Expanded", after.name())
        assertEquals(VIEW, after.type())
        assertEquals(if (Build.VERSION.SDK_INT >= 36) "undefined" else null, expandedState(after))
    }

    @Test
    fun badCupertinoExpansionTileHeadersTakeNoKeyboardFocus() {
        for (name in listOf("ENTER", "SPACE")) {
            open("bad-cupertino-expansion-tile")
            var backFocused = false
            for (i in 0 until 6) {
                key("TAB")
                val header = all().first { it.name().startsWith(SHIPPING) }
                assertFalse("$name: Tab ${i + 1} gave the header focus", header.isFocused)
                if (named("Back").isFocused) { backFocused = true; break }
            }
            assertTrue("$name: Tab reached Back", backFocused)
            key(name)
            // Back acted: the positive control. The example is gone, unopened.
            waitFor("$name on Back leaves the example") { !anyWindowHas { it.name() == c05Titles.getValue("bad-cupertino-expansion-tile") } }
        }
    }

    @Test
    fun badCupertinoExpansionTileHeaderIsNoButtonAndHasNoState() {
        open("bad-cupertino-expansion-tile")
        val header = all().first { it.name().startsWith(SHIPPING) && it.isClickable }
        assertEquals(SHIPPING, header.name())
        assertEquals(VIEW, header.type())
        assertEquals(if (Build.VERSION.SDK_INT >= 36) "undefined" else null, expandedState(header))
        assertTrue(header.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitFor("the click opens Shipping") { shown(SHIPPING_TEXT) }
    }

    /**
     * L4. For each example: TalkBack focus goes to the Shipping header
     * (closed); then, with focus left there, the header's ACTION_CLICK, which
     * is what a double tap sends, and what TalkBack says on the change; then
     * focus goes to the panel's text, and back to the header (open). In the
     * probe, focus cleared and put back on the same header read nothing
     * (docs/evidence/probes/c05/README.md), so focus goes elsewhere first.
     * Each step logs a marker first; tool/talkback.py reads the speech
     * between markers from logcat. Skipped unless TalkBack is running.
     *
     * Two examples have no state that could be announced: `bad-no-state`
     * and `bad-cupertino-expansion-tile`. For them what TalkBack says on
     * the click is not checked, since a check that passes on silence would
     * also pass on a lost capture: an END marker before the click drops
     * whatever is said then. Their missing state is heard in the closed and
     * open readings instead. `bad-cupertino-expansion-tile` merges its
     * open panel's text into the header, so it has no panel node to move
     * to; focus goes to Back, whose reading is checked, before the header
     * is read again.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        val slugs = good + listOf("bad-no-state", "bad-heading-on-button", "bad-no-heading", "bad-expansion-tile",
            "bad-cupertino-expansion-tile")
        val silentOnChange = setOf("bad-no-state", "bad-cupertino-expansion-tile")
        for (slug in slugs) {
            val header: () -> AccessibilityNodeInfo = if (slug.endsWith("expansion-tile")) {
                { all().first { it.name().startsWith(SHIPPING) && it.isClickable } }
            } else {
                { node(id(slug, "shipping")) }
            }
            // A good example is scrolled to its end (openGood), before
            // TalkBack's own announcement of the screen is waited out.
            if (slug in good) openGood(slug) else open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            android.util.Log.i(talkBackTag, "FOCUS c05-$slug-closed")
            talkBackFocus("$slug closed", header)
            Thread.sleep(6_000)
            if (slug in silentOnChange) {
                android.util.Log.i(talkBackTag, "END $slug")
            } else {
                android.util.Log.i(talkBackTag, "FOCUS c05-$slug-activated")
            }
            assertTrue("$slug click", header().performAction(AccessibilityNodeInfo.ACTION_CLICK))
            Thread.sleep(6_000)
            assertTrue("$slug: the click opened Shipping", shown(SHIPPING_TEXT))
            if (slug == "bad-cupertino-expansion-tile") {
                android.util.Log.i(talkBackTag, "FOCUS c05-$slug-back")
                talkBackFocus("$slug back") { named("Back") }
            } else {
                android.util.Log.i(talkBackTag, "FOCUS c05-$slug-panel")
                talkBackFocus("$slug panel") {
                    all().first { it.name() == SHIPPING_TEXT || it.text?.toString() == SHIPPING_TEXT }
                }
            }
            Thread.sleep(6_000)
            android.util.Log.i(talkBackTag, "FOCUS c05-$slug-open")
            talkBackFocus("$slug open", header)
            Thread.sleep(6_000)
            android.util.Log.i(talkBackTag, "END $slug")
        }
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val c05Titles = mapOf(
    "good-material" to "Material accordion",
    "good-cupertino" to "Cupertino accordion",
    "good-custom" to "Accordion built from Semantics",
    "bad-no-state" to "Headers with no state",
    "bad-heading-on-button" to "Heading on the button",
    "bad-no-heading" to "Headers that are not headings",
    "bad-hidden-panel" to "Closed sections kept hidden",
    "bad-expansion-tile" to "Material ExpansionTile",
    "bad-cupertino-expansion-tile" to "CupertinoExpansionTile",
)
