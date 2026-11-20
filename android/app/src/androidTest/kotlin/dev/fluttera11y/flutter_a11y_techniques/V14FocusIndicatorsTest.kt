// L3 (tree, keyboard, and pixels) and L4 (TalkBack walk) for V14 Focus
// indicators on Android.
// Spec: docs/specs/V14-focus-indicators.md.
//
// Keys come from a keyboard the test registers with the shell's `uinput`
// tool (Keyboard, below), so that they arrive as a hardware keyboard's,
// from a device with an id of its own. Keys sent with `input keyevent`,
// Instrumentation.sendKeySync, or UiAutomation.injectInputEvent all arrive
// with the virtual keyboard's id (-1), and Flutter does not let a key from
// it turn its focus highlights on (FL-433;
// docs/evidence/probes/v14/README.md, rounds 1 to 6). The keyboard is a
// device of its own, so this does not depend on the emulator's hardware
// keyboard setting. The FL-433 test uses `input keyevent` on purpose.
//
// What focus draws is read from UiAutomation.takeScreenshot: one screenshot
// before Tab reaches a control and two after, 700 ms apart once the screen
// has stopped changing. The pixels round the control that changed in both
// and agree are what focus drew, and their contrast is taken against the
// colours next to them in the focused screenshot (compare, below), never
// from the theme. Each stop is the node that reports isFocused.
package dev.fluttera11y.flutter_a11y_techniques

import android.app.UiAutomation
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.ParcelFileDescriptor
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
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
    "bad-checked-checkbox" to listOf(Triple("alerts", "Weather alerts", CHECKBOX)),
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

/** Two colours are one flat colour if no channel differs by more than this. */
private const val FLAT = 4

/** An anti-aliased edge is read across at most this many pixels. */
private const val BLUR = 4

/**
 * How many strong pixels, at a density of 1, a good control's indicator must
 * have in these tests: about a line one pixel wide round a 40 by 40 control.
 * The tests' own threshold, kept apart from the contrast measure: 1.4.11 sets
 * no size (2.4.13, AAA, does).
 */
private const val OUR_MINIMUM = 150

/**
 * One band of what focus drew: a connected area of one flat colour (or of
 * shades each within [FLAT] of the next), drawn mostly where the page was
 * before focus or mostly on the control. [contrast] is its lowest against any
 * neighbour it must contrast with, [lowest] that neighbour, and [next] its
 * commonest neighbours with how many of its edge's pixels touch them.
 */
private class Band(
    val colour: Int, val onPage: Boolean, val pixels: Int, val contrast: Double, val lowest: Int,
    val next: List<Pair<Int, Int>>,
) {
    override fun toString(): String {
        val total = maxOf(1, next.sumOf { it.second })
        return "$pixels px ${hex(colour)} ${if (onPage) "on the page" else "on the control"} " +
            "${"%.2f".format(contrast)} against ${hex(lowest)}; next to it " +
            next.take(2).joinToString { "${hex(it.first)} ${"%.2f".format(contrast(colour, it.first))} ${100 * it.second / total}%" }
    }
}

/** What focus drew in a region (see [compare]). */
private class Indicator(
    val changed: Int, val unstable: Int, val swapped: Int, val strong: Int, val page: Int, val bands: List<Band>,
) {
    /** Every changed pixel, whatever it replaced. */
    val indicator: Int get() = changed

    /** Indicator pixels in bands: all but anti-aliased edges. */
    val flat: Int get() = bands.sumOf { it.pixels }

    /**
     * The drawing moved rather than focus adding to it: half or more of the
     * colours the changed pixels took were there before, among them.
     */
    val moved: Boolean get() = changed > 0 && swapped * 2 >= changed

    /** The largest band's contrast, or 1 if nothing was drawn. */
    val ratio: Double get() = bands.firstOrNull()?.contrast ?: 1.0

    override fun toString() = "changed $changed, unstable $unstable, swapped $swapped, indicator $changed, " +
        "in bands $flat, 3:1 or more: $strong, page ${hex(page)}; ${bands.take(3).joinToString("; ")}"
}

/** A screenshot's pixels, or a picture made up for a case of the measure, as 0xRRGGBB. */
private class Pixels(val width: Int, val height: Int, private val data: IntArray) {
    constructor(b: Bitmap) : this(b.width, b.height, IntArray(b.width * b.height).also { b.getPixels(it, 0, b.width, 0, 0, b.width, b.height) })
    fun at(x: Int, y: Int) = data[y * width + x] and 0xFFFFFF
}

private fun compare(ub: Bitmap, f1b: Bitmap, f2b: Bitmap, region: Rect): Indicator =
    compare(Pixels(ub), Pixels(f1b), Pixels(f2b), region)

/**
 * What focus drew in [region], given the screenshot before focus [u] and two
 * after it, [f1] and [f2]. The measure of the V14 spec, section 6, which
 * lists what it is known not to do; the widget tests' _compare is the same,
 * step for step.
 *
 * A pixel has changed if it differs from [u] in both and [f1] and [f2] agree.
 * Every changed pixel is part of the indicator, whatever it replaced:
 * Understanding 1.4.11 does not compare the focused and unfocused states.
 * (What replaced what is used once, to tell a drawing that moved from one
 * that focus added to: [Indicator.moved].)
 *
 * A pixel of [f1] is solid if it has a 4-neighbour of its colour (within
 * [FLAT]) and is not anti-aliasing: a pixel whose colour lies between the
 * colours either side of it, across or down or on a diagonal, where those two
 * differ. A one pixel line is solid. Solid changed pixels are joined into
 * bands: 4-connected, each within [FLAT] of the next. A band is on the page if
 * most of it was drawn where the page was before focus, and on the control if
 * not.
 *
 * Each band is taken against its neighbours, spatially: from every pixel on
 * its edge, outward, across pixels of the edge pixel's own colour and at most
 * [BLUR] pixels of an anti-aliased edge being crossed (each between the pixels
 * before and after it on the way), to the first solid pixel (or the last of
 * those [BLUR], so that no neighbour is passed over for being blurred, unless
 * focus drew it). A walk that meets a blurred pixel that is not between them,
 * but is a blend some other way, is going along an edge, not across it, and
 * finds nothing; a blurred pixel that is a blend no way is texture (a dither),
 * and is the neighbour. A band on the control, inside it or on its border, must
 * contrast with every neighbour found, whatever it is (Understanding: both
 * adjacent colours). A band on the page, outside the control, must contrast
 * with the background: the walk goes on across the rest of what focus drew,
 * and a neighbour that was not the page before focus (the control itself) is
 * not one it must contrast with. A band's contrast is its lowest against any
 * of them (with none, against the page): the least contrasting part decides.
 * Its pixels are strong if that is 3:1 or more. The page's colour is the
 * commonest along the region's top and bottom edges in [u].
 */
private fun compare(u: Pixels, f1: Pixels, f2: Pixels, region: Rect): Indicator {
    val l = maxOf(0, region.left); val t = maxOf(0, region.top)
    val r = minOf(u.width, region.right); val b = minOf(u.height, region.bottom)
    val w = r - l; val h = b - t
    fun inside(x: Int, y: Int) = x >= l && x < r && y >= t && y < b
    fun at(x: Int, y: Int) = (y - t) * w + (x - l)
    val edge = HashMap<Int, Int>()
    for (x in l until r) for (y in listOf(t, t + 1, b - 2, b - 1)) edge.merge(u.at(x, y), 1, Int::plus)
    var page = 0; var most = -1
    for ((c, n) in edge) if (n > most || (n == most && c < page)) { page = c; most = n }
    val isChanged = BooleanArray(w * h)
    var changed = 0; var unstable = 0
    val newColours = HashMap<Int, Int>(); val oldColours = HashMap<Int, Int>()
    for (y in t until b) for (x in l until r) {
        val a = u.at(x, y); val p = f1.at(x, y); val q = f2.at(x, y)
        val d1 = channelDiff(a, p) > THRESHOLD; val d2 = channelDiff(a, q) > THRESHOLD
        if (d1 && d2 && channelDiff(p, q) <= THRESHOLD) {
            changed++
            isChanged[at(x, y)] = true
            newColours.merge(p, 1, Int::plus); oldColours.merge(a, 1, Int::plus)
        } else if (d1 || d2) unstable++
    }
    fun same(x: Int, y: Int, c: Int) = inside(x, y) && channelDiff(f1.at(x, y), c) <= FLAT
    fun between(c: Int, a: Int, z: Int) = listOf(16, 8, 0).all { s ->
        val v = (c shr s) and 255; val p = (a shr s) and 255; val q = (z shr s) and 255
        v >= minOf(p, q) - FLAT && v <= maxOf(p, q) + FLAT
    }
    // Whether (x, y) lies between the pixels either side of it along (dx, dy):
    // a pixel of an anti-aliased edge crossed that way.
    fun blendAlong(x: Int, y: Int, dx: Int, dy: Int): Boolean {
        if (!inside(x - dx, y - dy) || !inside(x + dx, y + dy)) return false
        val c = f1.at(x, y); val a = f1.at(x - dx, y - dy); val z = f1.at(x + dx, y + dy)
        return channelDiff(a, z) > THRESHOLD && channelDiff(c, a) > FLAT && channelDiff(c, z) > FLAT && between(c, a, z)
    }
    fun blend(x: Int, y: Int) =
        blendAlong(x, y, 1, 0) || blendAlong(x, y, 0, 1) || blendAlong(x, y, 1, 1) || blendAlong(x, y, 1, -1)
    val solidAt = BooleanArray(w * h)
    for (y in t until b) for (x in l until r) {
        val c = f1.at(x, y)
        solidAt[at(x, y)] = (same(x - 1, y, c) || same(x + 1, y, c) || same(x, y - 1, c) || same(x, y + 1, c)) && !blend(x, y)
    }
    fun onPageAt(x: Int, y: Int) = channelDiff(u.at(x, y), page) <= THRESHOLD
    // The neighbour of the edge pixel (x0, y0) in the direction (dx, dy).
    fun neighbour(x0: Int, y0: Int, dx: Int, dy: Int, onPage: Boolean): Int? {
        val c0 = f1.at(x0, y0)
        var x = x0; var y = y0; var blurred = 0
        while (true) {
            x += dx; y += dy
            if (!inside(x, y)) return null
            if (channelDiff(f1.at(x, y), c0) <= FLAT) continue
            if (onPage && isChanged[at(x, y)]) continue
            if (solidAt[at(x, y)]) return if (onPage && !onPageAt(x, y)) null else f1.at(x, y)
            if (!blendAlong(x, y, dx, dy)) {
                // A blend some other way is the side of an anti-aliased edge that
                // runs along the way, not one being crossed: the neighbour beyond it
                // is found by the walks that cross it.
                if (blend(x, y)) return null
                // A blend no way is texture (a dither, a pattern), not
                // anti-aliasing: it is the neighbour.
                return if (onPage && !onPageAt(x, y)) null else f1.at(x, y)
            }
            if (++blurred == BLUR) {
                // Blurred all the way: what is there, if focus did not draw it.
                return if (isChanged[at(x, y)] || (onPage && !onPageAt(x, y))) null else f1.at(x, y)
            }
        }
    }
    val ratios = HashMap<Long, Double>()
    fun ratio(a: Int, c: Int) = ratios.getOrPut((a.toLong() shl 32) or c.toLong()) { contrast(a, c) }
    val steps = listOf(1 to 0, -1 to 0, 0 to 1, 0 to -1)
    val bandOf = IntArray(w * h) { -1 }
    val bands = mutableListOf<Pair<Band, Int>>()
    var strong = 0
    for (y0 in t until b) for (x0 in l until r) {
        val i0 = at(x0, y0)
        if (!isChanged[i0] || !solidAt[i0] || bandOf[i0] >= 0) continue
        val id = bands.size
        val pixels = mutableListOf(x0 to y0)
        bandOf[i0] = id
        var k = 0
        while (k < pixels.size) {
            val (x, y) = pixels[k++]
            for ((dx, dy) in steps) {
                val nx = x + dx; val ny = y + dy
                if (!inside(nx, ny)) continue
                val j = at(nx, ny)
                if (!isChanged[j] || !solidAt[j] || bandOf[j] >= 0) continue
                if (channelDiff(f1.at(nx, ny), f1.at(x, y)) > FLAT) continue
                bandOf[j] = id
                pixels.add(nx to ny)
            }
        }
        val onPage = pixels.count { (x, y) -> onPageAt(x, y) } * 2 > pixels.size
        var contrast = Double.POSITIVE_INFINITY; var lowest = page
        val next = HashMap<Int, Int>()
        for ((x, y) in pixels) for ((dx, dy) in steps) {
            if (inside(x + dx, y + dy) && bandOf[at(x + dx, y + dy)] == id) continue
            val n = neighbour(x, y, dx, dy, onPage) ?: continue
            next.merge(n, 1, Int::plus)
            val c = ratio(f1.at(x, y), n)
            if (c < contrast) { contrast = c; lowest = n }
        }
        val counts = HashMap<Int, Int>()
        for ((x, y) in pixels) counts.merge(f1.at(x, y), 1, Int::plus)
        var colour = 0; var top = -1
        for ((c, n) in counts) if (n > top || (n == top && c < colour)) { colour = c; top = n }
        if (next.isEmpty()) { contrast = ratio(colour, page); lowest = page }
        if (contrast >= 3) strong += pixels.size
        val sorted = next.entries.sortedWith(compareByDescending<Map.Entry<Int, Int>> { it.value }.thenBy { it.key })
        bands.add(Band(colour, onPage, pixels.size, contrast, lowest, sorted.take(3).map { it.key to it.value }) to id)
    }
    bands.sortWith(compareByDescending<Pair<Band, Int>> { it.first.pixels }.thenBy { it.second })
    val swapped = newColours.entries.sumOf { (c, n) -> minOf(n, oldColours[c] ?: 0) }
    return Indicator(changed, unstable, swapped, strong, page, bands.map { it.first })
}

/** A case's picture: its [layers] painted in order on white at pixel ratio [s] (the case file says how). */
private fun paint(layers: JSONArray, width: Int, height: Int, s: Int): Pixels {
    val px = IntArray(width * height) { 0xFFFFFF }
    fun colourOf(h: String) = h.substring(1).toInt(16)
    for (i in 0 until layers.length()) {
        val layer = layers.getJSONObject(i)
        val rect = layer.optJSONArray("rect")
        val l = rect?.getInt(0)?.times(s) ?: 0; val t = rect?.getInt(1)?.times(s) ?: 0
        val r = rect?.getInt(2)?.times(s) ?: width; val b = rect?.getInt(3)?.times(s) ?: height
        val ring = layer.optInt("ring", 0) * s
        val byY = layer.optString("axis") == "y"
        for (y in t until b) for (x in l until r) {
            if (ring > 0 && x >= l + ring && x < r - ring && y >= t + ring && y < b - ring) continue
            val along = if (byY) y - t else x - l
            val length = if (byY) b - t else r - l
            val c = when {
                layer.has("checker") -> {
                    val pair = layer.getJSONArray("checker")
                    val p = layer.getInt("period") * s
                    colourOf(pair.getString(((x - l) / p + (y - t) / p) % 2))
                }
                layer.has("stripes") -> {
                    val stripes = layer.getJSONArray("stripes")
                    colourOf(stripes.getString((along / (layer.getInt("period") * s)) % stripes.length()))
                }
                layer.has("gradient") -> {
                    val ends = layer.getJSONArray("gradient")
                    val a = colourOf(ends.getString(0)); val z = colourOf(ends.getString(1))
                    val n = length - 1
                    listOf(16, 8, 0).fold(0) { acc, sh ->
                        acc or ((((a shr sh) and 255) * (n - along) + ((z shr sh) and 255) * along + n / 2) / n shl sh)
                    }
                }
                else -> colourOf(if (layer.has("colour")) layer.getString("colour") else layer.getString("fill"))
            }
            px[y * width + x] = c
        }
    }
    return Pixels(width, height, px)
}

/** What a case's measure at pixel ratio [s] gets wrong: none, if it passes. */
private fun checkCase(c: JSONObject, s: Int): List<String> {
    val size = c.getJSONArray("size")
    val w = size.getInt(0) * s; val h = size.getInt(1) * s
    val u = paint(c.getJSONArray("before"), w, h, s)
    val f1 = paint(c.getJSONArray("after"), w, h, s)
    val f2 = if (c.has("after2")) paint(c.getJSONArray("after2"), w, h, s) else f1
    val ind = compare(u, f1, f2, Rect(0, 0, w, h))
    val e = c.getJSONObject("expect")
    val problems = mutableListOf<String>()
    fun want(ok: Boolean, what: String) { if (!ok) problems.add("$what: $ind") }
    fun some(v: String, n: Int) = if (v == "none") n == 0 else n > 0
    if (e.has("changed")) want(some(e.getString("changed"), ind.changed), "changed ${e.getString("changed")}")
    if (e.has("unstable")) want(some(e.getString("unstable"), ind.unstable), "unstable ${e.getString("unstable")}")
    if (e.has("moved")) want(ind.moved == e.getBoolean("moved"), "moved ${e.getBoolean("moved")}")
    when (e.optString("strong")) {
        "all" -> want(ind.flat > 0 && ind.strong == ind.flat, "strong all")
        "none" -> want(ind.strong == 0, "strong none")
        "some" -> want(ind.strong > 0 && ind.strong < ind.flat, "strong some")
    }
    if (e.has("strongPixels")) want(ind.strong == e.getInt("strongPixels") * s * s, "strong pixels ${e.getInt("strongPixels") * s * s}")
    e.optJSONArray("ratio")?.let { want(Math.abs(ind.ratio - it.getDouble(0)) <= it.getDouble(1), "ratio ${it.getDouble(0)}") }
    if (e.has("ratioBelow")) want(ind.ratio < e.getDouble("ratioBelow"), "ratio below ${e.getDouble("ratioBelow")}")
    if (e.has("onPage")) want(ind.bands.isNotEmpty() && ind.bands[0].onPage == e.getBoolean("onPage"), "on the page ${e.getBoolean("onPage")}")
    return problems
}

/**
 * The measure's cases: a copy of test/techniques/v14_focus_indicators_measure_cases.json,
 * which the widget tests check is the same (the device cannot read the repository).
 */
private const val CASES = """
{
  "about": [
    "The cases of V14's pixel measure (docs/specs/V14-focus-indicators.md, section 6), on pictures made up for the purpose.",
    "The widget tests, the web spec, the iOS UI tests, and the probe analyser read this file; the Android test holds a copy, which the widget tests check is the same.",
    "A picture is its layers painted in order on white: fill, a rectangle [left, top, right, bottom], the outer 'ring' pixels of one, 'stripes' of colours one after another every 'period' pixels along an 'axis', a 'checker' of two colours in squares 'period' pixels wide, or a 'gradient' from one colour to another along an 'axis'.",
    "Each case is measured at each of its 'scales' (pixel ratios; every length is multiplied), with 'before' as the capture before focus and 'after' as both captures after it, unless 'after2' is given. The region is the whole picture.",
    "expect: 'changed' and 'unstable' are 'none' or 'some'; 'strong' is 'all' (every pixel of every band is in a band of 3:1 or more, and there is one), 'none', or 'some'; 'strongPixels' is the strong count at a pixel ratio of 1 (times the ratio squared); 'ratio' [value, tolerance], 'ratioBelow', and 'onPage' are of the largest band.",
    "Cases named 'known limit' show what the measure does where it is known to depart from 1.4.11; the spec lists them."
  ],
  "cases": [
    {
      "name": "Understanding figure 8: an inner yellow ring on the blue button passes, 3.55:1 against the blue",
      "size": [60, 60], "scales": [1, 3],
      "before": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}],
      "after": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [21, 26, 39, 34], "ring": 3, "colour": "#FFFF00"}],
      "expect": {"strong": "all", "ratio": [3.55, 0.05], "onPage": false}
    },
    {
      "name": "an outer yellow ring on the white page fails, 1.07:1",
      "size": [60, 60], "scales": [1, 3],
      "before": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}],
      "after": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [10, 15, 50, 45], "ring": 3, "colour": "#FFFF00"}],
      "expect": {"strong": "none", "ratioBelow": 1.1, "onPage": true}
    },
    {
      "name": "an outer green ring on the white page passes, 5.14:1",
      "size": [60, 60], "scales": [1, 3],
      "before": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}],
      "after": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [10, 15, 50, 45], "ring": 3, "colour": "#008000"}],
      "expect": {"strong": "all", "ratio": [5.14, 0.05], "onPage": true}
    },
    {
      "name": "Understanding figure 12: the button's edge turning green (#4B933A) fails: it is on the control and does not contrast with the blue inside",
      "size": [60, 60], "scales": [1, 3],
      "before": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}],
      "after": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [15, 20, 45, 40], "ring": 3, "colour": "#4B933A"}],
      "expect": {"strong": "none", "onPage": false}
    },
    {
      "name": "with a black border, an inner white border passes",
      "size": [60, 60], "scales": [1, 3],
      "before": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [15, 20, 45, 40], "ring": 2, "colour": "#000000"}],
      "after": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [15, 20, 45, 40], "ring": 2, "colour": "#000000"}, {"rect": [17, 22, 43, 38], "ring": 2, "colour": "#FFFFFF"}],
      "expect": {"strong": "all", "onPage": false}
    },
    {
      "name": "with a black border, an inner dark green border fails against the blue",
      "size": [60, 60], "scales": [1, 3],
      "before": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [15, 20, 45, 40], "ring": 2, "colour": "#000000"}],
      "after": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [15, 20, 45, 40], "ring": 2, "colour": "#000000"}, {"rect": [17, 22, 43, 38], "ring": 2, "colour": "#008000"}],
      "expect": {"strong": "none", "onPage": false}
    },
    {
      "name": "artwork that moves is not an indicator: the drawing moved",
      "size": [60, 60], "scales": [1],
      "before": [{"rect": [20, 20, 30, 30], "colour": "#000000"}],
      "after": [{"rect": [24, 20, 34, 30], "colour": "#000000"}],
      "expect": {"moved": true, "changed": "some"}
    },
    {
      "name": "nothing drawn is no indicator",
      "size": [60, 60], "scales": [1],
      "before": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}],
      "after": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}],
      "expect": {"changed": "none", "strong": "none", "moved": false}
    },
    {
      "name": "a mark in one capture only (a blinking caret) is unstable, not an indicator",
      "size": [60, 60], "scales": [1],
      "before": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}],
      "after": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}, {"rect": [30, 22, 31, 38], "colour": "#000000"}],
      "after2": [{"rect": [15, 20, 45, 40], "colour": "#4189B9"}],
      "expect": {"changed": "none", "unstable": "some"}
    },
    {
      "name": "the first review's reproduction: a 3 pixel border of #4B933A round an inside of three near-identical shades, in thirds, fails against them",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "stripes": ["#4189B9", "#428ABA", "#438BBB"], "axis": "x", "period": 67}],
      "after": [{"rect": [8, 8, 208, 68], "stripes": ["#4189B9", "#428ABA", "#438BBB"], "axis": "x", "period": 67}, {"rect": [8, 8, 208, 68], "ring": 3, "colour": "#4B933A"}],
      "expect": {"strong": "none", "ratioBelow": 1.1, "onPage": false}
    },
    {
      "name": "the same border round the same shades dithered pixel by pixel across fails",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "stripes": ["#4189B9", "#428ABA", "#438BBB"], "axis": "x", "period": 1}],
      "after": [{"rect": [8, 8, 208, 68], "stripes": ["#4189B9", "#428ABA", "#438BBB"], "axis": "x", "period": 1}, {"rect": [8, 8, 208, 68], "ring": 3, "colour": "#4B933A"}],
      "expect": {"strong": "none", "ratioBelow": 1.1}
    },
    {
      "name": "the same border round the same shades dithered row by row fails",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "stripes": ["#4189B9", "#428ABA", "#438BBB"], "axis": "y", "period": 1}],
      "after": [{"rect": [8, 8, 208, 68], "stripes": ["#4189B9", "#428ABA", "#438BBB"], "axis": "y", "period": 1}, {"rect": [8, 8, 208, 68], "ring": 3, "colour": "#4B933A"}],
      "expect": {"strong": "none", "ratioBelow": 1.1}
    },
    {
      "name": "the third review's reproduction: the same border round a one pixel checkerboard of #4189B9 and #4783BF fails against them (1.01:1 and 1.05:1): a texture is not anti-aliasing",
      "size": [216, 76], "scales": [1, 2, 3],
      "before": [{"rect": [8, 8, 208, 68], "checker": ["#4189B9", "#4783BF"], "period": 1}],
      "after": [{"rect": [8, 8, 208, 68], "checker": ["#4189B9", "#4783BF"], "period": 1}, {"rect": [8, 8, 208, 68], "ring": 3, "colour": "#4B933A"}],
      "expect": {"strong": "none", "ratioBelow": 1.1, "onPage": false}
    },
    {
      "name": "a black border round the same checkerboard passes against both its colours and the page",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "checker": ["#4189B9", "#4783BF"], "period": 1}],
      "after": [{"rect": [8, 8, 208, 68], "checker": ["#4189B9", "#4783BF"], "period": 1}, {"rect": [8, 8, 208, 68], "ring": 3, "colour": "#000000"}],
      "expect": {"strong": "all", "onPage": false}
    },
    {
      "name": "a thick border, 8 pixels of #4B933A on the blue, fails",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [8, 8, 208, 68], "ring": 8, "colour": "#4B933A"}],
      "expect": {"strong": "none", "onPage": false}
    },
    {
      "name": "a thick black border, 8 pixels on the blue, passes against the page and the blue",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [8, 8, 208, 68], "ring": 8, "colour": "#000000"}],
      "expect": {"strong": "all", "ratio": [5.5, 0.05], "onPage": false}
    },
    {
      "name": "a grey (#767676) inner ring on a button shaded from white to blue fails: its least contrasting neighbour, near the blue end, is 1.24:1, though near the white end it is 4.2:1 or more",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "gradient": ["#FFFFFF", "#4189B9"], "axis": "x"}],
      "after": [{"rect": [8, 8, 208, 68], "gradient": ["#FFFFFF", "#4189B9"], "axis": "x"}, {"rect": [14, 14, 202, 62], "ring": 3, "colour": "#767676"}],
      "expect": {"strong": "none", "ratioBelow": 1.3, "onPage": false}
    },
    {
      "name": "a black inner ring on the same shaded button passes against every shade",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "gradient": ["#FFFFFF", "#4189B9"], "axis": "x"}],
      "after": [{"rect": [8, 8, 208, 68], "gradient": ["#FFFFFF", "#4189B9"], "axis": "x"}, {"rect": [14, 14, 202, 62], "ring": 3, "colour": "#000000"}],
      "expect": {"strong": "all", "onPage": false}
    },
    {
      "name": "an inner black ring that contrasts with the page but not with the navy button it is on fails, 1.47:1",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#1F2A44"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#1F2A44"}, {"rect": [11, 11, 205, 65], "ring": 3, "colour": "#000000"}],
      "expect": {"strong": "none", "ratioBelow": 1.5, "onPage": false}
    },
    {
      "name": "a faint halo on the page round a black box does not take the box's contrast: it fails against the page",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [88, 18, 128, 58], "colour": "#000000"}],
      "after": [{"rect": [78, 8, 138, 68], "colour": "#EAE8F4"}, {"rect": [88, 18, 128, 58], "colour": "#000000"}],
      "expect": {"strong": "none", "ratioBelow": 1.5, "onPage": true}
    },
    {
      "name": "a faint tint on the page inside a black ring does not take the ring's contrast: the ring passes and the tint fails",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [60, 28, 156, 48], "colour": "#4189B9"}],
      "after": [{"rect": [20, 10, 196, 66], "ring": 2, "colour": "#000000"}, {"rect": [22, 12, 194, 64], "colour": "#EAE8F4"}, {"rect": [60, 28, 156, 48], "colour": "#4189B9"}],
      "expect": {"strong": "some", "strongPixels": 912, "ratioBelow": 1.5, "onPage": true}
    },
    {
      "name": "a two-colour ring on the page: the black outer part passes and the yellow inner part fails against the page",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [10, 10, 206, 66], "colour": "#4189B9"}],
      "after": [{"rect": [10, 10, 206, 66], "colour": "#4189B9"}, {"rect": [4, 4, 212, 72], "ring": 2, "colour": "#000000"}, {"rect": [6, 6, 210, 70], "ring": 2, "colour": "#FFFF00"}],
      "expect": {"strong": "some", "strongPixels": 1088, "ratio": [21, 0.01], "onPage": true}
    },
    {
      "name": "a one pixel black underline below a button passes, 21:1 against the page",
      "size": [216, 76], "scales": [1, 2, 3],
      "before": [{"rect": [8, 8, 208, 60], "colour": "#4189B9"}],
      "after": [{"rect": [8, 8, 208, 60], "colour": "#4189B9"}, {"rect": [8, 63, 208, 64], "colour": "#000000"}],
      "expect": {"strong": "all", "strongPixels": 200, "ratio": [21, 0.01], "onPage": true}
    },
    {
      "name": "a one pixel black outline round a button passes, 21:1 against the page",
      "size": [216, 76], "scales": [1, 2, 3],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [5, 5, 211, 71], "ring": 1, "colour": "#000000"}],
      "expect": {"strong": "all", "strongPixels": 540, "ratio": [21, 0.01], "onPage": true}
    },
    {
      "name": "an outer ring that touches a navy button passes on the page, though it does not contrast with the button",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#1F2A44"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#1F2A44"}, {"rect": [5, 5, 211, 71], "ring": 3, "colour": "#000000"}],
      "expect": {"strong": "all", "ratio": [21, 0.01], "onPage": true}
    },
    {
      "name": "a black border made thicker passes: the part of the same colour that was there is not a neighbour",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [8, 8, 208, 68], "ring": 1, "colour": "#000000"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [8, 8, 208, 68], "ring": 3, "colour": "#000000"}],
      "expect": {"strong": "all", "onPage": false}
    },
    {
      "name": "a black ring with anti-aliased grey edges passes; the grey edge pixels are left out",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [2, 2, 214, 74], "ring": 1, "colour": "#808080"}, {"rect": [3, 3, 213, 73], "ring": 3, "colour": "#000000"}, {"rect": [6, 6, 210, 70], "ring": 1, "colour": "#808080"}],
      "expect": {"strong": "all", "ratio": [21, 0.01], "onPage": true}
    },
    {
      "name": "at a pixel ratio of 1, an olive line on a navy button's top edge passes against the page and the navy, though the edge's anti-aliased fade, a blend of the two, runs on from its end at about 1.1:1 against the line: a walk along the fade, not across it, finds nothing",
      "size": [216, 76], "scales": [1],
      "before": [{"rect": [8, 9, 208, 68], "colour": "#1F2A44"}, {"rect": [8, 8, 100, 9], "colour": "#1F2A44"}, {"rect": [100, 8, 122, 9], "gradient": ["#848A98", "#FFFFFF"], "axis": "x"}],
      "after": [{"rect": [8, 9, 208, 68], "colour": "#1F2A44"}, {"rect": [8, 8, 100, 9], "colour": "#8A8A20"}, {"rect": [100, 8, 122, 9], "gradient": ["#848A98", "#FFFFFF"], "axis": "x"}],
      "expect": {"strong": "all", "strongPixels": 92, "onPage": false}
    },
    {
      "name": "known limit: a change of the control's own background is measured like any other part, though 1.4.11 leaves it out: a fill darkened to #2E6A94, 5.82:1 against the page and the white label, passes",
      "size": [216, 76], "scales": [1],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [60, 30, 156, 46], "colour": "#FFFFFF"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#2E6A94"}, {"rect": [60, 30, 156, 46], "colour": "#FFFFFF"}],
      "expect": {"strong": "all", "onPage": false}
    },
    {
      "name": "known limit: at a pixel ratio of 1, a one pixel strip along the top and bottom whose colour lies between the colours either side of it is read as anti-aliasing, and the ring is taken against the blue beyond it",
      "size": [216, 76], "scales": [1],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [12, 12, 204, 64], "ring": 3, "colour": "#000000"}, {"rect": [16, 15, 200, 16], "colour": "#2A5A7A"}, {"rect": [16, 60, 200, 61], "colour": "#2A5A7A"}],
      "expect": {"strong": "all", "strongPixels": 1428, "onPage": false}
    },
    {
      "name": "at a pixel ratio of 2 the same strips are two pixels wide and are measured: the ring fails against them, 2.84:1",
      "size": [216, 76], "scales": [2],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [12, 12, 204, 64], "ring": 3, "colour": "#000000"}, {"rect": [16, 15, 200, 16], "colour": "#2A5A7A"}, {"rect": [16, 60, 200, 61], "colour": "#2A5A7A"}],
      "expect": {"strong": "none", "onPage": false}
    },
    {
      "name": "known limit: the least contrasting neighbour decides a whole band: an inner ring that meets a small navy mark for 4 pixels fails all round",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [100, 15, 104, 17], "colour": "#1F2A44"}],
      "after": [{"rect": [8, 8, 208, 68], "colour": "#4189B9"}, {"rect": [100, 15, 104, 17], "colour": "#1F2A44"}, {"rect": [12, 12, 204, 64], "ring": 3, "colour": "#000000"}],
      "expect": {"strong": "none", "onPage": false}
    },
    {
      "name": "known limit: the page is one colour: a ring outside a control but on a grey card is held to a border's rule, and fails against the navy control",
      "size": [216, 76], "scales": [1, 2],
      "before": [{"rect": [4, 4, 212, 72], "colour": "#E0E0E0"}, {"rect": [12, 12, 204, 64], "colour": "#1F2A44"}],
      "after": [{"rect": [4, 4, 212, 72], "colour": "#E0E0E0"}, {"rect": [12, 12, 204, 64], "colour": "#1F2A44"}, {"rect": [9, 9, 207, 67], "ring": 3, "colour": "#000000"}],
      "expect": {"strong": "none", "onPage": false}
    }
  ]
}
"""

/**
 * A USB keyboard registered with the shell's `uinput` tool for as long as
 * the session is open. Its keys reach the app through the kernel, as a
 * real keyboard's do, with the device id Android gives the new device.
 * Closing the session removes the device.
 */
private class Keyboard(automation: UiAutomation, dumpsys: () -> String) : AutoCloseable {
    private val fds: Array<ParcelFileDescriptor> = automation.executeShellCommandRw("uinput -")
    private val stdin = ParcelFileDescriptor.AutoCloseOutputStream(fds[1])

    init {
        send("""{"id":1,"command":"register","name":"$NAME","vid":4660,"pid":22136,"bus":"usb",""" +
            """"configuration":[{"type":"UI_SET_EVBIT","data":["EV_KEY","EV_SYN"]},""" +
            """{"type":"UI_SET_KEYBIT","data":["KEY_TAB","KEY_SPACE","KEY_ENTER","KEY_LEFTSHIFT"]}]}""")
        // Android has to have configured the device before its keys count.
        val end = System.currentTimeMillis() + 10_000
        while (!dumpsys().contains(NAME)) {
            if (System.currentTimeMillis() > end) throw AssertionError("the uinput keyboard was not registered")
            Thread.sleep(200)
        }
        Thread.sleep(1_000)
    }

    private fun send(json: String) {
        stdin.write((json + "\n").toByteArray())
        stdin.flush()
    }

    /** Presses and releases [key], a Linux key name such as KEY_TAB. */
    fun press(key: String) = send(
        """{"id":1,"command":"inject","events":["EV_KEY","$key",1,"EV_SYN","SYN_REPORT",0,""" +
            """"EV_KEY","$key",0,"EV_SYN","SYN_REPORT",0]}""")

    override fun close() {
        stdin.close()
        ParcelFileDescriptor.AutoCloseInputStream(fds[0]).use { it.readBytes() }
    }

    companion object {
        const val NAME = "V14 test keyboard"
    }
}

@RunWith(AndroidJUnit4::class)
class V14FocusIndicatorsTest : TechniqueTest("V14") {
    private val density = inst.targetContext.resources.displayMetrics.density

    /** The pixels a measure of `n` logical pixels squared is. */
    private fun area(n: Int) = n * density * density

    private fun first(slug: String) = if (slug in NOTICE) "trail1" else CONTROLS.getValue(slug).first().first

    /**
     * Opens [slug]. With [keys], the keyboard is registered first, so that
     * the screen is captured with it already in place (Android may draw its
     * own mark at the edges of the screen once a keyboard has been used,
     * which the regions measured do not reach).
     */
    private fun open(slug: String, keys: Boolean = true) {
        if (keys && keyboard == null) {
            keyboard = Keyboard(automation) { device.executeShellCommand("dumpsys input") }
        }
        openExample(slug, By.res("v14-$slug-${first(slug)}"), settleMillis = 1_000)
    }

    private var keyboard: Keyboard? = null

    /** Presses KEY_[name] on the registered keyboard, registering it first if need be. */
    private fun key(name: String) {
        val k = keyboard ?: Keyboard(automation) { device.executeShellCommand("dumpsys input") }.also { keyboard = it }
        k.press("KEY_$name")
        Thread.sleep(500)
    }

    /** The same key from `input keyevent`, the virtual keyboard's (FL-433). */
    private fun virtualKey(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(500)
    }

    @After
    fun removeKeyboard() {
        keyboard?.close()
        keyboard = null
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

    /**
     * Tabs to [c] (one Tab on from where focus is) and measures what changed
     * round [id] against [before]. The control must be wholly on the screen
     * and must not move: a control that moved (scrolled into view by Tab,
     * say) would show its own drawing moved as a change, so the test fails
     * instead, and so it does if what changed is a drawing that moved.
     */
    private fun measureAfterTab(slug: String, c: String, id: String, before: Bitmap): Indicator {
        val where = bounds(id)
        assertTrue("$id is wholly on the screen: $where", where.top >= 0 && where.bottom <= device.displayHeight)
        tabTo(slug, c, 1)
        assertEquals("$id did not move", where, bounds(id))
        val r = Rect(where).apply { val m = (8 * density).toInt(); inset(-m, -m) }
        val f1 = settled(r)
        Thread.sleep(700)
        val ind = compare(before, f1, shot(), r)
        assertTrue("the drawing moved: $ind", !ind.moved)
        return ind
    }

    @Test
    fun theContrastRatioIsWcags() {
        assertEquals(21.0, contrast(0xFFFFFF, 0x000000), 0.001)
        assertEquals(4.54, contrast(0x767676, 0xFFFFFF), 0.01)
    }

    /** The measure on its cases, the same list as the widget tests and the web spec run. */
    @Test
    fun theMeasuresCases() {
        val cases = JSONObject(CASES).getJSONArray("cases")
        val problems = mutableListOf<String>()
        var run = 0
        for (i in 0 until cases.length()) {
            val c = cases.getJSONObject(i)
            val scales = c.getJSONArray("scales")
            for (k in 0 until scales.length()) {
                val s = scales.getInt(k)
                run++
                checkCase(c, s).forEach { problems.add("${c.getString("name")} (pixel ratio $s): $it") }
            }
        }
        Log.i("V14", "android the measure: $run cases run, ${problems.size} problems")
        assertTrue(problems.joinToString("\n"), problems.isEmpty())
    }

    @Test
    fun everyControlHasItsNameAndClass() {
        for ((slug, controls) in CONTROLS) {
            open(slug, keys = false)
            for ((c, name, type) in controls) {
                val node = revealed("v14-$slug-$c")
                assertEquals("$slug $c", name, node.name())
                assertEquals("$slug $c", type, node.type())
                assertTrue("$slug $c", !node.isFocused)
            }
        }
        for (slug in NOTICE) {
            open(slug, keys = false)
            for ((i, trail) in TRAILS.withIndex()) {
                val node = trail(slug, i + 1)
                assertEquals(slug, trail, node.name())
                assertEquals(slug, BUTTON, node.type())
            }
        }
    }

    @Test
    fun goodControlsDrawAnIndicatorOf3To1WhichGoesWhenFocusMovesOn() {
        for (slug in listOf("good-material", "good-cupertino", "good-widgets")) {
            open(slug)
            tabTo(slug, "back")
            val controls = CONTROLS.getValue(slug)
            var lastBefore: Bitmap? = null
            for ((c) in controls) {
                val id = "v14-$slug-$c"
                lastBefore = settled(region(id))
                val ind = measureAfterTab(slug, c, id, lastBefore)
                Log.i("V14", "android $slug $c: $ind")
                assertTrue("$slug $c: $ind", ind.strong > area(OUR_MINIMUM))
            }
            // Off again: Tab on from the last control, and its region is as
            // it was before it had focus.
            val lastId = "v14-$slug-${controls.last().first}"
            key("TAB")
            assertNotEquals(slug, controls.last().first, stop(slug))
            val r = region(lastId)
            val off = settled(r)
            val gone = compare(lastBefore!!, off, off, r)
            assertEquals("$slug after focus left: $gone", 0, gone.changed)
        }
    }

    @Test
    fun badIndicatorRemovedDrawsNothingAndBackDoes() {
        val slug = "bad-indicator-removed"
        open(slug)
        val saveId = "v14-$slug-save"
        val before = settled(region(saveId))
        // The positive control: Tab to Back changes pixels round it, through
        // the same measure.
        tabTo(slug, "back")
        val backRegion = Rect().also { named("Back").getBoundsInScreen(it) }
            .apply { val m = (8 * density).toInt(); inset(-m, -m) }
        val onBack = compare(before, settled(backRegion), shot(), backRegion)
        Log.i("V14", "android $slug back: $onBack")
        assertTrue("Back: $onBack", onBack.indicator > area(100))
        val onSave = measureAfterTab(slug, "save", saveId, before)
        Log.i("V14", "android $slug save: $onSave")
        // Written to fail if a FilledButton starts to show focus some other way.
        assertEquals("Save: $onSave", 0, onSave.changed)
        assertEquals("Save: $onSave", 0, onSave.unstable)
    }

    private fun measureFirst(slug: String, c: String): Indicator {
        open(slug)
        val id = "v14-$slug-$c"
        val before = settled(region(id))
        tabTo(slug, "back")
        return measureAfterTab(slug, c, id, before)
    }

    @Test
    fun badCheckedCheckboxHaloIsUnder3To1() {
        val ind = measureFirst("bad-checked-checkbox", "alerts")
        Log.i("V14", "android bad-checked-checkbox: $ind")
        assertTrue("$ind", ind.indicator > area(500))
        assertTrue("the halo is on the page: $ind", ind.bands.first().onPage)
        // Written to fail if Flutter makes the halo stand out, or adds
        // anything else at 3:1.
        assertTrue("$ind", ind.ratio < 1.5)
        assertTrue("$ind", ind.strong < ind.indicator * 0.02)
    }

    @Test
    fun badCupertinoRingIsUnder3To1() {
        val ind = measureFirst("bad-cupertino-ring", "save")
        Log.i("V14", "android bad-cupertino-ring: $ind")
        assertTrue("$ind", ind.indicator > area(500))
        assertTrue("the ring is on the page: $ind", ind.bands.first().onPage)
        // Written to fail if Flutter darkens the ring, or adds anything
        // else at 3:1.
        assertTrue("$ind", ind.ratio < 3)
        assertTrue("$ind", ind.strong < ind.indicator * 0.02)
    }

    /**
     * FL-433, in one launch and through one measure: Tab from `input
     * keyevent`, the virtual keyboard's, moves focus to good-widgets' card
     * and draws nothing, because Flutter's highlights stay off; then Shift
     * alone from the registered keyboard, which moves no focus, turns them
     * on, and the card draws its ring.
     */
    @Test
    fun keysFromTheVirtualKeyboardLeaveTheHighlightsOff() {
        val slug = "good-widgets"
        open(slug)
        val id = "v14-$slug-trail"
        val before = settled(region(id))
        var tabs = 0
        while (stop(slug) != "trail" && tabs < 4) { virtualKey("TAB"); tabs++; Thread.sleep(500) }
        assertEquals("input keyevent Tab reaches the card", "trail", stop(slug))
        val r = region(id)
        val off = compare(before, settled(r), shot(), r)
        Log.i("V14", "android FL-433 after input keyevent: $off")
        assertEquals("$off", 0, off.changed)
        key("LEFTSHIFT")
        assertEquals("Shift moved no focus", "trail", stop(slug))
        val f1 = settled(r)
        Thread.sleep(700)
        val on = compare(before, f1, shot(), r)
        Log.i("V14", "android FL-433 after Shift from the registered keyboard: $on")
        assertTrue("$on", on.strong > area(OUR_MINIMUM))
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
