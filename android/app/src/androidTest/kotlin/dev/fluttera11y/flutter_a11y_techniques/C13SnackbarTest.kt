// L3 (tree) and L4 (TalkBack) for C13 Snackbar and transient messages on
// Android. Spec: docs/specs/C13-snackbar.md.
//
// Every example's button is pressed with the click action, which moves no
// focus, so that what follows is the message's own doing. Keys are sent with
// `input keyevent`; they move Flutter's keyboard focus, which the tree reads
// as a node's focused state (they do not turn its focus highlight on,
// FL-433, which is not what is measured here). Every check that a key did
// nothing sends it alone, and shows in the same launch that the same path
// acts.
package dev.fluttera11y.flutter_a11y_techniques

import android.util.Log
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"

@RunWith(AndroidJUnit4::class)
class C13SnackbarTest : TechniqueTest("C13") {
    private fun open(slug: String) = openExample(slug, By.desc(c13Titles.getValue(slug)), settleMillis = 500)

    private val message = mapOf(
        "good-action" to "Message archived",
        "good-message" to "Draft saved",
        "good-banner" to "You are offline.",
        "bad-action-times-out" to "Message archived",
        "bad-only-in-message" to "Booked. Code: K7Q2",
        "bad-inline-banner" to "You are offline.",
    )

    private val line = mapOf(
        "good-action" to ("Archived: 0" to "Archived: 1"),
        "good-message" to ("Drafts saved: 0" to "Drafts saved: 1"),
        "good-banner" to ("Status: online" to "Status: offline"),
        "bad-action-times-out" to ("Archived: 0" to "Archived: 1"),
        "bad-only-in-message" to ("Bookings: 0" to "Bookings: 1"),
        "bad-inline-banner" to ("Status: online" to "Status: offline"),
    )

    /** The first node of the app named [name], or null. */
    private fun maybe(name: String): AccessibilityNodeInfo? = all().firstOrNull { it.name() == name }

    /** The node of the example's message: the node named by it. */
    private fun messageNode(slug: String) = maybe(message.getValue(slug))

    private fun lineText(slug: String) = node("c13-$slug-count").name()

    /** Presses the example's button with the click action and waits for its line and its message. */
    private fun press(slug: String) {
        assertTrue("$slug click", node("c13-$slug-show").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && (lineText(slug) != line.getValue(slug).second || messageNode(slug) == null)) {
            Thread.sleep(100)
        }
        assertEquals("$slug line", line.getValue(slug).second, lineText(slug))
        assertNotNull("$slug message shown", messageNode(slug))
    }

    /** Waits until the message has gone, at most [max] ms; how long it took, or null. */
    private fun goneAfter(slug: String, max: Long): Long? {
        val start = System.currentTimeMillis()
        while (System.currentTimeMillis() - start < max) {
            if (messageNode(slug) == null) return System.currentTimeMillis() - start
            Thread.sleep(100)
        }
        return null
    }

    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /** The name of the node with input focus, by its identifier or its name; "(none)" if none has it. */
    private fun focused(): String {
        val f = all().lastOrNull { it.isFocused } ?: return "(none)"
        return f.viewIdResourceName?.takeIf { it.isNotEmpty() } ?: f.name()
    }

    /** Tab until the node named [name] has focus; the first Tab can be used up leaving touch mode. */
    private fun tabTo(name: String) {
        for (i in 0 until 8) {
            if (focused() == name) return
            key("TAB")
        }
        assertEquals("Tab did not reach $name", name, focused())
    }

    @Test
    fun eachMessageIsAPoliteLiveRegionWithItsWordsAndTheDismissAction() {
        for (slug in listOf("good-action", "good-message", "good-banner", "bad-action-times-out", "bad-only-in-message")) {
            open(slug)
            assertTrue("$slug: no live region before", all().none { it.liveRegion != View.ACCESSIBILITY_LIVE_REGION_NONE })
            press(slug)
            val live = all().filter { it.liveRegion != View.ACCESSIBILITY_LIVE_REGION_NONE }
            assertEquals("$slug: one live region", 1, live.size)
            assertEquals("$slug: polite", View.ACCESSIBILITY_LIVE_REGION_POLITE, live.single().liveRegion)
            assertEquals("$slug: its words", message.getValue(slug), live.single().name())
            assertTrue("$slug: the dismiss action", live.single().actionList.any { it.id == AccessibilityNodeInfo.ACTION_DISMISS })
        }
    }

    @Test
    fun goodActionHasUndoAndCloseButtonsAndTheBannerGoOnline() {
        open("good-action")
        press("good-action")
        for (name in listOf("Undo", "Close")) {
            val n = maybe(name)
            assertNotNull(name, n)
            assertEquals("$name class", BUTTON, n!!.type())
            assertTrue("$name clickable", n.isClickable)
        }
        open("good-banner")
        press("good-banner")
        val go = maybe("Go online")
        assertNotNull(go)
        assertEquals(BUTTON, go!!.type())
    }

    @Test
    fun theDismissActionTakesTheMessageAway() {
        for (slug in listOf("good-action", "good-banner")) {
            open(slug)
            press(slug)
            assertTrue("$slug dismiss", messageNode(slug)!!.performAction(AccessibilityNodeInfo.ACTION_DISMISS))
            assertNotNull("$slug: gone after the dismiss action", goneAfter(slug, 3_000))
        }
    }

    @Test
    fun theMessagesWithAnActionStay() {
        for (slug in listOf("good-action", "good-banner")) {
            open(slug)
            press(slug)
            assertNull("$slug: still shown 10 s later", goneAfter(slug, 10_000))
        }
    }

    @Test
    fun goodMessageGoesAndWhatItSaidStaysOnThePage() {
        open("good-message")
        press("good-message")
        val gone = goneAfter("good-message", 12_000)
        assertNotNull("gone", gone)
        assertTrue("gone within 6 s of being seen, took $gone ms", gone!! < 6_000)
        assertEquals("Drafts saved: 1", lineText("good-message"))
    }

    @Test
    fun keysReachUndoAndCloseAndEnterActs() {
        open("good-action")
        press("good-action")
        tabTo("Undo")
        key("ENTER")
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && lineText("good-action") != "Archived: 0") Thread.sleep(100)
        assertEquals("Archived: 0", lineText("good-action"))
        assertNotNull("gone after Undo", goneAfter("good-action", 3_000))

        open("good-action")
        press("good-action")
        tabTo("Close")
        key("ENTER")
        assertNotNull("gone after Close", goneAfter("good-action", 3_000))
        assertEquals("Close undoes nothing", "Archived: 1", lineText("good-action"))
    }

    // FL-291.
    @Test
    fun escapeLeavesTheMessageAndEnterInTheSameLaunchActs() {
        for ((slug, action) in listOf("good-action" to "Undo", "good-banner" to "Go online")) {
            open(slug)
            press(slug)
            tabTo(action)
            key("ESCAPE")
            Thread.sleep(1_000)
            assertNotNull("$slug: still shown after Escape", messageNode(slug))
            assertEquals("$slug: focus stays after Escape", action, focused())
            assertEquals("$slug: Escape acted on nothing", line.getValue(slug).second, lineText(slug))
            key("ENTER")
            val end = System.currentTimeMillis() + 5_000
            while (System.currentTimeMillis() < end && lineText(slug) != line.getValue(slug).first) Thread.sleep(100)
            assertEquals("$slug: Enter acted", line.getValue(slug).first, lineText(slug))
        }
    }

    // FL-290: the time limit, with nothing to change it.
    @Test
    fun badActionTimesOutUndoGoesWithTheMessage() {
        open("bad-action-times-out")
        press("bad-action-times-out")
        assertNotNull("Undo shown", maybe("Undo"))
        val gone = goneAfter("bad-action-times-out", 12_000)
        assertNotNull("gone", gone)
        assertTrue("gone within 6 s of being seen, took $gone ms", gone!! < 6_000)
        assertNull("Undo gone", maybe("Undo"))
        assertEquals("Archived: 1", lineText("bad-action-times-out"))
    }

    // FL-292: written to fail if focus goes anywhere else.
    @Test
    fun badActionTimesOutGoesWithKeyboardFocusOnUndo() {
        open("bad-action-times-out")
        press("bad-action-times-out")
        tabTo("Undo")
        assertNotNull("gone with focus on Undo", goneAfter("bad-action-times-out", 12_000))
        Thread.sleep(500)
        val after = focused()
        Log.i("C13KEYS", "focus after Undo went: $after")
        assertEquals("focus after Undo went", C13_FOCUS_AFTER_TIMEOUT, after)
    }

    @Test
    fun badOnlyInMessageTheCodeGoesAndIsNowhereElse() {
        open("bad-only-in-message")
        assertTrue("no code before", all().none { it.name().contains("K7Q2") })
        press("bad-only-in-message")
        val gone = goneAfter("bad-only-in-message", 12_000)
        assertNotNull("gone", gone)
        assertTrue("gone within 6 s of being seen, took $gone ms", gone!! < 6_000)
        assertTrue("the code is nowhere", all().none { it.name().contains("K7Q2") || it.text?.contains("K7Q2") == true })
        assertEquals("Bookings: 1", lineText("bad-only-in-message"))
    }

    // FL-295.
    @Test
    fun badInlineBannerIsNoLiveRegionAndItsResultLineInTheSameLaunchIs() {
        open("bad-inline-banner")
        press("bad-inline-banner")
        Thread.sleep(2_000)
        assertTrue("no live region", all().none { it.liveRegion != View.ACCESSIBILITY_LIVE_REGION_NONE })
        assertTrue("no dismiss action", all().none { n -> n.actionList.any { it.id == AccessibilityNodeInfo.ACTION_DISMISS } })
        // The positive control, in the same launch, read the same way.
        assertTrue("Go online click", maybe("Go online")!!.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        assertEquals("Go online's result line is one", listOf("You are online."), waitLiveRegions(listOf("You are online.")))
    }

    /** Waits up to 5 seconds for the names of the live regions to be [expected]; returns them. */
    private fun waitLiveRegions(expected: List<String>): List<String> {
        fun now() = all().filter { it.liveRegion != View.ACCESSIBILITY_LIVE_REGION_NONE }.map { it.name() }
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && now() != expected) Thread.sleep(100)
        return now()
    }

    // What an action did is told by the example's result line: a polite
    // live region, with no node while empty, which then stays; the status
    // line is no live region.
    @Test
    fun whatAnActionDidIsAPoliteLiveRegionResultLine() {
        for ((slug, action, said) in listOf(
            Triple("good-action", "Undo", "Archive undone. Archived: 0"),
            Triple("good-banner", "Go online", "You are online."),
            Triple("bad-action-times-out", "Undo", "Archive undone. Archived: 0"),
        )) {
            open(slug)
            assertTrue("$slug: no result node while empty", all().none { it.viewIdResourceName == "c13-$slug-result" })
            press(slug)
            assertTrue("$slug $action click", maybe(action)!!.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            assertEquals("$slug: told", listOf(said), waitLiveRegions(listOf(said)))
            val result = node("c13-$slug-result")
            assertEquals("$slug: polite", View.ACCESSIBILITY_LIVE_REGION_POLITE, result.liveRegion)
            assertEquals("$slug: its words", said, result.name())
            assertEquals("$slug line", line.getValue(slug).first, lineText(slug))
            assertEquals("$slug: the line is no live region", View.ACCESSIBILITY_LIVE_REGION_NONE, node("c13-$slug-count").liveRegion)
            Thread.sleep(6_000)
            assertEquals("$slug: it stays", said, node("c13-$slug-result").name())
        }
    }

    /**
     * L4. Skipped unless TalkBack is running. For each example: TalkBack
     * focus is parked on the example's line, the button is pressed with the
     * click action, and what TalkBack then says is logged as
     * "c13-<slug>-announced" (for bad-inline-banner, the silence and then
     * focus moved to its button, in that row). For the messages that stay, focus is then
     * moved to each of the message's nodes. tool/talkback.py reads the
     * speech between the markers from logcat.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        for (slug in c13Titles.keys) {
            openExampleInAnyWindow(slug) { it.name() == c13Titles.getValue(slug) }
            Thread.sleep(8_000)
            talkBackFocus("$slug line") { nodeInAnyWindow("c13-$slug-count") }
            Thread.sleep(3_000)
            Log.i(talkBackTag, "FOCUS c13-$slug-announced")
            assertTrue("$slug click", nodeInAnyWindow("c13-$slug-show").performAction(AccessibilityNodeInfo.ACTION_CLICK))
            Thread.sleep(5_000)
            if (slug == "bad-inline-banner") {
                // Its silence is the five seconds above. The strict judge
                // (tool/talkback.py, walk_strictly) counts a row with
                // nothing spoken as a capture shown to be short, so the row
                // ends, within its marker, with TalkBack focus moved to the
                // page's button, which must be read: the capture was live
                // in the same row, after the silence.
                talkBackFocus("$slug button") { nodeInAnyWindow("c13-$slug-show") }
                Thread.sleep(3_000)
            }
            val stops = when (slug) {
                "good-action" -> listOf("message" to "Message archived", "undo" to "Undo", "close" to "Close")
                "good-banner" -> listOf("message" to "You are offline.", "go-online" to "Go online")
                "bad-inline-banner" -> listOf("message" to "You are offline.")
                else -> emptyList()
            }
            for ((part, name) in stops) {
                Log.i(talkBackTag, "FOCUS c13-$slug-$part")
                talkBackFocus("$slug $part") { anyWindowNode { it.name() == name } }
                Thread.sleep(4_000)
            }
            // What the action did, announced: focus parked on the line again,
            // the action pressed with the click action. For bad-inline-banner
            // this is also the positive control of its silence, in the same
            // launch.
            val acted = when (slug) {
                "good-action" -> "Undo"
                "good-banner", "bad-inline-banner" -> "Go online"
                else -> null
            }
            if (acted != null) {
                talkBackFocus("$slug line") { nodeInAnyWindow("c13-$slug-count") }
                Thread.sleep(3_000)
                Log.i(talkBackTag, "FOCUS c13-$slug-done-announced")
                assertTrue("$slug $acted click", anyWindowNode { it.name() == acted }.performAction(AccessibilityNodeInfo.ACTION_CLICK))
                Thread.sleep(5_000)
            }
            Log.i(talkBackTag, "END $slug")
        }
    }

    private fun anyWindowNode(match: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo {
        val end = System.currentTimeMillis() + 8_000
        while (true) {
            for (w in automation.windows) {
                val found = mutableListOf<AccessibilityNodeInfo>()
                fun walk(n: AccessibilityNodeInfo?) {
                    if (n == null) return
                    if (match(n)) found.add(n)
                    for (i in 0 until n.childCount) walk(n.getChild(i))
                }
                walk(w.root)
                found.firstOrNull()?.let { return it }
            }
            if (System.currentTimeMillis() > end) throw AssertionError("no such node in any window")
            Thread.sleep(250)
        }
    }
}

/**
 * Where keyboard focus is after a SnackBar goes with it on its action
 * (FL-292): back on the button that showed it, as on the web. In the widget
 * tests no node has it.
 */
private const val C13_FOCUS_AFTER_TIMEOUT = "c13-bad-action-times-out-show"

private val c13Titles = mapOf(
    "good-action" to "SnackBar with an action",
    "good-message" to "SnackBar whose news is also on the page",
    "good-banner" to "MaterialBanner",
    "bad-action-times-out" to "Action that times out",
    "bad-only-in-message" to "Information only in a SnackBar",
    "bad-inline-banner" to "Banner put in the page",
)
