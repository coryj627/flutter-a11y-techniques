// L3 (tree and taps) and L4 (TalkBack walk) for V13 Minimum touch target
// size on Android.
// Spec: docs/specs/V13-touch-target-size.md.
//
// Every size is compared in dp: a node's bounds are in pixels, and are
// divided by the device's density first (1 on CI's 320 by 640 emulator,
// 2.625 on the local one). Points to tap are worked out in dp, 2 dp inside
// or outside an edge, and turned back into pixels, after the node's bounds
// have stopped moving. The probe found that the bounds are Flutter's
// semantics node and that a tap is taken where Flutter's hit test says,
// which here is the node (docs/evidence/probes/v13/README.md).
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Rect
import android.graphics.RectF
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.math.hypot

private const val BUTTON = "android.widget.Button"
private const val MINIMUM = 24f
private const val LINK = "good-inline-link"

private val NAMES = linkedMapOf("previous" to "Previous", "play" to "Play", "next" to "Next")
private val GOOD = listOf("good-material", "good-cupertino", "good-custom")
private val BAD = listOf("bad-shrinkwrap", "bad-zero-padding-web", "bad-cupertino-small", "bad-custom-small")

// Each control's node in dp on Android. bad-zero-padding-web is padded to
// 48 by 48 here by the theme; its defect is in a desktop browser (FL-412).
private val SIZE = mapOf(
    "good-material" to 48f,
    "good-cupertino" to 48f,
    "good-custom" to 48f,
    "bad-shrinkwrap" to 18f,
    "bad-zero-padding-web" to 48f,
    "bad-cupertino-small" to 18f,
    "bad-custom-small" to 18f,
)

/**
 * The targets that fail WCAG 2.5.8 among [targets] (id to rect in dp): an
 * undersized one passes only if a circle 24 across, centred on it, meets no
 * other target and no other undersized target's circle. The same rule as
 * wcag258Failures in the widget tests.
 */
internal fun wcag258Failures(targets: Map<String, RectF>): List<String> {
    fun undersized(r: RectF) = r.width() < MINIMUM || r.height() < MINIMUM
    val failures = mutableListOf<String>()
    for ((id, r) in targets) {
        if (!undersized(r)) continue
        for ((other, o) in targets) {
            if (other == id) continue
            val nx = r.centerX().coerceIn(o.left, o.right)
            val ny = r.centerY().coerceIn(o.top, o.bottom)
            if (hypot(nx - r.centerX(), ny - r.centerY()) < MINIMUM / 2) {
                failures.add("$id: its circle meets $other")
            } else if (undersized(o) && hypot(o.centerX() - r.centerX(), o.centerY() - r.centerY()) < MINIMUM) {
                failures.add("$id: its circle meets the circle of $other")
            }
        }
    }
    return failures
}

@RunWith(AndroidJUnit4::class)
class V13TouchTargetSizeTest : TechniqueTest("V13") {
    override val countName: String get() = "press count"

    private val density: Float get() = inst.targetContext.resources.displayMetrics.density

    private fun ids(slug: String): List<String> =
        if (slug == LINK) listOf("v13-$LINK-rules") else NAMES.keys.map { "v13-$slug-$it" }

    /** Opens an example and waits for its first control. */
    private fun open(slug: String) = openExample(slug, By.res(ids(slug).first()))

    /**
     * The node's bounds in dp, once they are the same on two reads 250 ms
     * apart; throws if they never settle. Taps were lost on CI when a point
     * was worked out while the screen was still arriving.
     */
    private fun settled(id: String): RectF {
        fun bounds() = Rect().also { revealed(id).getBoundsInScreen(it) }
        var r = bounds()
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end) {
            Thread.sleep(250)
            val next = bounds()
            if (next == r) return RectF(r.left / density, r.top / density, r.right / density, r.bottom / density)
            r = next
        }
        throw AssertionError("$id was still moving after 5 seconds, last at $r")
    }

    /** Taps at (x, y) in dp. */
    private fun tapAt(x: Float, y: Float) {
        assertTrue("tap at $x,$y dp", device.click(Math.round(x * density), Math.round(y * density)))
    }

    /** Taps at a point of [id]'s node, worked out after it has settled, and waits for [expected] presses. */
    private fun tapExpecting(slug: String, id: String, expected: Int, why: String, point: (RectF) -> Pair<Float, Float>) {
        val before = count(slug)
        val (x, y) = point(settled(id))
        tapAt(x, y)
        // When nothing is to change, give a stray press time to show.
        if (expected == before) Thread.sleep(1_500)
        waitForCount(slug, expected)
        // And no second press after the expected one.
        Thread.sleep(300)
        assertEquals("$id: $why", expected, count(slug))
    }

    /**
     * A tap at [point] that must do nothing, checked alone, then the
     * positive control in the same launch: a tap at the centre of [id],
     * which must press it once.
     */
    private fun expectNothingAt(slug: String, id: String, why: String, point: (RectF) -> Pair<Float, Float>) {
        val before = count(slug)
        tapExpecting(slug, id, before, why, point)
        tapExpecting(slug, id, before + 1, "the tap at its centre after $why") { it.centerX() to it.centerY() }
    }

    @Test
    fun everyControlHasItsNameClassAndSizeInDp() {
        for (slug in GOOD + LINK + BAD) {
            open(slug)
            for (id in ids(slug)) {
                val node = revealed(id)
                assertTrue(id, node.isClickable)
                assertTrue(id, node.actionList.any { it.id == AccessibilityNodeInfo.ACTION_CLICK })
                if (slug == LINK) {
                    assertEquals(id, "trail rules", node.name())
                    continue
                }
                assertEquals(id, NAMES[id.substringAfterLast('-')], node.name())
                assertEquals(id, BUTTON, node.type())
                val r = settled(id)
                // Within half a dp: the bounds are whole pixels.
                assertEquals("$id width in dp at density $density", SIZE[slug]!!, r.width(), 0.5f)
                assertEquals("$id height in dp at density $density", SIZE[slug]!!, r.height(), 0.5f)
            }
        }
    }

    @Test
    fun goodExamplesHaveNoTargetUnder24By24() {
        for (slug in GOOD + "bad-zero-padding-web") {
            open(slug)
            val targets = ids(slug).associateWith { settled(it) }
            for ((id, r) in targets) {
                assertTrue("$id is ${r.width()} by ${r.height()} dp", r.width() >= MINIMUM && r.height() >= MINIMUM)
            }
            assertEquals(slug, emptyList<String>(), wcag258Failures(targets))
        }
    }

    @Test
    fun badExamplesFailEvenWithTheSpacingException() {
        for (slug in BAD - "bad-zero-padding-web") {
            open(slug)
            val targets = ids(slug).associateWith { settled(it) }
            val rects = targets.values.toList()
            assertEquals("$slug gap 1", 4f, rects[1].left - rects[0].right, 0.75f)
            assertEquals("$slug gap 2", 4f, rects[2].left - rects[1].right, 0.75f)
            assertEquals(slug, targets.keys, wcag258Failures(targets).map { it.substringBefore(':') }.toSet())
        }
    }

    @Test
    fun theLinkIsUnder24HighInItsSentence() {
        open(LINK)
        val r = settled("v13-$LINK-rules")
        assertTrue("the link is ${r.height()} dp high", r.height() < MINIMUM)
    }

    @Test
    fun eachControlTakesATapInsideItsEdgeAndNotOutside() {
        for (slug in GOOD + BAD) {
            open(slug)
            for (id in ids(slug)) {
                tapExpecting(slug, id, count(slug) + 1, "centre") { it.centerX() to it.centerY() }
                tapExpecting(slug, id, count(slug) + 1, "2 dp inside its bottom edge") { it.centerX() to it.bottom - 2 }
                expectNothingAt(slug, id, "2 dp below its bottom edge") { it.centerX() to it.bottom + 2 }
            }
            // Nothing is to the right of the last control. On the web the
            // small ones' labels take a click there (FL-411); here they do not.
            expectNothingAt(slug, ids(slug).last(), "2 dp right of its right edge") { it.right + 2 to it.centerY() }
        }
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act (as in I01). */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /**
     * The link takes keyboard focus and Enter and Space activate it. The
     * emulator has a hardware keyboard; the first Tab after launch can be
     * used up leaving touch mode, so Tab is pressed until the link has
     * focus (I01's probe). isFocused follows Flutter's keyboard focus.
     */
    @Test
    fun tabReachesTheLinkAndEnterAndSpaceActivateIt() {
        open(LINK)
        val id = "v13-$LINK-rules"
        var reached = false
        for (i in 0 until 6) {
            key("TAB")
            if (revealed(id).isFocused) { reached = true; break }
        }
        assertTrue("Tab reaches the link", reached)
        key("ENTER")
        waitForCount(LINK, 1)
        key("SPACE")
        waitForCount(LINK, 2)
        assertTrue("focus stays on the link", revealed(id).isFocused)
    }

    @Test
    fun theLinkTakesATapAndNotOneJustBelowIt() {
        open(LINK)
        val id = "v13-$LINK-rules"
        tapExpecting(LINK, id, 1, "centre") { it.centerX() to it.centerY() }
        expectNothingAt(LINK, id, "2 dp below it") { it.centerX() to it.bottom + 2 }
    }

    /**
     * L4. Moves TalkBack focus to each control and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running. Size is not heard: TalkBack reads the small buttons as it
     * reads the large ones.
     */
    @Test
    fun talkBackWalk() {
        val walk: List<Pair<String, List<Stop>>> = (GOOD + LINK + BAD).map { slug ->
            slug to ids(slug).map { id -> Stop(id) { nodeInAnyWindow(id) } }
        }
        talkBackWalk(walk, open = { slug -> openExampleInAnyWindow(slug) { it.viewIdResourceName == ids(slug).first() } },
            dwellMillis = { 4_000 })
    }
}
