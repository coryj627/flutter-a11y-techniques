// L3 (tree) and L4 (TalkBack walk) for C18 Card on Android.
// Spec: docs/specs/C18-card.md.
//
// A card's parts are found by their names: the heading and the text have no
// identifiers (an identifier would be a node of its own), and the controls
// by their test identifiers. Each count under a card says which action ran.
package dev.fluttera11y.flutter_a11y_techniques

import android.text.Spanned
import android.text.style.URLSpan
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
private const val IMAGE = "android.widget.ImageView"
private const val TRAIL = "Ridge trail"
private const val TEXT = "A 6 km climb with a view."
private const val PICTURE = "Sunrise over the valley"
private const val CARD = "$TRAIL\n$TEXT"
private const val DESTINATION = "Card"

@RunWith(AndroidJUnit4::class)
class C18CardTest : TechniqueTest("C18") {
    /** Waits for the example's own title, then for the picture to decode. */
    private fun open(slug: String) = openExample(slug, By.desc(c18Titles.getValue(slug)), settleMillis = 500)

    /** The number a count shows: 2 for "Saves: 2". */
    private fun countOf(id: String): Int = revealed(id).name().substringAfter(": ").toInt()

    /** Waits up to 5 seconds for every count in [expected] to show its number. */
    private fun waitForCounts(what: String, expected: Map<String, Int>) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && expected.any { (id, n) -> countOf(id) != n }) Thread.sleep(100)
        for ((id, n) in expected) assertEquals("$what: $id", n, countOf(id))
    }

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

    /**
     * The nodes of the example between the "Example" heading and its first
     * count, in the tree's order, that have a name: what TalkBack moves
     * through in the card.
     */
    private fun cardNodes(): List<AccessibilityNodeInfo> {
        // A node out of view is not in the tree, and on CI's 320 by 640
        // emulator the card's end can be below the view. The screen is read
        // from the top, then scrolled a step at a time until a count is in
        // the tree; each node is kept once, in the order first seen.
        val isEnd = { n: AccessibilityNodeInfo ->
            n.viewIdResourceName?.matches(Regex("c18-.*-(saves|shares|opens)")) == true
        }
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        val keys = mutableSetOf<String>()
        for (step in 0 until 8) {
            for (n in all()) {
                if (keys.add("${n.name()}|${n.type()}|${n.viewIdResourceName}")) nodes.add(n)
            }
            if (nodes.any(isEnd) || nodes.any { it.name() == "Read more" }) break
            val view = all().firstOrNull { it.isScrollable } ?: break
            if (!view.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) break
            Thread.sleep(500)
        }
        val start = nodes.indexOfFirst { it.name() == "Example" }
        val end = nodes.indexOfFirst(isEnd)
        assertTrue("the Example heading", start >= 0)
        return nodes.subList(start + 1, if (end < 0) nodes.size else end).filter { it.name().isNotEmpty() }
    }

    private fun describe(n: AccessibilityNodeInfo): String = listOfNotNull(
        n.name(),
        n.type().substringAfterLast('.'),
        if (n.isHeading) "heading" else null,
        if (n.isClickable) "clickable" else null,
    ).joinToString(" | ")

    private fun urls(node: AccessibilityNodeInfo): List<String> {
        val desc = node.contentDescription as? Spanned ?: return emptyList()
        return desc.getSpans(0, desc.length, URLSpan::class.java).map { it.url }
    }

    private val controls = mapOf(
        "good-material" to mapOf(
            "c18-good-material-save" to "c18-good-material-saves",
            "c18-good-material-share" to "c18-good-material-shares",
        ),
        "good-tappable" to mapOf("c18-good-tappable-card" to "c18-good-tappable-opens"),
    )

    @Test
    fun goodMaterialHasEachPartAsANodeOfItsOwn() {
        open("good-material")
        assertEquals(
            listOf(
                "$TRAIL | View | heading",
                "$TEXT | View",
                "$PICTURE | ImageView",
                "Save $TRAIL | Button | clickable",
                "Share $TRAIL | Button | clickable",
            ),
            cardNodes().map(::describe),
        )
    }

    @Test
    fun goodTappableIsOneButtonNamedByItsTextAndNotAHeading() {
        open("good-tappable")
        assertEquals(listOf("$CARD | Button | clickable"), cardNodes().map(::describe))
        val card = node("c18-good-tappable-card")
        assertEquals(BUTTON, card.type())
        assertFalse(card.isHeading)
    }

    @Test
    fun goodCupertinoHasAHeadingTheTextAndThePictureAndNoControl() {
        open("good-cupertino")
        assertEquals(
            listOf("$TRAIL | View | heading", "$TEXT | View", "$PICTURE | ImageView"),
            cardNodes().map(::describe),
        )
        assertEquals("no clickable node but Back", 0, all().count { it.isClickable && it.name() != "Back" })
    }

    @Test
    fun eachControlIsActivatedAloneByTheClickActionATapAndTabThenEnter() {
        for ((slug, list) in controls) {
            val zero = list.values.associateWith { 0 }
            for ((id, count) in list) {
                // The click action: what TalkBack's double tap performs.
                open(slug)
                waitForCounts("$slug before", zero)
                assertTrue("$id click", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForCounts("$slug: the click action on $id", zero + (count to 1))
                // A tap at its centre.
                open(slug)
                val r = android.graphics.Rect().also { node(id).getBoundsInScreen(it) }
                device.click(r.centerX(), r.centerY())
                waitForCounts("$slug: a tap on $id", zero + (count to 1))
                // Tab to it, then Enter.
                open(slug)
                tabTo(id)
                key("ENTER")
                waitForCounts("$slug: Tab then Enter on $id", zero + (count to 1))
            }
        }
    }

    @Test
    fun badDefaultContainerIsOneHeadingNodeHoldingTheButton() {
        open("bad-default-container")
        assertEquals(
            listOf("$CARD | View | heading", "Save $TRAIL | Button | clickable"),
            cardNodes().map(::describe),
        )
        val heading = all().single { it.name() == CARD }
        assertTrue(heading.isHeading)
        assertEquals("the button is the heading node's child", 1, heading.childCount)
        assertEquals("Save $TRAIL", heading.getChild(0).name())
        assertEquals(0, all().count { it.name() == TRAIL })
        // Positive control: the button inside still works.
        assertTrue(node("c18-bad-default-container-save").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCounts("bad-default-container", mapOf("c18-bad-default-container-saves" to 1))
    }

    @Test
    fun badHeadingButtonIsAButtonAndAHeadingOnAndroid() {
        // The defect is on the web (FL-268); Android keeps both.
        open("bad-heading-button")
        val card = node("c18-bad-heading-button-card")
        assertEquals(BUTTON, card.type())
        assertTrue(card.isHeading)
        assertEquals(CARD, card.name())
        assertTrue(card.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCounts("bad-heading-button", mapOf("c18-bad-heading-button-opens" to 1))
    }

    @Test
    fun badInkWellIsNotAButton() {
        open("bad-ink-well")
        val card = node("c18-bad-ink-well-card")
        assertEquals(VIEW, card.type())
        assertEquals(CARD, card.name())
        assertTrue("clickable", card.isClickable)
        // Everything but the role works: the click action, and Tab and Enter.
        assertTrue(card.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCounts("bad-ink-well: the click action", mapOf("c18-bad-ink-well-opens" to 1))
        open("bad-ink-well")
        tabTo("c18-bad-ink-well-card")
        key("ENTER")
        waitForCounts("bad-ink-well: Tab then Enter", mapOf("c18-bad-ink-well-opens" to 1))
    }

    @Test
    fun badReadMoreIsALinkNamedReadMoreBesideTheHeading() {
        open("bad-read-more")
        assertEquals(
            listOf("$TRAIL | View | heading", "$TEXT | View", "Read more | View | clickable"),
            cardNodes().map(::describe),
        )
        val link = node("c18-bad-read-more-link")
        assertEquals(listOf("#/t/C18"), urls(link))
        assertFalse(link.name().contains(TRAIL))
        assertFalse((link.hintText ?: "").contains(TRAIL))
        assertFalse((link.stateDescription ?: "").contains(TRAIL))
        // The link and the heading are not parent and child.
        val heading = all().single { it.name() == TRAIL }
        assertEquals(0, heading.childCount)
        assertEquals(0, link.childCount)
        // Positive control: it is a working link.
        assertTrue(link.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !anyWindowHas { it.name() == DESTINATION }) Thread.sleep(100)
        assertTrue("the technique's page opens", anyWindowHas { it.name() == DESTINATION })
    }

    /**
     * L4. Moves TalkBack focus to each part of each card and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running.
     */
    @Test
    fun talkBackWalk() {
        val byName = { marker: String, name: String -> Stop(marker) { all().single { it.name() == name } } }
        val byId = { marker: String, id: String -> Stop(marker) { node(id) } }
        fun parts(slug: String) = listOf(
            byName("c18-$slug-heading", TRAIL),
            byName("c18-$slug-text", TEXT),
            byName("c18-$slug-picture", PICTURE),
        )
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-material" to parts("good-material") + listOf(
                byId("c18-good-material-save", "c18-good-material-save"),
                byId("c18-good-material-share", "c18-good-material-share"),
            ),
            "good-tappable" to listOf(byId("c18-good-tappable-card", "c18-good-tappable-card")),
            "good-cupertino" to parts("good-cupertino"),
            "bad-default-container" to listOf(
                byName("c18-bad-default-container-card", CARD),
                byId("c18-bad-default-container-save", "c18-bad-default-container-save"),
            ),
            "bad-heading-button" to listOf(byId("c18-bad-heading-button-card", "c18-bad-heading-button-card")),
            "bad-ink-well" to listOf(byId("c18-bad-ink-well-card", "c18-bad-ink-well-card")),
            "bad-read-more" to listOf(
                byName("c18-bad-read-more-heading", TRAIL),
                byName("c18-bad-read-more-text", TEXT),
                byId("c18-bad-read-more-link", "c18-bad-read-more-link"),
            ),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val c18Titles = mapOf(
    "good-material" to "Material card with separate parts",
    "good-tappable" to "Material card that is one control",
    "good-cupertino" to "Card in Cupertino style",
    "bad-default-container" to "Card left as one container",
    "bad-heading-button" to "Tappable card with a heading",
    "bad-ink-well" to "Tappable card with an InkWell",
    "bad-read-more" to "Card with a \"Read more\" link",
)
