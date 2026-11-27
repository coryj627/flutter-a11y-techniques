// L3 (tree) and L4 (TalkBack walk) for S09 Content grouping on Android.
// Spec: docs/specs/S09-content-grouping.md.
//
// Texts are found by their names (an identifier would be a node of its
// own); the controls and the status lines by their test identifiers. Each
// status line under an example says what its controls did.
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

private const val GROUP = "Kitchen light"
private const val TARGET = "App information"
private val FACTS = listOf("City" to "Boston", "Founded" to "1630")

@RunWith(AndroidJUnit4::class)
class S09ContentGroupingTest : TechniqueTest("S09") {
    /** Waits for the example's own title. */
    private fun open(slug: String) = openExample(slug, By.desc(s09Titles.getValue(slug)), settleMillis = 500)

    /** Presses a key on the emulator's keyboard and gives Flutter time to act (as in I01). */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /** Tab until [id] has keyboard focus; the first Tab can be used up leaving touch mode. */
    private fun tabTo(id: String) {
        for (i in 0 until 8) {
            key("TAB")
            if (revealed(id).isFocused) return
        }
        throw AssertionError("Tab did not reach $id")
    }

    /** What the status line [id] says: "Light: on". */
    private fun status(id: String): String = revealed(id).name()

    /** Waits up to 5 seconds for the status line [id] to say [expected]. */
    private fun waitForStatus(what: String, id: String, expected: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            // revealed() throws on a miss; a miss here is a reading to retry.
            val now = try { status(id) } catch (e: AssertionError) { null }
            if (now == expected) return
            Thread.sleep(100)
        }
        assertEquals(what, expected, status(id))
    }

    private val isEnd = { n: AccessibilityNodeInfo ->
        n.viewIdResourceName?.matches(Regex("s09-.*-(status|opens)")) == true
    }

    /**
     * The nodes of the example between the "Example" heading and its status
     * line (or the end of the screen), in the tree's order, that have a
     * name or a click action, each with its depth below the first of them.
     * The screen is read from the top, then scrolled a step at a time until
     * the status line is in the tree; each node is kept once.
     */
    private fun exampleNodes(): List<Pair<Int, AccessibilityNodeInfo>> {
        val nodes = mutableListOf<Pair<Int, AccessibilityNodeInfo>>()
        val keys = mutableSetOf<String>()
        fun collect(n: AccessibilityNodeInfo?, depth: Int) {
            if (n == null) return
            if (keys.add("${n.name()}|${n.type()}|${n.viewIdResourceName}")) nodes.add(depth to n)
            for (i in 0 until n.childCount) collect(n.getChild(i), depth + 1)
        }
        for (step in 0 until 8) {
            collect(automation.rootInActiveWindow, 0)
            if (nodes.any { isEnd(it.second) }) break
            val view = all().firstOrNull { it.isScrollable } ?: break
            if (!view.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) break
            Thread.sleep(500)
        }
        val start = nodes.indexOfFirst { it.second.name() == "Example" }
        assertTrue("the Example heading", start >= 0)
        val end = nodes.indexOfFirst { isEnd(it.second) }
        val list = nodes.subList(start + 1, if (end < 0) nodes.size else end)
            .filter { it.second.name().isNotEmpty() || it.second.hasClickAction() }
        val base = list.minOfOrNull { it.first } ?: 0
        return list.map { (it.first - base) to it.second }
    }

    private fun describe(entry: Pair<Int, AccessibilityNodeInfo>): String {
        val (depth, n) = entry
        return "  ".repeat(depth) + listOfNotNull(
            n.name(),
            n.type().substringAfterLast('.'),
            if (n.isClickable) "clickable" else null,
        ).joinToString(" | ")
    }

    private val controls = mapOf(
        "good-named-group" to mapOf(
            "s09-good-named-group-on" to ("s09-good-named-group-status" to "Light: on"),
            "s09-good-named-group-off" to ("s09-good-named-group-status" to "Light: off"),
        ),
        "good-tap-target" to mapOf("s09-good-tap-target-info" to ("s09-good-tap-target-opens" to "Opens: 1")),
    )

    @Test
    fun goodMergedFactsHasEachLabelAndValueAsOneNode() {
        open("good-merged-facts")
        assertEquals(FACTS.map { (l, v) -> "$l\n$v | View" }, exampleNodes().map(::describe))
        assertEquals("no clickable node but Back", 0, all().count { it.isClickable && it.name() != "Back" })
    }

    @Test
    fun goodCupertinoHasEachRowAsOneNode() {
        open("good-cupertino")
        assertEquals(FACTS.map { (l, v) -> "$l\n$v | View" }, exampleNodes().map(::describe))
        assertEquals("no clickable node but Back", 0, all().count { it.isClickable && it.name() != "Back" })
    }

    @Test
    fun goodNamedGroupIsANodeNamedByTheQuestionHoldingTheButtons() {
        open("good-named-group")
        assertEquals(
            listOf("$GROUP | View", "  On | Button | clickable", "  Off | Button | clickable"),
            exampleNodes().map(::describe),
        )
        val group = all().single { it.name() == GROUP }
        assertEquals(2, group.childCount)
        assertEquals(listOf("On", "Off"), (0 until group.childCount).map { group.getChild(it).name() })
        // Nothing tells TalkBack what the group is (FL-320): no container
        // title, which Android 14 added "to group together related
        // controls, similar to HTML fieldset", and no pane title. Written
        // to fail if Flutter starts setting either.
        if (Build.VERSION.SDK_INT >= 34) assertTrue((group.containerTitle ?: "").isEmpty())
        assertTrue((group.paneTitle ?: "").isEmpty())
        // The buttons carry nothing of the question themselves.
        for (id in listOf("s09-good-named-group-on", "s09-good-named-group-off")) {
            val b = node(id)
            for (text in listOf(b.name(), b.hintText ?: "", b.stateDescription ?: "")) {
                assertFalse("$id: $text", text.toString().contains(GROUP))
            }
        }
    }

    @Test
    fun goodTapTargetIsOneButtonNamedByItsText() {
        open("good-tap-target")
        assertEquals(listOf("$TARGET | Button | clickable"), exampleNodes().map(::describe))
    }

    @Test
    fun eachControlDoesItsOwnActionByTheClickActionATapAndTabThenEnter() {
        for ((slug, list) in controls) {
            for ((id, expected) in list) {
                val (statusId, after) = expected
                // The click action: what TalkBack's double tap performs.
                open(slug)
                assertFalse("$slug before", status(statusId) == after)
                assertTrue("$id click", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForStatus("$slug: the click action on $id", statusId, after)
                // A tap at its centre.
                open(slug)
                val r = android.graphics.Rect().also { node(id).getBoundsInScreen(it) }
                device.click(r.centerX(), r.centerY())
                waitForStatus("$slug: a tap on $id", statusId, after)
                // Tab to it, then Enter.
                open(slug)
                tabTo(id)
                key("ENTER")
                waitForStatus("$slug: Tab then Enter on $id", statusId, after)
            }
        }
    }

    @Test
    fun badSplitFactsReadsBothLabelsBeforeBothValues() {
        open("bad-split-facts")
        assertEquals(
            listOf("City | View", "Founded | View", "Boston | View", "1630 | View"),
            exampleNodes().map(::describe),
        )
    }

    @Test
    fun badMergedGroupIsOneButtonWhoseClickTurnsTheLightOn() {
        open("bad-merged-group")
        assertEquals(listOf("$GROUP\nOn\nOff | Button | clickable"), exampleNodes().map(::describe))
        assertEquals("no node named Off", 0, all().count { it.name() == "Off" })
        val status = "s09-bad-merged-group-status"
        // The keyboard still reaches Off's own focus: the merged node takes
        // two Tab stops, On's focus and then Off's, as in the probe. Tab
        // until it has focus (On's; the first Tab can be used up leaving
        // touch mode), then once more, to Off's.
        tabTo("s09-bad-merged-group-light")
        key("TAB")
        assertTrue("still on the merged node", revealed("s09-bad-merged-group-light").isFocused)
        key("ENTER")
        waitForStatus("bad-merged-group: three Tabs then Enter", status, "Light: off")
        // What TalkBack's double tap performs, on the one node, is On.
        assertTrue(node("s09-bad-merged-group-light").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForStatus("bad-merged-group: the click action", status, "Light: on")
    }

    /**
     * L4. Moves TalkBack focus to each part of each example and logs
     * markers; tool/talkback.py reads the speech from logcat and judges the
     * walk whole. For the named group, focus goes to the question and then
     * to each button, and in a second pass straight from the "Example"
     * heading to "On", as when a person lands on the button without passing
     * the question. Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val byName = { marker: String, name: String -> Stop(marker) { all().single { it.name() == name } } }
        val byId = { marker: String, id: String -> Stop(marker) { node(id) } }
        val facts = { slug: String ->
            FACTS.mapIndexed { i, (l, v) -> byName("s09-$slug-fact${i + 1}", "$l\n$v") }
        }
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-merged-facts" to facts("good-merged-facts"),
            "good-cupertino" to facts("good-cupertino"),
            "good-named-group" to listOf(
                byName("s09-good-named-group-group", GROUP),
                byId("s09-good-named-group-on", "s09-good-named-group-on"),
                byId("s09-good-named-group-off", "s09-good-named-group-off"),
                byName("s09-good-named-group-heading", "Example"),
                byId("s09-good-named-group-on-direct", "s09-good-named-group-on"),
            ),
            "good-tap-target" to listOf(byId("s09-good-tap-target-info", "s09-good-tap-target-info")),
            "bad-split-facts" to listOf(
                byName("s09-bad-split-facts-city", "City"),
                byName("s09-bad-split-facts-founded", "Founded"),
                byName("s09-bad-split-facts-boston", "Boston"),
                byName("s09-bad-split-facts-1630", "1630"),
            ),
            "bad-merged-group" to listOf(byId("s09-bad-merged-group-light", "s09-bad-merged-group-light")),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val s09Titles = mapOf(
    "good-merged-facts" to "Each label merged with its value",
    "good-cupertino" to "Cupertino rows, each one element",
    "good-named-group" to "Buttons in a group named by its question",
    "good-tap-target" to "Icon and text as one button",
    "bad-split-facts" to "Labels and values in separate rows",
    "bad-merged-group" to "Question and buttons merged",
)
