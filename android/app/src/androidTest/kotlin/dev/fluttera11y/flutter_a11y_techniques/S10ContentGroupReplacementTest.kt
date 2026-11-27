// L3 (tree) and L4 (TalkBack walk) for S10 Content group replacement on
// Android. Spec: docs/specs/S10-content-group-replacement.md.
//
// Each replacement carries an identifier of its own, `Semantics(identifier:)`
// on the replacement node, and the add buttons theirs through `TestId`. The
// pieces of `bad-pieces` have none and are found by their names.
package dev.fluttera11y.flutter_a11y_techniques

import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val VIEW = "android.view.View"
private const val BUTTON = "android.widget.Button"
private const val PROGRESS = "android.widget.ProgressBar"
private const val WORDS = "Rating: 3.4 out of 5 stars, based on 856 reviews"
private const val WORDS_AFTER = "Rating: 3.4 out of 5 stars, based on 857 reviews"
private const val PIECES = "Rating:\n3.4 / 5\nReviews: 856"
private const val ADD = "Add a 5-star review"
private val PIECE_NAMES = listOf("Rating:", "3.4 / 5", "Reviews: 856", "3.4", "(856)")

@RunWith(AndroidJUnit4::class)
class S10ContentGroupReplacementTest : TechniqueTest("S10") {
    /** Waits for the example's own title. */
    private fun open(slug: String) = openExample(slug, By.desc(s10Titles.getValue(slug)), settleMillis = 300)

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
     * Every node after the "Example" heading to the end of the screen, in
     * the tree's order, that has a name or a range: what TalkBack moves
     * through. The screen is read from the top and then scrolled a step at a
     * time to its end, each node kept once, in the order first seen: on CI's
     * 320 by 640 emulator the example's end can be below the view.
     */
    private fun exampleNodes(): List<AccessibilityNodeInfo> {
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        val keys = mutableSetOf<String>()
        for (step in 0 until 8) {
            var added = false
            for (n in all()) {
                if (keys.add("${n.name()}|${n.type()}|${n.viewIdResourceName}")) {
                    nodes.add(n)
                    added = true
                }
            }
            val view = all().firstOrNull { it.isScrollable } ?: break
            if (!view.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD) && !added) break
            Thread.sleep(500)
        }
        val start = nodes.indexOfFirst { it.name() == "Example" }
        assertTrue("the Example heading", start >= 0)
        return nodes.subList(start + 1, nodes.size).filter { it.name().isNotEmpty() || it.rangeInfo != null }
    }

    private fun describe(n: AccessibilityNodeInfo): String = listOfNotNull(
        n.name(),
        n.type().substringAfterLast('.'),
        n.rangeInfo?.let { "range ${it.min.toInt()}..${it.max.toInt()} at ${it.current.toInt()}" },
        if (n.isClickable) "clickable" else null,
    ).joinToString(" | ")

    /** The replacement node of [slug]. */
    private fun rating(slug: String) = node("s10-$slug-rating")

    /** Waits up to five seconds for the replacement of [slug] to be named [name]. */
    private fun waitForRating(slug: String, name: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            val n = runCatching { rating(slug).name() }.getOrNull()
            if (n == name) return
            Thread.sleep(100)
        }
        assertEquals("$slug's replacement", name, rating(slug).name())
    }

    /** No node of the screen is a piece of the rating or a progress bar. */
    private fun assertNoPieces(what: String) {
        for (n in all()) {
            assertFalse("$what: a node named \"${n.name()}\"", n.name() in PIECE_NAMES)
            assertFalse("$what: a progress bar", n.type() == PROGRESS || n.rangeInfo != null)
        }
    }

    @Test
    fun eachGoodReplacementIsOneNodeNamedByWhatTheRatingMeans() {
        for (slug in listOf("good-exclude-semantics", "good-hidden-pieces", "good-stars")) {
            open(slug)
            val r = rating(slug)
            assertEquals(slug, VIEW, r.type())
            assertEquals(slug, WORDS, r.name())
            assertNull("$slug: no range", r.rangeInfo)
            assertFalse("$slug: not clickable", r.isClickable)
            assertEquals("$slug: no child", 0, r.childCount)
            assertNoPieces(slug)
            val expected = mutableListOf("$WORDS | View")
            if (slug == "good-exclude-semantics") expected.add("$ADD | Button | clickable")
            assertEquals(slug, expected, exampleNodes().map(::describe))
        }
    }

    @Test
    fun theReplacementFollowsTheValuesAfterTheClickActionATapAndTabThenEnter() {
        val slug = "good-exclude-semantics"
        val add = "s10-$slug-add"
        for (how in listOf("click action", "tap", "Tab then Enter")) {
            open(slug)
            assertEquals(WORDS, rating(slug).name())
            when (how) {
                // The click action: what TalkBack's double tap performs.
                "click action" -> assertTrue(node(add).performAction(AccessibilityNodeInfo.ACTION_CLICK))
                "tap" -> {
                    val r = android.graphics.Rect().also { node(add).getBoundsInScreen(it) }
                    device.click(r.centerX(), r.centerY())
                }
                else -> {
                    tabTo(add)
                    key("ENTER")
                }
            }
            waitForRating(slug, WORDS_AFTER)
            assertNoPieces("$slug after the $how")
        }
    }

    @Test
    fun badPiecesIsTwoNumbersAndNothingForTheStars() {
        open("bad-pieces")
        assertEquals(listOf("3.4 | View", "(856) | View"), exampleNodes().map(::describe))
        for (n in exampleNodes()) {
            for (word in listOf("star", "Star", "out of", "review", "Rating")) {
                assertFalse("\"${n.name()}\" has \"$word\"", n.name().contains(word))
            }
        }
    }

    @Test
    fun badMergedIsOneProgressBarAt68NamedByThePieces() {
        open("bad-merged")
        val r = rating("bad-merged")
        assertEquals(PROGRESS, r.type())
        assertEquals("68, $PIECES", r.name())
        assertEquals(68f, r.rangeInfo!!.current)
        assertEquals(listOf("68, $PIECES | ProgressBar | range 0..100 at 68"), exampleNodes().map(::describe))
    }

    @Test
    fun badNotExcludedIsOneProgressBarWithTheLabelAndThePieces() {
        open("bad-not-excluded")
        val r = rating("bad-not-excluded")
        assertEquals(PROGRESS, r.type())
        assertEquals("68, $WORDS\n$PIECES", r.name())
        assertEquals(
            listOf("68, $WORDS\n$PIECES | ProgressBar | range 0..100 at 68"),
            exampleNodes().map(::describe),
        )
    }

    @Test
    fun badHidesControlHasNoNodeForTheButtonThatTheKeyboardStillReaches() {
        open("bad-hides-control")
        assertEquals(
            listOf("$WORDS | View", "Reviews opened: 0 | View"),
            exampleNodes().map(::describe),
        )
        assertEquals("no node is the button", 0, all().count { it.name() == "Reviews" })
        assertEquals("no clickable node but Back", 0, all().count { it.isClickable && it.name() != "Back" })
        // The keyboard reaches it. From a fresh launch each, one to three
        // Tabs and then Enter, sent once: Enter on Back leaves the screen
        // (the positive control for the keys), and on the stop after Back it
        // runs Reviews, while no node named Reviews is focused (the probe
        // found Back still reported as focused: android-tree.txt, p13).
        val results = mutableListOf<String>()
        var ranReviews = false
        var leftByBack = false
        for (tabs in 1..3) {
            open("bad-hides-control")
            repeat(tabs) { key("TAB") }
            val focused = all().filter { it.isFocused }.map { it.name() }
            key("ENTER")
            Thread.sleep(1_500)
            val open = anyWindowHas { it.name() == "Example" }
            val opens = if (open) node("s10-bad-hides-control-opens").name() else "(screen left)"
            results.add("$tabs Tabs, focused $focused: $opens")
            if (opens == "Reviews opened: 1") {
                ranReviews = true
                assertFalse("no node named Reviews is focused", focused.contains("Reviews"))
            }
            if (!open) leftByBack = true
        }
        assertTrue("Enter after a Tab ran Reviews: $results", ranReviews)
        assertTrue("Enter on Back left the screen: $results", leftByBack)
    }

    @Test
    fun badStaleKeepsSaying856AfterAReview() {
        open("bad-stale")
        assertEquals(WORDS, rating("bad-stale").name())
        assertTrue(node("s10-bad-stale-add").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        // As long as good-exclude-semantics takes to follow (its test waits
        // up to five seconds), and the name must not change.
        val end = System.currentTimeMillis() + 2_000
        while (System.currentTimeMillis() < end) {
            assertEquals(WORDS, rating("bad-stale").name())
            Thread.sleep(200)
        }
        assertEquals(0, all().count { it.name().contains("857") })
        // Positive control in the same test: good-exclude-semantics follows.
        open("good-exclude-semantics")
        assertTrue(node("s10-good-exclude-semantics-add").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForRating("good-exclude-semantics", WORDS_AFTER)
    }

    /**
     * L4. Moves TalkBack focus to each node of each example and logs
     * markers; tool/talkback.py reads the speech from logcat and judges each
     * walk whole. Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val byId = { marker: String, id: String -> Stop(marker) { node(id) } }
        val byName = { marker: String, name: String -> Stop(marker) { all().single { it.name() == name } } }
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-exclude-semantics" to listOf(
                byId("s10-good-exclude-semantics-rating", "s10-good-exclude-semantics-rating"),
                byId("s10-good-exclude-semantics-add", "s10-good-exclude-semantics-add"),
                // After the click action on the button, the replacement again.
                Stop("s10-good-exclude-semantics-after", before = {
                    assertTrue(node("s10-good-exclude-semantics-add").performAction(AccessibilityNodeInfo.ACTION_CLICK))
                    waitForRating("good-exclude-semantics", WORDS_AFTER)
                }) { node("s10-good-exclude-semantics-rating") },
            ),
            "good-hidden-pieces" to listOf(byId("s10-good-hidden-pieces-rating", "s10-good-hidden-pieces-rating")),
            "good-stars" to listOf(byId("s10-good-stars-rating", "s10-good-stars-rating")),
            "bad-pieces" to listOf(byName("s10-bad-pieces-stars", "3.4"), byName("s10-bad-pieces-count", "(856)")),
            "bad-merged" to listOf(byId("s10-bad-merged-rating", "s10-bad-merged-rating")),
            "bad-not-excluded" to listOf(byId("s10-bad-not-excluded-rating", "s10-bad-not-excluded-rating")),
            "bad-hides-control" to listOf(
                byId("s10-bad-hides-control-rating", "s10-bad-hides-control-rating"),
                byId("s10-bad-hides-control-opens", "s10-bad-hides-control-opens"),
            ),
            "bad-stale" to listOf(
                byId("s10-bad-stale-rating", "s10-bad-stale-rating"),
                // Focus is moved to the button first, as in
                // good-exclude-semantics: with focus put on the replacement
                // again straight after its first reading, TalkBack said
                // nothing for it in three walks (the first recording,
                // docs/evidence/probes/s10/talkback-round1-fail.md.txt; the
                // cause was not found).
                byId("s10-bad-stale-add", "s10-bad-stale-add"),
                Stop("s10-bad-stale-after", before = {
                    assertTrue(node("s10-bad-stale-add").performAction(AccessibilityNodeInfo.ACTION_CLICK))
                    Thread.sleep(2_000)
                }) { node("s10-bad-stale-rating") },
            ),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val s10Titles = mapOf(
    "good-exclude-semantics" to "Rating replaced with excludeSemantics",
    "good-hidden-pieces" to "Rating merged, with every piece hidden",
    "good-stars" to "Star rating replaced",
    "bad-pieces" to "Star rating left as pieces",
    "bad-merged" to "Rating merged, not replaced",
    "bad-not-excluded" to "Label with the pieces left in",
    "bad-hides-control" to "Replacement that hides a button",
    "bad-stale" to "Replacement with a fixed label",
)
