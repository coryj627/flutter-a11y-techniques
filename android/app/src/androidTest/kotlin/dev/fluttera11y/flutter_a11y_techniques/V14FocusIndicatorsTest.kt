// L3 (tree, keyboard, and pixels) and L4 (TalkBack walk) for V14 Focus
// indicators on Android.
// Spec: docs/specs/V14-focus-indicators.md.
//
// Keys are sent with `input keyevent`. Android gives every key a test can
// send the virtual keyboard's device id (-1), whatever device it was sent
// as, and Flutter does not let a key from that device turn its focus
// highlights on: they stay as after a touch (FL-433;
// docs/evidence/probes/v14/README.md, rounds 2 to 5, which tried five ways
// of sending keys and four of moving a mouse). So on Android only an
// indicator that Flutter draws whenever the control has focus can be seen
// by these tests: good-material's two rings, which come from the focused
// state and not from the highlight mode. Those are measured here, and
// FL-433 is asserted on the same screen: the checkbox tile's own focus tint,
// which follows the highlight mode, is not drawn while the ring is. The
// indicators that follow the highlight mode (good-cupertino, good-widgets,
// and the defaults of the bad examples) are measured in the widget tests,
// on the web, and on iOS, and are not verified on Android.
//
// What focus draws is read from UiAutomation.takeScreenshot: one screenshot
// before Tab reaches a control and two after, 700 ms apart once the screen
// has stopped changing. The pixels round the control that changed in both
// and agree are what focus drew; contrast is worked out from those pixels,
// never from the theme. Each stop is the node that reports isFocused.
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Bitmap
import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val CHECKBOX = "android.widget.CheckBox"
private const val SWITCH = "android.widget.Switch"
private const val BUTTON = "android.widget.Button"
private const val THRESHOLD = 12

/** The controls of each example outside a scrolling list, in Tab order after Back. */
private val CONTROLS = mapOf(
    "good-material" to listOf(Triple("alerts", "Weather alerts", CHECKBOX), Triple("save", "Save", BUTTON)),
    "good-cupertino" to listOf(Triple("alerts", "Weather alerts", SWITCH), Triple("save", "Save", BUTTON)),
    "good-widgets" to listOf(Triple("trail", "Ridge trail", BUTTON)),
    "bad-indicator-removed" to listOf(Triple("save", "Save", BUTTON)),
    "bad-checkbox-halo" to listOf(Triple("alerts", "Weather alerts", CHECKBOX)),
    "bad-cupertino-ring" to listOf(Triple("save", "Save", BUTTON)),
)
private val TRAILS = listOf("Ridge trail", "Lake loop", "Summit path", "Forest walk", "River run", "Canyon climb")
private val NOTICE = listOf("good-notice-below", "bad-notice-over-list")

/** WCAG's contrast ratio between two colours (0xRRGGBB). */
private fun contrast(a: Int, b: Int): Double {
    fun lin(c: Int): Double { val v = c / 255.0; return if (v <= 0.04045) v / 12.92 else Math.pow((v + 0.055) / 1.055, 2.4) }
    fun lum(p: Int) = 0.2126 * lin((p shr 16) and 255) + 0.7152 * lin((p shr 8) and 255) + 0.0722 * lin(p and 255)
    val x = lum(a); val y = lum(b)
    return (maxOf(x, y) + 0.05) / (minOf(x, y) + 0.05)
}

private fun channelDiff(a: Int, b: Int) = maxOf(
    Math.abs(((a shr 16) and 255) - ((b shr 16) and 255)),
    Math.abs(((a shr 8) and 255) - ((b shr 8) and 255)),
    Math.abs((a and 255) - (b and 255)))

private fun hex(c: Int) = String.format("#%06X", c and 0xFFFFFF)

/**
 * What focus drew in a region. Changed pixels differ from before focus in
 * both captures and agree; a mark is a changed pixel drawn where the page
 * was, or 3:1 or more from the colour it replaced (a tinted fill or a border
 * a shade darker is not one); strong marks are 3:1 or more against the
 * page, whose colour is the commonest along the region's edge, before focus.
 */
private class Indicator(
    val changed: Int, val unstable: Int, val marks: Int, val strong: Int,
    val page: Int, val colour: Int?, val strongColour: Int?,
) {
    val ratio: Double get() = colour?.let { contrast(it, page) } ?: 1.0
    override fun toString() = "changed $changed, unstable $unstable, marks $marks, page ${hex(page)}, " +
        "commonest mark ${colour?.let { hex(it) } ?: "none"} (${"%.2f".format(ratio)}), 3:1 or more: $strong" +
        (strongColour?.let { " (${hex(it)}, ${"%.2f".format(contrast(it, page))})" } ?: "")
}

private fun compare(u: Bitmap, f1: Bitmap, f2: Bitmap, region: Rect): Indicator {
    val l = maxOf(0, region.left); val t = maxOf(0, region.top)
    val r = minOf(u.width, region.right); val b = minOf(u.height, region.bottom)
    val edge = HashMap<Int, Int>()
    for (x in l until r) for (y in listOf(t, t + 1, b - 2, b - 1)) edge.merge(u.getPixel(x, y) and 0xFFFFFF, 1, Int::plus)
    val page = edge.maxByOrNull { it.value }!!.key
    var changed = 0; var unstable = 0; var marks = 0; var strong = 0
    val colours = HashMap<Int, Int>(); val strongColours = HashMap<Int, Int>()
    val ratios = HashMap<Long, Double>()
    fun ratio(a: Int, c: Int) = ratios.getOrPut((a.toLong() shl 32) or c.toLong()) { contrast(a, c) }
    for (y in t until b) for (x in l until r) {
        val a = u.getPixel(x, y) and 0xFFFFFF; val p = f1.getPixel(x, y) and 0xFFFFFF; val q = f2.getPixel(x, y) and 0xFFFFFF
        val d1 = channelDiff(a, p) > THRESHOLD; val d2 = channelDiff(a, q) > THRESHOLD
        if (d1 && d2 && channelDiff(p, q) <= THRESHOLD) {
            changed++
            if (channelDiff(p, page) > THRESHOLD && (channelDiff(a, page) <= THRESHOLD || ratio(p, a) >= 3)) {
                marks++
                colours.merge(p, 1, Int::plus)
                if (ratio(p, page) >= 3) { strong++; strongColours.merge(p, 1, Int::plus) }
            }
        } else if (d1 || d2) unstable++
    }
    return Indicator(changed, unstable, marks, strong, page,
        colours.maxByOrNull { it.value }?.key, strongColours.maxByOrNull { it.value }?.key)
}

@RunWith(AndroidJUnit4::class)
class V14FocusIndicatorsTest : TechniqueTest("V14") {
    private val density = inst.targetContext.resources.displayMetrics.density

    /** The pixels a measure of `n` logical pixels squared is. */
    private fun area(n: Int) = n * density * density

    private fun first(slug: String) = if (slug in NOTICE) "trail1" else CONTROLS.getValue(slug).first().first

    private fun open(slug: String) = openExample(slug, By.res("v14-$slug-${first(slug)}"), settleMillis = 1_000)

    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(500)
    }

    private fun find(id: String): AccessibilityNodeInfo? = all().firstOrNull { it.viewIdResourceName == id }

    private fun bounds(id: String): Rect = Rect().also { revealed(id).getBoundsInScreen(it) }

    /** The control with keyboard focus, by its identifier's last part, "back", or "none". */
    private fun stop(slug: String): String {
        val focused = all().filter { it.isFocused && (it.viewIdResourceName != null || it.name().isNotEmpty()) }
        if (focused.isEmpty()) return "none"
        assertEquals("nodes with focus: ${focused.map { it.viewIdResourceName ?: it.name() }}", 1, focused.size)
        val node = focused.single()
        if (node.name() == "Back") return "back"
        val id = node.viewIdResourceName.orEmpty()
        return if (id.startsWith("v14-$slug-")) id.removePrefix("v14-$slug-") else "other: $id ${node.name()}"
    }

    /**
     * Presses Tab until [c] has focus, at most [max] times; waits, at most
     * 3 seconds, for the stop to be read. The first Tab after the app opens
     * is sometimes lost (docs/evidence/probes/i01/README.md).
     */
    private fun tabTo(slug: String, c: String, max: Int = 4) {
        for (i in 0 until max) {
            key("TAB")
            val end = System.currentTimeMillis() + 3_000
            while (System.currentTimeMillis() < end) {
                if (stop(slug) == c) return
                Thread.sleep(200)
            }
        }
        throw AssertionError("$slug: Tab did not reach $c; focus is on ${stop(slug)}")
    }

    /** The first scrollable node inside [root], depth first. */
    private fun scrollableIn(root: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (root == null) return null
        for (i in 0 until root.childCount) {
            val child = root.getChild(i) ?: continue
            if (child.isScrollable) return child
            scrollableIn(child)?.let { return it }
        }
        return null
    }

    /**
     * Trail [i] of [slug]'s list. A trail scrolled out of the list's own
     * box is not in the tree, and scrolling the page does not bring it
     * back: the list is brought into view, then scrolled itself, forward
     * and then back. No keyboard focus moves.
     */
    private fun trail(slug: String, i: Int): AccessibilityNodeInfo {
        val id = "v14-$slug-trail$i"
        find(id)?.let { return it }
        revealed("v14-$slug-list")
        for (action in listOf(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD, AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD)) {
            for (k in 0 until 6) {
                find(id)?.let { return it }
                val list = scrollableIn(find("v14-$slug-list")) ?: break
                if (!list.performAction(action)) break
                Thread.sleep(500)
            }
        }
        return find(id) ?: throw AssertionError("no node with id $id, even after scrolling its list")
    }

    private fun shot(): Bitmap {
        val b = automation.takeScreenshot()!!
        return if (b.config == Bitmap.Config.HARDWARE) b.copy(Bitmap.Config.ARGB_8888, false) else b
    }

    /** The control's bounds, 8 logical pixels larger on every side. */
    private fun region(id: String): Rect = bounds(id).apply { val m = (8 * density).toInt(); inset(-m, -m) }

    /**
     * Waits, at most 3 s, for two screenshots 300 ms apart that differ in no
     * more than 1% of [region]. Returns the last.
     */
    private fun settled(region: Rect): Bitmap {
        var last = shot()
        repeat(10) {
            Thread.sleep(300)
            val next = shot()
            val c = compare(last, next, next, region)
            last = next
            if (c.changed + c.unstable <= region.width() * region.height() / 100) return last
        }
        throw AssertionError("the screen did not settle")
    }

    /** Tabs to [c] (one Tab on from where focus is) and measures what changed round [id] against [before]. */
    private fun measureAfterTab(slug: String, c: String, id: String, before: Bitmap): Indicator {
        tabTo(slug, c, 1)
        val r = region(id)
        val f1 = settled(r)
        Thread.sleep(700)
        return compare(before, f1, shot(), r)
    }

    @Test
    fun theContrastRatioIsWcags() {
        assertEquals(21.0, contrast(0xFFFFFF, 0x000000), 0.001)
        assertEquals(4.54, contrast(0x767676, 0xFFFFFF), 0.01)
    }

    @Test
    fun everyControlHasItsNameAndClass() {
        for ((slug, controls) in CONTROLS) {
            open(slug)
            for ((c, name, type) in controls) {
                val node = revealed("v14-$slug-$c")
                assertEquals("$slug $c", name, node.name())
                assertEquals("$slug $c", type, node.type())
                assertTrue("$slug $c", !node.isFocused)
            }
        }
        for (slug in NOTICE) {
            open(slug)
            for ((i, trail) in TRAILS.withIndex()) {
                val node = trail(slug, i + 1)
                assertEquals(slug, trail, node.name())
                assertEquals(slug, BUTTON, node.type())
            }
        }
    }

    @Test
    fun goodMaterialDrawsRingsOf3To1WhichGoWhenFocusMovesOn() {
        val slug = "good-material"
        open(slug)
        tabTo(slug, "back")
        val controls = CONTROLS.getValue(slug)
        var lastBefore: Bitmap? = null
        for ((c) in controls) {
            val id = "v14-$slug-$c"
            lastBefore = settled(region(id))
            val ind = measureAfterTab(slug, c, id, lastBefore)
            Log.i("V14", "android $slug $c: $ind")
            assertTrue("$slug $c: $ind", ind.strong > area(150))
            // FL-433, on the same screen and through the same measure: the
            // ring is drawn (above), and the tile's and the button's own
            // focus tints, which follow the highlight mode, are not. With
            // highlights on, as in the widget tests and on the web and iOS,
            // the tile's tint is its commonest mark, at 1.32:1.
            assertTrue("$slug $c: the commonest mark is the ring: $ind", ind.ratio >= 3)
        }
        // Off again: Tab on from the last control, and its region is as it
        // was before it had focus.
        val lastId = "v14-$slug-${controls.last().first}"
        key("TAB")
        assertNotEquals(slug, controls.last().first, stop(slug))
        val r = region(lastId)
        val off = settled(r)
        val gone = compare(lastBefore!!, off, off, r)
        assertEquals("$slug after focus left: $gone", 0, gone.changed)
    }

    /**
     * The examples whose indicator follows Flutter's highlight mode: Tab
     * reaches each control (isFocused), so the keys arrive; what is drawn
     * is not asserted here (see the top of the file).
     */
    @Test
    fun tabReachesEveryControlOfTheOtherExamples() {
        for (slug in CONTROLS.keys - "good-material") {
            open(slug)
            tabTo(slug, "back")
            for ((c) in CONTROLS.getValue(slug)) tabTo(slug, c, 1)
        }
    }

    /** How much of trail [i] is in sight: inside the screen and the list, and not under the notice. */
    private fun visible(slug: String, i: Int): Double {
        val t = Rect().also { find("v14-$slug-trail$i")!!.getBoundsInScreen(it) }
        val box = Rect().also { find("v14-$slug-list")!!.getBoundsInScreen(it) }
        val notice = Rect().also { find("v14-$slug-notice")!!.getBoundsInScreen(it) }
        val top = maxOf(t.top, box.top, 0); val bottom = minOf(t.bottom, box.bottom, device.displayHeight)
        if (bottom <= top) return 0.0
        val hidden = maxOf(0, minOf(bottom, notice.bottom) - maxOf(top, notice.top))
        return (bottom - top - hidden).toDouble() / t.height()
    }

    private fun walkTrails(slug: String): List<Double> {
        open(slug)
        tabTo(slug, "back")
        val seen = (1..6).map { i ->
            tabTo(slug, "trail$i", 1)
            Thread.sleep(500)
            visible(slug, i)
        }
        Log.i("V14", "android $slug visible: ${seen.joinToString { "%.2f".format(it) }}")
        return seen
    }

    @Test
    fun goodNoticeBelowKeepsEveryFocusedTrailInSight() {
        for ((i, v) in walkTrails("good-notice-below").withIndex()) assertEquals("trail${i + 1}", 1.0, v, 0.03)
    }

    @Test
    fun badNoticeOverListHidesTrailsFourToSix() {
        val seen = walkTrails("bad-notice-over-list")
        // The positive control, through the same measure.
        assertEquals(1.0, seen[0], 0.03)
        assertEquals(1.0, seen[1], 0.03)
        // Written to fail if Flutter starts to scroll a focused control out
        // from under what is drawn over its view.
        for (i in listOf(4, 5, 6)) assertEquals("trail$i", 0.0, seen[i - 1], 0.0)
    }

    /**
     * L4. Moves TalkBack focus to each control and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running. Focus indicators are not spoken: this records what each
     * control is to TalkBack.
     */
    @Test
    fun talkBackWalk() {
        val walk: List<Pair<String, List<Stop>>> =
            CONTROLS.map { (slug, controls) ->
                slug to controls.map { (c) -> Stop("v14-$slug-$c") { nodeInAnyWindow("v14-$slug-$c") } }
            } + NOTICE.map { slug ->
                // Trails in the tree when the example opens: in
                // good-notice-below the last three are scrolled out of the
                // box, and in bad-notice-over-list trail 4 is under the
                // notice.
                val trails = if (slug == "good-notice-below") listOf(1, 3) else listOf(1, 4)
                slug to trails.map { i -> Stop("v14-$slug-trail$i") { nodeInAnyWindow("v14-$slug-trail$i") } }
            }
        talkBackWalk(walk, open = { slug -> openExampleInAnyWindow(slug) { it.viewIdResourceName == "v14-$slug-${first(slug)}" } }, dwellMillis = { 3_000 })
    }
}
