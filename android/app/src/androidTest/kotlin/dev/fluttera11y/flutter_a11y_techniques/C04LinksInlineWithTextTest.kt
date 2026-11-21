// L3 (tree) and L4 (TalkBack walk) for C04 Links inline with text on
// Android. Spec: docs/specs/C04-links-inline-with-text.md.
//
// Each sentence has two links, to C04's page ("Links inline with text") and
// to C03's ("Stand-alone link"). A link with an address is an
// android.view.View whose content description carries a URLSpan with it
// (FL-220); one without is an android.widget.Button (FL-032). "Followed
// once" is checked by one Back bringing the example back.
//
// The colour and underline of a link are drawn, not exposed, so this layer
// cannot see bad-colour-only's defect; the widget tests assert it.
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Rect
import android.text.Spanned
import android.text.style.URLSpan
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
private const val VIEW = "android.view.View"

/** A link of the sentence: its name, its address, and its page's title. */
private data class Link(val name: String, val address: String, val page: String)

private val LINKS = listOf(
    Link("links in text", "#/t/C04", "Links inline with text"),
    Link("stand-alone links", "#/t/C03", "Stand-alone link"),
)

/** The words and links of the two-link sentence, in reading order. */
private val SENTENCE = listOf("Read about ", "links in text", " and ", "stand-alone links", " first.")

/** The page that only bad-text-span opens (TextSpanPage). */
private const val TEXT_SPAN_PAGE = "About links in text"

@RunWith(AndroidJUnit4::class)
class C04LinksInlineWithTextTest : TechniqueTest("C04") {
    private fun open(slug: String) = openExample(slug, By.desc(c04Titles.getValue(slug)), settleMillis = 300)

    private fun linkId(slug: String, n: Int) = "c04-$slug-link-$n"

    private val good = listOf("good-material", "good-cupertino", "good-custom")

    private fun urls(node: AccessibilityNodeInfo): List<String> {
        val desc = node.contentDescription as? Spanned ?: return emptyList()
        return desc.getSpans(0, desc.length, URLSpan::class.java).map { it.url }
    }

    private fun clickLabel(node: AccessibilityNodeInfo): String =
        node.actionList.firstOrNull { it.id == AccessibilityNodeInfo.ACTION_CLICK }?.label?.toString().orEmpty()

    private fun onPage(title: String): Boolean = anyWindowHas { it.name() == title }

    private fun onExample(slug: String): Boolean = anyWindowHas { it.name() == c04Titles.getValue(slug) }

    /** Waits up to 5 seconds for [condition]. */
    private fun waitFor(what: String, condition: () -> Boolean) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !condition()) Thread.sleep(100)
        assertTrue(what, condition())
    }

    /** The page of [link] is on screen, then one Back brings [slug] back. */
    private fun expectFollowedOnce(slug: String, link: Link, how: String) {
        waitFor("$slug: $how opens ${link.page}") { onPage(link.page) && !onExample(slug) }
        device.pressBack()
        waitFor("$slug: one Back after $how brings the example back") { onExample(slug) && !onPage(link.page) }
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act (as in C03). */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /** Tab until [id] has keyboard focus; the first Tab can be used up leaving touch mode. */
    private fun tabTo(id: String) {
        for (i in 0 until 6) {
            key("TAB")
            if (revealed(id).isFocused) return
        }
        throw AssertionError("Tab did not reach $id")
    }

    /** The names of the sentence's own nodes, in the tree's order. */
    private fun sentenceParts(slug: String): List<String> {
        val parent = node(linkId(slug, 1)).parent
        assertNotNull("$slug: the sentence's node", parent)
        return (0 until parent!!.childCount).map { parent.getChild(it).name() }
    }

    @Test
    fun goodLinksAreNamedNodesWithTheirAddressInTheirPlace() {
        for (slug in good) {
            open(slug)
            for ((i, link) in LINKS.withIndex()) {
                val id = linkId(slug, i + 1)
                val node = node(id)
                assertEquals("$id class", VIEW, node.type())
                assertEquals("$id name", link.name, node.name())
                assertEquals("$id address", listOf(link.address), urls(node))
                assertEquals("$id click label", "open link", clickLabel(node))
                assertTrue("$id clickable", node.isClickable)
                assertTrue("$id focusable", node.isFocusable)
            }
            // The sentence's nodes: its words and its links, in order.
            assertEquals("$slug: the sentence", SENTENCE, sentenceParts(slug))
            // The two links are the only controls but Back.
            assertEquals("$slug: clickable nodes but Back", 2, all().count { it.isClickable && it.name() != "Back" })
        }
    }

    @Test
    fun goodLinksAreFollowedOnceByTheClickAction() {
        // ACTION_CLICK is what TalkBack performs on a double tap.
        for (slug in good) {
            for ((i, link) in LINKS.withIndex()) {
                open(slug)
                assertTrue(node(linkId(slug, i + 1)).performAction(AccessibilityNodeInfo.ACTION_CLICK))
                expectFollowedOnce(slug, link, "the click action on link ${i + 1}")
            }
        }
    }

    @Test
    fun goodLinksAreFollowedOnceByATap() {
        for (slug in good) {
            for ((i, link) in LINKS.withIndex()) {
                open(slug)
                val r = Rect().also { node(linkId(slug, i + 1)).getBoundsInScreen(it) }
                assertTrue(device.click(r.centerX(), r.centerY()))
                expectFollowedOnce(slug, link, "a tap on link ${i + 1}")
            }
        }
    }

    @Test
    fun goodLinksAreReachedByTabInOrderAndFollowedByEnter() {
        for (slug in good) {
            for ((i, link) in LINKS.withIndex()) {
                open(slug)
                tabTo(linkId(slug, 1))
                if (i == 1) {
                    // The next Tab goes from the first link to the second.
                    key("TAB")
                    waitFor("$slug: one Tab from the first link reaches the second") {
                        revealed(linkId(slug, 2)).isFocused && !revealed(linkId(slug, 1)).isFocused
                    }
                }
                key("ENTER")
                expectFollowedOnce(slug, link, "Enter on link ${i + 1}")
            }
        }
    }

    // Each bad example is asserted to have its named defect.

    @Test
    fun badTextSpanIsAButtonWithNoAddressThatTabNeverReaches() {
        open("bad-text-span")
        val id = "c04-bad-text-span-link-1"
        val node = node(id)
        assertEquals(LINKS[0].name, node.name())
        // A link with no address is a button on Android (FL-032).
        assertEquals(BUTTON, node.type())
        assertEquals(emptyList<String>(), urls(node))
        // In its place in the sentence.
        val parent = node.parent!!
        assertEquals(listOf("Read about ", LINKS[0].name, " first."), (0 until parent.childCount).map { parent.getChild(it).name() })
        // Tab never gives it focus. The positive control in the same launch:
        // Tab does reach Back, the one other control.
        var backFocused = false
        for (i in 0 until 6) {
            key("TAB")
            assertFalse("Tab ${i + 1} gave it focus", revealed(id).isFocused)
            if (named("Back").isFocused) backFocused = true
        }
        assertTrue("Tab reached Back", backFocused)
        // The click action still opens its page, which hides the defect.
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitFor("the click action opens the text span's page") { onPage(TEXT_SPAN_PAGE) }
    }

    /** No key opens the page that only bad-text-span's link opens. */
    @Test
    fun badTextSpanPageIsOpenedByNoKey() {
        val id = "c04-bad-text-span-link-1"
        for (name in listOf("ENTER", "SPACE")) {
            open("bad-text-span")
            var backFocused = false
            for (i in 0 until 6) {
                key("TAB")
                assertFalse("$name: Tab ${i + 1} gave the link focus", revealed(id).isFocused)
                if (named("Back").isFocused) { backFocused = true; break }
            }
            assertTrue("$name: Tab reached Back", backFocused)
            key(name)
            waitFor("$name on Back opens the technique's page") { onPage(LINKS[0].page) }
            assertFalse("$name: the text span's page did not open", onPage(TEXT_SPAN_PAGE))
        }
    }

    @Test
    fun badOutOfOrderReadsTheSentenceWithoutItsLinksThenTheLinks() {
        open("bad-out-of-order")
        val first = node(linkId("bad-out-of-order", 1))
        val sentence = first.parent!!
        // The sentence's node is named by its words alone, and holds the
        // two links after them.
        assertEquals("Read about \n and \n first.", sentence.name())
        assertEquals(LINKS.map { it.name }, (0 until sentence.childCount).map { sentence.getChild(it).name() })
        for ((i, link) in LINKS.withIndex()) {
            assertEquals(listOf(link.address), urls(node(linkId("bad-out-of-order", i + 1))))
        }
    }

    @Test
    fun badMergedIsOneLinkNodeWhoseClickFollowsTheFirstLink() {
        open("bad-merged")
        val node = node("c04-bad-merged-sentence")
        assertEquals(SENTENCE.joinToString("\n"), node.name())
        assertEquals(VIEW, node.type())
        // One address, the first link's, over the whole sentence.
        assertEquals(listOf(LINKS[0].address), urls(node))
        assertEquals(0, node.childCount)
        assertEquals("one clickable node but Back", 1, all().count { it.isClickable && it.name() != "Back" })
        assertTrue(node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        expectFollowedOnce("bad-merged", LINKS[0], "the click action")
    }

    /**
     * L4. Moves TalkBack focus to each part of each sentence in turn and logs
     * markers; tool/talkback.py reads the speech from logcat. Moving focus by
     * action shows what is said for each part, not where a swipe goes: the
     * tree tests check the parts' order. Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        fun part(slug: String, n: Int) = { node(linkId(slug, 1)).parent!!.getChild(n) }
        fun sentenceStops(slug: String) = listOf(
            Stop("c04-$slug-words-1", find = part(slug, 0)),
            Stop(linkId(slug, 1)) { node(linkId(slug, 1)) },
            Stop("c04-$slug-words-2", find = part(slug, 2)),
            Stop(linkId(slug, 2)) { node(linkId(slug, 2)) },
            Stop("c04-$slug-words-3", find = part(slug, 4)),
        )
        val span = "c04-bad-text-span-link-1"
        val walk: List<Pair<String, List<Stop>>> = good.map { it to sentenceStops(it) } + listOf(
            "bad-text-span" to listOf(Stop(span) { node(span) }),
            "bad-out-of-order" to listOf(
                Stop("c04-bad-out-of-order-sentence") { node(linkId("bad-out-of-order", 1)).parent!! },
                Stop(linkId("bad-out-of-order", 1)) { node(linkId("bad-out-of-order", 1)) },
                Stop(linkId("bad-out-of-order", 2)) { node(linkId("bad-out-of-order", 2)) },
            ),
            "bad-colour-only" to sentenceStops("bad-colour-only"),
            "bad-merged" to listOf(Stop("c04-bad-merged-sentence") { node("c04-bad-merged-sentence") }),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 5_000 })
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val c04Titles = mapOf(
    "good-material" to "Material links in a sentence",
    "good-cupertino" to "Cupertino links in a sentence",
    "good-custom" to "Widgets-layer links in a sentence",
    "bad-text-span" to "Link in a text span",
    "bad-out-of-order" to "Links read after their sentence",
    "bad-colour-only" to "Links shown by colour alone",
    "bad-merged" to "Sentence and links as one element",
)
