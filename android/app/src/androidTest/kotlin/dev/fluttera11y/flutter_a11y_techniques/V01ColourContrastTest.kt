// L3 (tree and pixels) and L4 (TalkBack walk) for V01 Colour contrast on
// Android. Spec: docs/specs/V01-colour-contrast.md, section 6.
//
// Every contrast here is read from UiAutomation.takeScreenshot, at the
// emulator's own pixel ratio, never from the theme. The measures are the
// widget tests' (test/techniques/v01_colour_contrast_test.dart), step for
// step: textContrast is _textContrast, edge is _edge, marks is _marks. Their
// lengths, given there in physical pixels at a pixel ratio of 3, are given
// here in logical pixels (dp) and multiplied by the emulator's density.
//
// Where a text is a node of its own (the body text, the captions) its box is
// the node's bounds, which are the paragraph's rectangle, as in the widget
// tests. Where a text is merged into its control's node (a field's label and
// hint, a tile's title, a button's text), Android's tree has no rectangle
// for it, so its box is found from the pixels of the control at rest
// (pieces, below): the bounding box of the pixels that differ from the
// commonest colour there by more than 12 in some channel, split where 8 dp
// of columns or more have none, 2 pixels larger on every side. The box found
// at rest is used for every other state of the same control, moved with the
// control's node. A Material outlined field's label is drawn on the field's
// top edge, half above its node, so it is found in a band round that edge
// with the edge left out (materialField). These are the steps that are not
// the widget tests'.
//
// Light and dark are the device's own setting, `cmd uimode night yes/no`
// from the test's shell (inModes): the test asserts the setting took, and a
// witness that the app follows it (the page's colour), and puts the setting
// back in a finally and asserts it is back.
//
// Keyboard focus comes from a keyboard the test registers with the shell's
// `uinput` tool, as V14 does (V01Keyboard, below): keys from the virtual
// keyboard do not turn Flutter's focus highlights on (FL-433). A press is a
// finger held down, injected with UiAutomation.injectInputEvent: ACTION_DOWN,
// a wait of 180 ms, past Flutter's 100 ms press timeout, the screenshot, then
// ACTION_UP, all under Flutter's 500 ms long-press time (pressed). The
// widget tests take theirs at 300 ms; here the screenshot is begun between
// 180 and 300 ms, so a pressed highlight that fades in may not be at its
// full strength. What could not be measured: hover (the emulator has no
// mouse pointer the tests can drive), and a press on the Cupertino field
// (the widget tests do not press it either: a tap focuses a field and can
// bring up the soft keyboard over the example).
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Bitmap
import android.graphics.Rect
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.app.UiAutomation
import android.util.Log
import android.view.InputDevice
import android.view.MotionEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import java.io.ByteArrayOutputStream
import kotlin.math.roundToInt
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val TAG = "V01"
private const val EDIT_TEXT = "android.widget.EditText"
private const val CHECKBOX = "android.widget.CheckBox"
private const val BUTTON = "android.widget.Button"
private const val RADIO = "android.widget.RadioButton"
private const val VIEW = "android.view.View"
private const val BODY = "We reply within two days."
private const val CAPTION = "Harbour"
private const val CALENDAR = "Calendar view"
private val VIEWS = listOf("Day", "Week", "Month")

/** Flutter's long-press time (kLongPressTimeout); a held press must end before it. */
private const val LONG_PRESS_MILLIS = 500L

/** How long a press is held before the screenshot: past Flutter's 100 ms press timeout. */
private const val HOLD_MILLIS = 180L

/** Screenshots of a press are begun no later than this after the finger went down. */
private const val PRESS_BUDGET_MILLIS = 300L

/** How many times a press is made, at most, when a try misses what is measured ([pressed]). */
private const val PRESS_TRIES = 3

/** Each example's title, as the app shows it in the app bar. */
private val TITLES = mapOf(
    "good-material" to "Material form at the theme's defaults",
    "good-cupertino" to "Cupertino field with stronger greys",
    "good-caption" to "Caption on a bar of its own",
    "good-selection" to "Choice shown by a shape",
    "bad-cupertino-placeholder" to "Default Cupertino placeholder",
    "bad-caption" to "Caption straight on the picture",
    "bad-colour-only" to "Choice shown by colour alone",
    "bad-faint-edge" to "Field with a faint edge",
)

// --- Pixels -----------------------------------------------------------------

private fun luminance(c: Int): Double {
    fun lin(v: Int): Double { val s = v / 255.0; return if (s <= 0.04045) s / 12.92 else Math.pow((s + 0.055) / 1.055, 2.4) }
    return 0.2126 * lin((c shr 16) and 255) + 0.7152 * lin((c shr 8) and 255) + 0.0722 * lin(c and 255)
}

/** WCAG's contrast ratio between two colours (0xRRGGBB). */
private fun ratio(a: Int, b: Int): Double {
    val x = luminance(a); val y = luminance(b)
    return (maxOf(x, y) + 0.05) / (minOf(x, y) + 0.05)
}

/** The largest difference between two colours in any channel. */
private fun diff(a: Int, b: Int) = maxOf(
    Math.abs(((a shr 16) and 255) - ((b shr 16) and 255)),
    Math.abs(((a shr 8) and 255) - ((b shr 8) and 255)),
    Math.abs((a and 255) - (b and 255)))

private fun hex(c: Int) = String.format("#%06X", c and 0xFFFFFF)

private fun f2(d: Double) = "%.2f".format(d)

/** A screenshot's pixels as 0xRRGGBB. */
private class V01Shot(val width: Int, val height: Int, private val px: IntArray) {
    constructor(b: Bitmap) : this(b.width, b.height, IntArray(b.width * b.height).also { b.getPixels(it, 0, b.width, 0, 0, b.width, b.height) })
    fun at(x: Int, y: Int) = px[y * width + x] and 0xFFFFFF
}

/** What the text measure found. */
private class V01Text(val colour: Int, val lowest: Double, val under: Int, val textPixels: Int, val core: Int) {
    override fun toString() =
        "text ${hex(colour)}, lowest ${f2(lowest)}:1 over ${hex(under)} ($core of $textPixels pixels the text colour)"
}

/**
 * The text measure (the spec, section 6, item 1; the widget tests'
 * _textContrast). [box] is the text's box in screenshot pixels. For each
 * column the colours round the text are the pixels 6 above the box and 6
 * below it; a pixel of the box that differs from both by more than 12 in
 * some channel is a text pixel; the text's colour is the commonest text pixel
 * (exact colour); and the contrast is the lowest, over every column with a
 * pixel of exactly that colour, of the text's colour against either colour
 * round it there. More than 20 text pixels are required.
 */
private fun textContrast(s: V01Shot, box: Rect): V01Text {
    val l = box.left; val r = box.right - 1; val t = box.top; val b = box.bottom - 1
    val above = t - 6; val below = b + 6
    assertTrue("box off the screen: $box", above >= 0 && below < s.height && l >= 0 && r < s.width)
    val counts = LinkedHashMap<Int, Int>()
    var textPixels = 0
    for (x in l..r) {
        val up = s.at(x, above); val down = s.at(x, below)
        for (y in t..b) {
            val c = s.at(x, y)
            if (diff(c, up) > 12 && diff(c, down) > 12) {
                textPixels++
                counts[c] = (counts[c] ?: 0) + 1
            }
        }
    }
    assertTrue("no text found in $box: $textPixels text pixels", textPixels > 20)
    // As the widget tests' reduce: on a tie the colour met first is kept.
    var colour = 0; var most = -1
    for ((c, n) in counts) if (n > most) { colour = c; most = n }
    var lowest = Double.POSITIVE_INFINITY; var under = 0
    for (x in l..r) {
        var has = false
        var y = t
        while (y <= b && !has) { has = s.at(x, y) == colour; y++ }
        if (!has) continue
        for (c in listOf(s.at(x, above), s.at(x, below))) {
            val q = ratio(colour, c)
            if (q < lowest) { lowest = q; under = c }
        }
    }
    return V01Text(colour, lowest, under, textPixels, most)
}

/** What the edge measure found. */
private class V01Edge(val start: Int, val edge: Int, val end: Int) {
    /** The edge against where the walk began (outside the control) and where it ended (inside). */
    val outside get() = ratio(edge, start)
    val inside get() = ratio(edge, end)
    override fun toString() = "edge ${hex(edge)}: ${f2(outside)}:1 against ${hex(start)}, ${f2(inside)}:1 against ${hex(end)}"
}

/**
 * The edge measure (section 6, item 2; _edge): from ([x0], [y0]), a pixel
 * outside the control, [steps] pixels in the direction ([dx], [dy]); the edge
 * is the pixel on the way that contrasts most with the first, taken against
 * the first and against the last.
 */
private fun edge(s: V01Shot, x0: Int, y0: Int, dx: Int, dy: Int, steps: Int): V01Edge {
    val start = s.at(x0, y0)
    var e = start
    for (i in 1..steps) {
        val c = s.at(x0 + dx * i, y0 + dy * i)
        if (ratio(c, start) > ratio(e, start)) e = c
    }
    return V01Edge(start, e, s.at(x0 + dx * steps, y0 + dy * steps))
}

/** The pixels of [area] that are 3:1 or more against [against] (section 6, item 3; _marks). */
private fun marks(s: V01Shot, area: Rect, against: Int): Int {
    var n = 0
    for (y in area.top until area.bottom) for (x in area.left until area.right) {
        if (ratio(s.at(x, y), against) >= 3) n++
    }
    return n
}

/** The commonest colour of [r]. */
private fun commonest(s: V01Shot, r: Rect): Int {
    val counts = HashMap<Int, Int>()
    for (y in r.top until r.bottom) for (x in r.left until r.right) counts.merge(s.at(x, y), 1, Int::plus)
    var colour = 0; var most = -1
    for ((c, n) in counts) if (n > most || (n == most && c < colour)) { colour = c; most = n }
    return colour
}

/**
 * What is drawn in [region]: the bounding boxes of the pixels that differ
 * from [bg] by more than [threshold] in some channel, split where [gap] or
 * more columns in a row have none, left to right. With [lineOver], a pixel in
 * a run of such pixels along a row that long or longer, or in a run that
 * reaches the region's left or right side, is left out first: a control's
 * edge, not a letter.
 */
private fun pieces(s: V01Shot, region: Rect, bg: Int, gap: Int, threshold: Int = 12, lineOver: Int? = null): List<Rect> {
    val w = region.width(); val h = region.height()
    val on = BooleanArray(w * h)
    for (y in 0 until h) for (x in 0 until w) on[y * w + x] = diff(s.at(region.left + x, region.top + y), bg) > threshold
    if (lineOver != null) {
        for (y in 0 until h) {
            var x = 0
            while (x < w) {
                if (!on[y * w + x]) { x++; continue }
                var e = x
                while (e < w && on[y * w + e]) e++
                if (e - x >= lineOver || x == 0 || e == w) for (k in x until e) on[y * w + k] = false
                x = e
            }
        }
    }
    val columns = (0 until w).map { x -> (0 until h).any { y -> on[y * w + x] } }
    val out = mutableListOf<Rect>()
    var x = 0
    while (x < w) {
        if (!columns[x]) { x++; continue }
        var end = x; var empty = 0; var k = x
        while (k < w && empty < gap) {
            if (columns[k]) { end = k; empty = 0 } else empty++
            k++
        }
        var top = h; var bottom = -1
        for (cx in x..end) for (y in 0 until h) if (on[y * w + cx]) { top = minOf(top, y); bottom = maxOf(bottom, y) }
        out.add(Rect(region.left + x, region.top + top, region.left + end + 1, region.top + bottom + 1))
        x = end + 1
    }
    return out
}

private fun Rect.grown(n: Int) = Rect(left - n, top - n, right + n, bottom + n)
private fun Rect.shrunk(dx: Int, dy: Int) = Rect(left + dx, top + dy, right - dx, bottom - dy)

/**
 * A USB keyboard registered with the shell's `uinput` tool for as long as
 * the session is open (V14's, with the arrow keys). Its keys reach the app
 * through the kernel, as a real keyboard's do, and turn Flutter's focus
 * highlights on, which keys from the virtual keyboard do not (FL-433).
 * Closing the session removes the device.
 */
private class V01Keyboard(automation: UiAutomation, dumpsys: () -> String) : AutoCloseable {
    private val fds: Array<ParcelFileDescriptor> = automation.executeShellCommandRw("uinput -")
    private val stdin = ParcelFileDescriptor.AutoCloseOutputStream(fds[1])

    init {
        send("""{"id":1,"command":"register","name":"$NAME","vid":4660,"pid":22137,"bus":"usb",""" +
            """"configuration":[{"type":"UI_SET_EVBIT","data":["EV_KEY","EV_SYN"]},""" +
            """{"type":"UI_SET_KEYBIT","data":["KEY_TAB","KEY_SPACE","KEY_ENTER","KEY_LEFTSHIFT","KEY_DOWN","KEY_UP"]}]}""")
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
        const val NAME = "V01 test keyboard"
    }
}

@RunWith(AndroidJUnit4::class)
class V01ColourContrastTest : TechniqueTest("V01") {
    private val density = inst.targetContext.resources.displayMetrics.density

    /** [n] logical pixels in screenshot pixels. */
    private fun dp(n: Number) = (n.toDouble() * density).roundToInt()

    /** An area of [n] physical pixels at the widget tests' pixel ratio of 3, in screenshot pixels. */
    private fun area3(n: Int) = (n / 9.0 * density * density).roundToInt()

    private var keyboard: V01Keyboard? = null

    @After
    fun removeKeyboard() {
        keyboard?.close()
        keyboard = null
    }

    // --- Opening, waiting, and the device's settings ---------------------

    /**
     * Opens [slug] and scrolls to its end. With [keys], the keyboard is
     * registered first, so that the screen is measured with it in place.
     */
    private fun open(slug: String, keys: Boolean = false) {
        if (keys && keyboard == null) keyboard = V01Keyboard(automation) { device.executeShellCommand("dumpsys input") }
        openExample(slug, By.desc(TITLES.getValue(slug)), settleMillis = 500)
        scrollToEnd()
    }

    /**
     * Waits up to [millis] for [ok]. A lookup that misses (node() and
     * revealed() throw an AssertionError) counts as not yet, and is tried
     * again; the last miss is reported if time runs out.
     */
    private fun waitFor(what: String, millis: Long = 5_000, ok: () -> Boolean) {
        val end = System.currentTimeMillis() + millis
        var miss: String? = null
        while (System.currentTimeMillis() < end) {
            try {
                if (ok()) return
                miss = null
            } catch (e: AssertionError) {
                miss = e.message
            }
            Thread.sleep(150)
        }
        throw AssertionError("timed out waiting for $what" + (miss?.let { ": $it" } ?: ""))
    }

    /** The node of [id], waiting for it as [waitFor] does. */
    private fun nodeNow(id: String): AccessibilityNodeInfo {
        var found: AccessibilityNodeInfo? = null
        waitFor("node $id") { found = node(id); true }
        return found!!
    }

    private fun bounds(id: String): Rect = Rect().also { nodeNow(id).getBoundsInScreen(it) }

    /** The one node named [name], waiting for it. */
    private fun namedNow(name: String): AccessibilityNodeInfo {
        var found: AccessibilityNodeInfo? = null
        waitFor("one node named \"$name\"") {
            val all = all().filter { it.name() == name }
            if (all.size == 1) found = all.single()
            all.size == 1
        }
        return found!!
    }

    private fun boundsNamed(name: String): Rect = Rect().also { namedNow(name).getBoundsInScreen(it) }

    private fun shell(command: String): String = device.executeShellCommand(command).trim()

    private fun nightMode(): String = shell("cmd uimode night").removePrefix("Night mode:").trim()

    private fun setNight(value: String) {
        shell("cmd uimode night $value")
        waitFor("night mode $value") { nightMode() == value }
    }

    /**
     * Runs [block] in light mode, then in dark mode, set by the device's own
     * night mode setting. Each change is asserted to have taken before
     * anything is read; the setting the device had is put back afterwards,
     * whatever happens, and asserted to be back.
     */
    private fun inModes(block: (dark: Boolean) -> Unit) {
        val original = nightMode()
        assertTrue("night mode is one the test can put back: $original", original in listOf("yes", "no", "auto"))
        var failure: Throwable? = null
        try {
            for (dark in listOf(false, true)) {
                setNight(if (dark) "yes" else "no")
                assertEquals("night mode took", if (dark) "yes" else "no", nightMode())
                block(dark)
            }
        } catch (t: Throwable) {
            failure = t
            throw t
        } finally {
            shell("cmd uimode night $original")
            val back = try { waitFor("night mode back to $original") { nightMode() == original }; null } catch (e: AssertionError) { e }
            Log.i(TAG, "android night mode put back to ${nightMode()} (was $original)")
            if (back != null && failure == null) throw back
        }
    }

    private fun mode(dark: Boolean) = if (dark) "dark" else "light"

    // --- Screenshots -------------------------------------------------------

    private fun bitmap(): Bitmap {
        val b = automation.takeScreenshot()!!
        return if (b.config == Bitmap.Config.HARDWARE) b.copy(Bitmap.Config.ARGB_8888, false) else b
    }

    /**
     * A screenshot once [region] has stopped changing: two screenshots 300 ms
     * apart that differ in no more than 1% of it (a field's caret blinks).
     */
    private fun settled(region: Rect, name: String? = null): V01Shot {
        var last = bitmap()
        repeat(20) {
            Thread.sleep(300)
            val next = bitmap()
            val a = V01Shot(last); val b = V01Shot(next)
            var changed = 0
            val r = Rect(region).apply { intersect(0, 0, b.width, b.height) }
            for (y in r.top until r.bottom) for (x in r.left until r.right) if (diff(a.at(x, y), b.at(x, y)) > 12) changed++
            last = next
            if (changed <= r.width() * r.height() / 100) {
                if (name != null) keep(next, name)
                return b
            }
        }
        throw AssertionError("the screen did not settle in $region")
    }

    private var keptFolder = false

    /**
     * Saves [b] as /data/local/tmp/v01/<name>.png on the device, for the
     * probe folder (the run that pulls them deletes the folder). The shell
     * command is split at spaces and run with no shell, so the bytes go to
     * `dd`'s input.
     */
    private fun keep(b: Bitmap, name: String) {
        try {
            val png = ByteArrayOutputStream().also { b.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
            if (!keptFolder) { shell("mkdir -p /data/local/tmp/v01"); keptFolder = true }
            val fds = automation.executeShellCommandRw("dd of=/data/local/tmp/v01/$name.png")
            ParcelFileDescriptor.AutoCloseOutputStream(fds[1]).use { it.write(png) }
            ParcelFileDescriptor.AutoCloseInputStream(fds[0]).use { it.readBytes() }
        } catch (e: Exception) {
            Log.w(TAG, "could not keep $name: $e")
        }
    }

    /** The whole screen, less its top and bottom 4%, the system's bars. */
    private fun screenRegion(): Rect {
        val h = device.displayHeight
        return Rect(0, h / 25, device.displayWidth, h - h / 25)
    }

    /**
     * The page's colour beside [near]: the commonest colour of the 8 dp at the
     * screen's left edge level with it, where the example's padding is. In
     * light mode it must be light and in dark mode dark: the witness that the
     * app follows the device's setting.
     */
    private fun page(s: V01Shot, near: Rect, dark: Boolean): Int {
        val p = commonest(s, Rect(0, near.top, dp(8), near.bottom))
        val l = luminance(p)
        assertTrue("the page is ${hex(p)} in ${mode(dark)} mode", if (dark) l < 0.05 else l > 0.8)
        return p
    }

    /** The top of the soft keyboard's window, or the screen's bottom if none is shown. */
    private fun imeTop(): Int {
        val ime = automation.windows.firstOrNull { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD }
            ?: return device.displayHeight
        return Rect().also { ime.getBoundsInScreen(it) }.top
    }

    /** Fails unless [r] is wholly on the screen and above any soft keyboard. */
    private fun onScreen(what: String, r: Rect) {
        val bottom = imeTop()
        assertTrue("$what is wholly on the screen and above the soft keyboard (top $bottom): $r",
            r.top >= 0 && r.left >= 0 && r.right <= device.displayWidth && r.bottom <= bottom)
    }

    /** A text's measure, logged. */
    private fun measured(s: V01Shot, what: String, box: Rect): V01Text {
        onScreen(what, box.grown(7))
        val m = textContrast(s, box)
        Log.i(TAG, "android $what: $m")
        return m
    }

    private fun assertText(s: V01Shot, what: String, box: Rect, at: Double = 4.5): V01Text {
        val m = measured(s, what, box)
        assertTrue("$what: $m", m.lowest >= at)
        return m
    }

    /** An edge's measure, logged; its first pixel must be the page's colour. */
    private fun measuredEdge(s: V01Shot, what: String, page: Int, x0: Int, y0: Int, dx: Int, dy: Int, steps: Int): V01Edge {
        onScreen(what, Rect(minOf(x0, x0 + dx * steps), minOf(y0, y0 + dy * steps), maxOf(x0, x0 + dx * steps) + 1, maxOf(y0, y0 + dy * steps) + 1))
        val e = edge(s, x0, y0, dx, dy, steps)
        Log.i(TAG, "android $what: $e")
        assertTrue("$what: the walk starts on the page (${hex(page)}), not ${hex(e.start)}: $e", diff(e.start, page) <= 2)
        return e
    }

    // --- Where each text is ----------------------------------------------

    /** A box found at rest, kept relative to its control's node so that it moves with it. */
    private inner class Box(val id: String?, val name: String?, rest: Rect, at: Rect) {
        private val dx = rest.left - at.left
        private val dy = rest.top - at.top
        private val w = rest.width()
        private val h = rest.height()
        private val size = Pair(at.width(), at.height())

        /** Where it is now. */
        fun now(): Rect {
            val at = if (id != null) bounds(id) else boundsNamed(name!!)
            assertEquals("${id ?: name} kept its size", size, Pair(at.width(), at.height()))
            return Rect(at.left + dx, at.top + dy, at.left + dx + w, at.top + dy + h)
        }
    }

    private fun boxOf(id: String, rest: Rect) = Box(id, null, rest, bounds(id))

    /** A text that is a node of its own: its box is the node's, the paragraph's rectangle. */
    private fun ownText(name: String) = Box(null, name, boundsNamed(name), boundsNamed(name))

    /**
     * The one piece drawn in [region] of [id]'s node at rest, 2 pixels larger
     * on every side: the text there. Fails unless there is exactly [count]
     * pieces, and returns piece [index].
     */
    private fun pieceOf(s: V01Shot, id: String, region: Rect, what: String, count: Int = 1, index: Int = 0, lineOver: Int? = null): Rect {
        val ps = pieces(s, region, commonest(s, region), dp(8), lineOver = lineOver)
        Log.i(TAG, "android $what pieces in $region: $ps")
        assertEquals("$what: pieces drawn in $region: $ps", count, ps.size)
        return ps[index]
    }

    /**
     * The label and the hint of a Material outlined field at rest. The
     * field's node begins at its top edge, and the floating label is drawn
     * centred on that edge, in a gap in it, half above the node (as the
     * test's screenshots show). The edge is the row with the most pixels off
     * the page from 4 dp above the node's top to 24 dp below it, between the
     * field's rounded corners; the label is what is drawn in the band 12 dp
     * either side of that row once the edge is left out (runs 12 dp long or
     * longer, and the stubs that reach the band's sides). The hint is what
     * is drawn inside the field below that band.
     */
    private fun materialField(s: V01Shot, id: String, page: Int, what: String, hint: Boolean): Pair<Rect, Rect?> {
        val f = bounds(id)
        val l = f.left + dp(6); val r = f.right - dp(6)
        var edgeY = -1; var most = -1
        for (y in f.top - dp(4) until minOf(f.bottom, f.top + dp(24))) {
            var n = 0
            for (x in l until r) if (diff(s.at(x, y), page) > 12) n++
            if (n > most) { most = n; edgeY = y }
        }
        assertTrue("$what: the field's top edge is a line across it: $most of ${r - l} pixels", most > (r - l) / 2)
        val band = Rect(l, edgeY - dp(12), r, edgeY + dp(12))
        // A piece 4 dp tall or more is a letter, not what is left of the edge.
        val all = pieces(s, band, page, dp(8), lineOver = dp(12))
        val label = all.filter { it.height() >= dp(4) }
        Log.i(TAG, "android $what field $f, top edge at $edgeY; pieces in $band: $all")
        assertEquals("$what: one label is drawn on the field's top edge: $all", 1, label.size)
        if (!hint) return label.first().grown(2) to null
        val inside = Rect(l, band.bottom + dp(1), r, f.bottom - dp(4))
        val hints = pieces(s, inside, commonest(s, inside), dp(8))
        Log.i(TAG, "android $what hint pieces in $inside: $hints")
        assertEquals("$what: the hint is the one thing drawn inside the field: $hints", 1, hints.size)
        return label.first().grown(2) to hints.single().grown(2)
    }

    // --- Input ---------------------------------------------------------------

    private fun key(name: String) {
        val k = keyboard ?: throw AssertionError("no keyboard registered")
        k.press("KEY_$name")
        Thread.sleep(500)
    }

    /** The control with keyboard focus: its identifier's last part, "back", or "none". */
    private fun stop(slug: String): String {
        val focused = all().filter { it.isFocused && (it.viewIdResourceName != null || it.name().isNotEmpty()) }
        if (focused.isEmpty()) return "none"
        assertEquals("nodes with focus: ${focused.map { it.viewIdResourceName ?: it.name() }}", 1, focused.size)
        val node = focused.single()
        if (node.name() == "Back") return "back"
        val id = node.viewIdResourceName.orEmpty()
        return if (id.startsWith("v01-$slug-")) id.removePrefix("v01-$slug-") else "other: $id ${node.name()}"
    }

    /** Presses Tab until [c] has focus, at most [max] times, waiting up to 3 s each time. */
    private fun tabTo(slug: String, c: String, max: Int = 6) {
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

    /** Presses [k] once and waits up to 3 s for [c] to have focus. */
    private fun keyTo(slug: String, k: String, c: String) {
        key(k)
        val end = System.currentTimeMillis() + 3_000
        while (System.currentTimeMillis() < end) {
            if (stop(slug) == c) return
            Thread.sleep(200)
        }
        throw AssertionError("$slug: $k did not move focus to $c; focus is on ${stop(slug)}")
    }

    private fun touch(action: Int, down: Long, x: Int, y: Int) {
        val e = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, x.toFloat(), y.toFloat(), 0)
        e.source = InputDevice.SOURCE_TOUCHSCREEN
        try {
            assertTrue("the touch event was injected", automation.injectInputEvent(e, true))
        } finally {
            e.recycle()
        }
    }

    /**
     * Holds a finger down at the centre of [id] for [HOLD_MILLIS], takes a
     * screenshot, and lifts it, all before Flutter's long-press time; returns
     * the screenshot.
     *
     * With [rest], a screenshot of the same screen before the press,
     * screenshots are taken until one differs from it in [id]'s bounds by
     * more than [drawn] pixels (the control shows the press), or until
     * [PRESS_BUDGET_MILLIS] after the finger went down. A try whose last
     * screenshot shows nothing of the press, or that was held past the
     * long-press time, missed what is measured: it is not a reading. The
     * finger is lifted (a tap, which these controls' handlers take as one)
     * and the press made again, at most [PRESS_TRIES] times in all, every try
     * logged; the try returned must be under the long-press time, and the
     * caller asserts that its screenshot shows the press. A screenshot is
     * taken just before each press and thrown away: the first screenshot
     * after a pause was seen to take up to 300 ms (a press held 479 ms), and
     * in dark mode the Cupertino button's press was once missed, its
     * screenshot returned about 380 ms after the finger went down.
     */
    /** How many presses (each a tap once lifted) the last [pressed] made. */
    private var presses = 0

    private fun pressed(id: String, name: String, rest: V01Shot? = null, drawn: Int = 0): Bitmap {
        val r = bounds(id)
        onScreen(id, r)
        var b: Bitmap? = null
        var held = 0L
        presses = 0
        for (attempt in 1..PRESS_TRIES) {
            if (attempt > 1) Thread.sleep(1_000)
            bitmap()
            val down = SystemClock.uptimeMillis()
            touch(MotionEvent.ACTION_DOWN, down, r.centerX(), r.centerY())
            presses++
            var shots = 0
            var shown = false
            try {
                Thread.sleep(HOLD_MILLIS)
                while (true) {
                    b = bitmap(); shots++
                    shown = rest == null || changed(rest, V01Shot(b!!), r) > drawn
                    if (shown || SystemClock.uptimeMillis() - down >= PRESS_BUDGET_MILLIS) break
                }
            } finally {
                touch(MotionEvent.ACTION_UP, down, r.centerX(), r.centerY())
            }
            held = SystemClock.uptimeMillis() - down
            Log.i(TAG, "android $name: try $attempt held $held ms, $shots screenshots, " +
                if (shown) "the press shown" else "nothing of the press shown")
            if (shown && held < LONG_PRESS_MILLIS) break
        }
        assertTrue("$id: the press was held $held ms, past the long-press time", held < LONG_PRESS_MILLIS)
        keep(b!!, name)
        return b!!
    }

    /** How many pixels of [r] differ by more than 2 between [a] and [b]. */
    private fun changed(a: V01Shot, b: V01Shot, r: Rect): Int {
        var n = 0
        for (y in r.top until r.bottom) for (x in r.left until r.right) if (diff(a.at(x, y), b.at(x, y)) > 2) n++
        return n
    }

    // --- Tests ------------------------------------------------------------

    @Test
    fun theMeasureGivesWcagsRatiosForKnownPairs() {
        assertEquals(21.0, ratio(0x000000, 0xFFFFFF), 0.01)
        assertEquals(4.54, ratio(0x767676, 0xFFFFFF), 0.01)
        assertEquals(3.03, ratio(0x949494, 0xFFFFFF), 0.01)
        assertEquals(1.0, ratio(0xFFFFFF, 0xFFFFFF), 0.0)
    }

    /** The example's named nodes after the "Example" heading, one line each, for the log. */
    private fun describe(): List<String> {
        val nodes = all()
        val start = nodes.indexOfFirst { it.name() == "Example" }
        return nodes.drop(start + 1).filter { it.name().isNotEmpty() || it.viewIdResourceName != null || !it.hintText.isNullOrEmpty() }
            .map {
                "${it.type().substringAfterLast('.')} id=${it.viewIdResourceName} desc=\"${it.name()}\" " +
                    "hint=\"${it.hintText}\" text=\"${it.text}\" checkable=${it.isCheckable} checked=${it.isChecked} " +
                    "selected=${it.isSelected} focusable=${it.isFocusable} clickable=${it.isClickable}"
            }
    }

    /** A field's name for a screen reader: its content description or, as Flutter gives a field's label, its hint text. */
    private fun fieldName(n: AccessibilityNodeInfo) = n.name().ifEmpty { n.hintText?.toString().orEmpty() }

    @Test
    fun everyExampleHasItsNodes() {
        for (slug in TITLES.keys) {
            open(slug)
            Log.i(TAG, "android tree $slug:\n" + describe().joinToString("\n"))
        }
        open("good-material")
        assertEquals(VIEW, namedNow(BODY).type())
        nodeNow("v01-good-material-email").let {
            assertEquals(EDIT_TEXT, it.type())
            assertTrue("the field's name starts with Email: ${fieldName(it)}", fieldName(it).startsWith("Email"))
        }
        nodeNow("v01-good-material-updates").let {
            assertEquals(CHECKBOX, it.type()); assertEquals("Send me updates", it.name()); assertTrue(!it.isChecked)
        }
        nodeNow("v01-good-material-send").let { assertEquals(BUTTON, it.type()); assertEquals("Send", it.name()) }

        for (slug in listOf("good-cupertino", "bad-cupertino-placeholder")) {
            open(slug)
            val field = nodeNow("v01-$slug-email")
            assertEquals(slug, EDIT_TEXT, field.type())
            assertTrue("$slug: the field's name starts with Email: ${fieldName(field)}", fieldName(field).startsWith("Email"))
            // The label above the field is not a node of its own.
            assertEquals(slug, 1, all().count { fieldName(it).startsWith("Email") })
        }
        open("good-cupertino")
        nodeNow("v01-good-cupertino-send").let { assertEquals(BUTTON, it.type()); assertEquals("Send", it.name()) }

        for (slug in listOf("good-caption", "bad-caption")) {
            open(slug)
            assertEquals(slug, 1, all().count { it.name() == CAPTION })
        }

        open("good-selection")
        for ((v, on) in VIEWS.zip(listOf(false, true, false))) {
            val n = nodeNow("v01-good-selection-${v.lowercase()}")
            assertEquals(v, RADIO, n.type()); assertEquals(v, n.name()); assertEquals(v, on, n.isChecked)
        }
        assertTrue("tap Day", device.click(bounds("v01-good-selection-day").centerX(), bounds("v01-good-selection-day").centerY()))
        waitFor("Day checked") { nodeNow("v01-good-selection-day").isChecked && !nodeNow("v01-good-selection-week").isChecked }

        open("bad-colour-only")
        for ((v, on) in VIEWS.zip(listOf(false, true, false))) {
            val n = nodeNow("v01-bad-colour-only-${v.lowercase()}")
            assertEquals(v, BUTTON, n.type()); assertEquals(v, n.name()); assertEquals(v, on, n.isSelected)
        }
        assertTrue("tap Day", device.click(bounds("v01-bad-colour-only-day").centerX(), bounds("v01-bad-colour-only-day").centerY()))
        waitFor("Day selected") { nodeNow("v01-bad-colour-only-day").isSelected && !nodeNow("v01-bad-colour-only-week").isSelected }

        open("bad-faint-edge")
        nodeNow("v01-bad-faint-edge-email").let {
            assertEquals(EDIT_TEXT, it.type())
            assertTrue("the field's name starts with Email: ${fieldName(it)}", fieldName(it).startsWith("Email"))
        }
    }

    /** good-material's texts at rest, as boxes that move with their controls. */
    private inner class MaterialForm(s: V01Shot, page: Int) {
        val body = ownText(BODY)
        val label: Box
        val hint: Box
        val updates: Box
        val square: Rect
        val send: Box

        init {
            val (l, h) = materialField(s, "v01-good-material-email", page, "good-material email", hint = true)
            label = boxOf("v01-good-material-email", l)
            hint = boxOf("v01-good-material-email", h!!)
            val tile = bounds("v01-good-material-updates")
            val ps = pieces(s, tile.shrunk(dp(1), dp(1)), commonest(s, tile), dp(8))
            Log.i(TAG, "android good-material updates pieces: $ps")
            assertEquals("the tile draws its title and its checkbox: $ps", 2, ps.size)
            updates = boxOf("v01-good-material-updates", ps[0].grown(2))
            square = ps[1]
            assertTrue("the checkbox is about 18 dp square: $square",
                square.width() in dp(14)..dp(24) && square.height() in dp(14)..dp(24))
            val b = bounds("v01-good-material-send")
            send = boxOf("v01-good-material-send",
                pieceOf(s, "v01-good-material-send", b.shrunk(dp(20), dp(8)), "good-material send").grown(2))
        }
    }

    @Test
    fun goodMaterialEveryTextAndEdgeAtRestAndWithKeyboardFocus() = inModes { dark ->
        val m = mode(dark)
        open("good-material", keys = true)
        val field = bounds("v01-good-material-email")
        val s = settled(screenRegion(), "good-material-$m-rest")
        val page = page(s, field, dark)
        Log.i(TAG, "android good-material $m: page ${hex(page)}, density $density")
        val form = MaterialForm(s, page)
        assertText(s, "good-material $m rest body", form.body.now())
        assertText(s, "good-material $m rest label", form.label.now())
        assertText(s, "good-material $m rest hint", form.hint.now())
        assertText(s, "good-material $m rest updates", form.updates.now())
        assertText(s, "good-material $m rest send", form.send.now())
        val fieldEdge = measuredEdge(s, "good-material $m field edge", page, field.left - dp(4), field.centerY(), 1, 0, dp(10))
        assertTrue("field $fieldEdge", fieldEdge.outside >= 3)
        val sq = form.square
        val boxEdge = measuredEdge(s, "good-material $m checkbox edge", page, sq.right + dp(2), sq.centerY(), -1, 0, dp(8))
        assertTrue("box $boxEdge", boxEdge.outside >= 3)
        val send = bounds("v01-good-material-send")
        val outline = measuredEdge(s, "good-material $m button outline", page, send.left - dp(2), send.centerY(), 1, 0, dp(10))
        assertTrue("outline $outline", outline.outside >= 3)

        // With keyboard focus on each control in turn, from the keyboard.
        tabTo("good-material", "back")
        for ((c, boxes) in listOf(
            "email" to listOf("label" to form.label, "hint" to form.hint),
            "updates" to listOf("updates" to form.updates),
            "send" to listOf("send" to form.send),
        )) {
            tabTo("good-material", c, 1)
            val f = settled(bounds("v01-good-material-$c").grown(dp(8)), "good-material-$m-focused-$c")
            for ((what, box) in boxes) assertText(f, "good-material $m focused $c $what", box.now())
        }
    }

    @Test
    fun goodMaterialEachTextWhilePressedAndTheCheckboxChecked() = inModes { dark ->
        val m = mode(dark)
        open("good-material")
        val field = bounds("v01-good-material-email")
        val s = settled(screenRegion(), "good-material-$m-rest-2")
        val page = page(s, field, dark)
        val form = MaterialForm(s, page)

        // Send: the witness that the press took is what it drew.
        val send = bounds("v01-good-material-send")
        val sendHeld = V01Shot(pressed("v01-good-material-send", "good-material-$m-pressed-send", s, dp(10) * dp(10)))
        val drawn = changed(s, sendHeld, send)
        Log.i(TAG, "android good-material $m pressed send: $drawn pixels changed")
        assertTrue("the press on Send drew something: $drawn pixels", drawn > dp(10) * dp(10))
        assertText(sendHeld, "good-material $m pressed send", form.send.now())

        // The checkbox tile: the witness is the box checked once the finger is lifted.
        val updatesHeld = V01Shot(pressed("v01-good-material-updates", "good-material-$m-pressed-updates"))
        assertText(updatesHeld, "good-material $m pressed updates", form.updates.now())
        // Each press is a tap once lifted: an odd number of them checks the
        // box. Should a try have been made again (pressed), an even number
        // leaves it unchecked, and a click checks it for what follows.
        val odd = presses % 2 == 1
        waitFor("the checkbox ${if (odd) "checked" else "unchecked"} after $presses presses") {
            nodeNow("v01-good-material-updates").isChecked == odd
        }
        if (!odd) {
            assertTrue("click the checkbox", nodeNow("v01-good-material-updates").performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitFor("the checkbox checked") { nodeNow("v01-good-material-updates").isChecked }
        }

        // Checked, once the ripple has gone: the fill 3:1 against the page
        // and the mark 3:1 against the fill.
        val tile = bounds("v01-good-material-updates")
        Thread.sleep(1_000)
        val c = settled(tile.grown(dp(4)), "good-material-$m-checked")
        val sq = form.square
        val fill = measuredEdge(c, "good-material $m checked fill", page, sq.right + dp(2), sq.centerY(), -1, 0, dp(8))
        assertTrue("fill $fill", fill.outside >= 3)
        val inner = Rect(sq.centerX() - dp(5), sq.centerY() - dp(5), sq.centerX() + dp(5), sq.centerY() + dp(5))
        val mark = marks(c, inner, fill.edge)
        Log.i(TAG, "android good-material $m checked mark: $mark pixels 3:1 or more against ${hex(fill.edge)}")
        assertTrue("a mark 3:1 on the fill: $mark", mark > area3(30))
        assertText(c, "good-material $m checked updates", form.updates.now())

        // The field, last: lifting the finger is a tap, which focuses it.
        val fieldHeld = V01Shot(pressed("v01-good-material-email", "good-material-$m-pressed-email"))
        assertText(fieldHeld, "good-material $m pressed label", form.label.now())
        waitFor("the field focused by the tap") { nodeNow("v01-good-material-email").isFocused }
    }

    /** The label above a Cupertino field and the placeholder inside it, at rest. */
    private fun cupertinoField(s: V01Shot, id: String, what: String): Pair<Box, Box> {
        val f = bounds(id)
        val above = Rect(f.left, f.top - dp(30), f.right, f.top - dp(1))
        val label = pieces(s, above, commonest(s, above), dp(8))
        Log.i(TAG, "android $what label pieces in $above: $label")
        assertTrue("$what: a label above the field: $label", label.isNotEmpty())
        val placeholder = pieceOf(s, id, f.shrunk(dp(3), dp(3)), "$what placeholder")
        return boxOf(id, label.first().grown(2)) to boxOf(id, placeholder.grown(2))
    }

    @Test
    fun goodCupertinoEveryTextAndTheFieldsEdgeAtRestAndWithKeyboardFocus() = inModes { dark ->
        val m = mode(dark)
        open("good-cupertino", keys = true)
        val id = "v01-good-cupertino-email"
        val field = bounds(id)
        val s = settled(screenRegion(), "good-cupertino-$m-rest")
        val page = page(s, field, dark)
        val (label, placeholder) = cupertinoField(s, id, "good-cupertino $m")
        val b = bounds("v01-good-cupertino-send")
        val send = boxOf("v01-good-cupertino-send",
            pieceOf(s, "v01-good-cupertino-send", b.shrunk(dp(8), dp(4)), "good-cupertino send").grown(2))
        assertText(s, "good-cupertino $m rest label", label.now())
        assertText(s, "good-cupertino $m rest placeholder", placeholder.now())
        assertText(s, "good-cupertino $m rest send", send.now())
        val e = measuredEdge(s, "good-cupertino $m field edge", page, field.left - dp(2), field.centerY(), 1, 0, dp(6))
        assertTrue("$e", e.outside >= 3)
        assertTrue("$e", e.inside >= 3)

        tabTo("good-cupertino", "back")
        tabTo("good-cupertino", "email", 1)
        val f = settled(field.grown(dp(8)), "good-cupertino-$m-focused-email")
        assertText(f, "good-cupertino $m focused label", label.now())
        assertText(f, "good-cupertino $m focused placeholder", placeholder.now())
        tabTo("good-cupertino", "send", 1)
        val g = settled(bounds("v01-good-cupertino-send").grown(dp(8)), "good-cupertino-$m-focused-send")
        assertText(g, "good-cupertino $m focused send", send.now())
    }

    @Test
    fun goodCupertinoTheButtonsTextWhilePressed() = inModes { dark ->
        val m = mode(dark)
        open("good-cupertino")
        val s = settled(screenRegion(), "good-cupertino-$m-rest-2")
        page(s, bounds("v01-good-cupertino-email"), dark)
        val b = bounds("v01-good-cupertino-send")
        val send = boxOf("v01-good-cupertino-send",
            pieceOf(s, "v01-good-cupertino-send", b.shrunk(dp(8), dp(4)), "good-cupertino send").grown(2))
        val held = V01Shot(pressed("v01-good-cupertino-send", "good-cupertino-$m-pressed-send", s, dp(10) * dp(10)))
        // The witness: pressedOpacity fades the button while it is held.
        val drawn = changed(s, held, b)
        Log.i(TAG, "android good-cupertino $m pressed send: $drawn pixels changed")
        assertTrue("the press on Send changed the button: $drawn pixels", drawn > dp(10) * dp(10))
        assertText(held, "good-cupertino $m pressed send", send.now())
    }

    @Test
    fun goodCaptionIs45To1OverTheWholePicture() = inModes { dark ->
        val m = mode(dark)
        open("good-caption")
        val box = boundsNamed(CAPTION)
        val s = settled(screenRegion(), "good-caption-$m")
        page(s, box, dark)
        assertText(s, "good-caption $m caption", box)
    }

    /** The radio rings and titles of good-selection at rest. */
    private fun radios(s: V01Shot): Map<String, Pair<Rect, Box>> = VIEWS.associate { v ->
        val id = "v01-good-selection-${v.lowercase()}"
        val tile = bounds(id)
        val ps = pieces(s, tile.shrunk(dp(1), dp(1)), commonest(s, tile), dp(8))
        Log.i(TAG, "android good-selection $v pieces: $ps")
        assertEquals("$v: the tile draws its radio button and its title: $ps", 2, ps.size)
        val ring = ps[0]
        assertTrue("$v: the ring is about 20 dp across: $ring", ring.width() in dp(16)..dp(24) && ring.height() in dp(16)..dp(24))
        v to (ring to boxOf(id, ps[1].grown(2)))
    }

    /** Each ring's edge and each title at [s], and the pixels 3:1 against the page in each ring's middle. */
    private fun dots(s: V01Shot, page: Int, rings: Map<String, Pair<Rect, Box>>, what: String): Map<String, Int> =
        rings.mapValues { (v, p) ->
            val (ring, title) = p
            val e = measuredEdge(s, "$what $v ring", page, ring.left - dp(2), ring.centerY(), 1, 0, ring.width() / 2 + dp(2))
            assertTrue("$v ring $e", e.outside >= 3)
            assertText(s, "$what $v title", title.now())
            marks(s, Rect(ring.centerX() - dp(4), ring.centerY() - dp(4), ring.centerX() + dp(4), ring.centerY() + dp(4)), page)
        }

    @Test
    fun goodSelectionTitlesRingsAndTheDotAtRestAfterATapAndWithKeyboardFocus() = inModes { dark ->
        val m = mode(dark)
        open("good-selection", keys = true)
        val s = settled(screenRegion(), "good-selection-$m-rest")
        val page = page(s, bounds("v01-good-selection-day"), dark)
        val rings = radios(s)
        val before = dots(s, page, rings, "good-selection $m rest")
        Log.i(TAG, "android good-selection $m dots before: $before")
        assertTrue("$before", before.getValue("Week") > area3(100))
        assertEquals("$before", 0, before.getValue("Day"))
        assertEquals("$before", 0, before.getValue("Month"))

        val day = bounds("v01-good-selection-day")
        assertTrue("tap Day", device.click(day.centerX(), day.centerY()))
        waitFor("Day checked") { nodeNow("v01-good-selection-day").isChecked && !nodeNow("v01-good-selection-week").isChecked }
        Thread.sleep(1_000)
        val t = settled(screenRegion(), "good-selection-$m-after-tap")
        val after = dots(t, page, rings, "good-selection $m after the tap")
        Log.i(TAG, "android good-selection $m dots after the tap on Day: $after")
        assertTrue("$after", after.getValue("Day") > area3(100))
        assertEquals("$after", 0, after.getValue("Week"))
        assertEquals("$after", 0, after.getValue("Month"))

        // Keyboard focus: Tab goes into the group at the chosen radio button
        // (Day, now), and each arrow moves the choice and the focus on.
        tabTo("good-selection", "day")
        for ((v, next) in listOf("Day" to null, "Week" to "DOWN", "Month" to "DOWN")) {
            val c = v.lowercase()
            if (next != null) keyTo("good-selection", next, c)
            waitFor("$v checked") { nodeNow("v01-good-selection-$c").isChecked }
            val f = settled(bounds("v01-good-selection-$c").grown(dp(8)), "good-selection-$m-focused-$c")
            assertText(f, "good-selection $m focused $v title", rings.getValue(v).second.now())
        }
    }

    @Test
    fun goodSelectionEachTitleWhilePressed() = inModes { dark ->
        val m = mode(dark)
        open("good-selection")
        val s = settled(screenRegion(), "good-selection-$m-rest-2")
        page(s, bounds("v01-good-selection-day"), dark)
        val rings = radios(s)
        // Day and Month first, then Week: each press chooses its radio
        // button once the finger is lifted, the witness that it took.
        for (v in listOf("Day", "Month", "Week")) {
            val c = v.lowercase()
            val held = V01Shot(pressed("v01-good-selection-$c", "good-selection-$m-pressed-$c"))
            assertText(held, "good-selection $m pressed $v title", rings.getValue(v).second.now())
            waitFor("$v checked after its press") { nodeNow("v01-good-selection-$c").isChecked }
            Thread.sleep(800)
        }
    }

    @Test
    fun badCupertinoPlaceholderIsUnder45To1() = inModes { dark ->
        val m = mode(dark)
        val id = "v01-bad-cupertino-placeholder-email"
        open("bad-cupertino-placeholder")
        val field = bounds(id)
        val s = settled(screenRegion(), "bad-cupertino-placeholder-$m")
        val page = page(s, field, dark)
        val (label, placeholder) = cupertinoField(s, id, "bad-cupertino-placeholder $m")
        val p = measured(s, "bad-cupertino-placeholder $m placeholder", placeholder.now())
        // Written to fail if Flutter's default placeholder reaches 4.5:1.
        assertTrue("$p", p.lowest < 4.5)
        assertTrue("the placeholder is drawn: $p", p.lowest > 1.2)
        assertText(s, "bad-cupertino-placeholder $m label", label.now())
        val e = measuredEdge(s, "bad-cupertino-placeholder $m field edge", page, field.left - dp(2), field.centerY(), 1, 0, dp(6))
        assertTrue("$e", e.outside >= 3)
    }

    @Test
    fun badCaptionIsUnder45To1OverThePalePartOfThePicture() = inModes { dark ->
        val m = mode(dark)
        open("bad-caption")
        val box = boundsNamed(CAPTION)
        val s = settled(screenRegion(), "bad-caption-$m")
        val page = page(s, box, dark)
        val whole = measured(s, "bad-caption $m caption", box)
        // Written to fail if the caption reaches 4.5:1 where it is drawn.
        assertTrue("$whole", whole.lowest < 4.5)
        assertTrue("the caption is drawn: $whole", whole.lowest > 1)
        // The caption's colour would be 4.5:1 or more over the dark end of
        // the picture, at the right of the same bar: what fails is where it
        // is drawn. The bar's right end is where the page starts again along
        // the caption's middle row.
        val y = box.centerY()
        var x = box.right
        while (x < s.width - 1 && diff(s.at(x, y), page) > 2) x++
        assertTrue("the picture runs on past the caption: ends at $x, the caption at ${box.right}", x > box.right + dp(4))
        val dark2 = s.at(x - dp(2), y)
        assertTrue("the bar's end is not the page: ${hex(dark2)}", diff(dark2, page) > 2)
        val q = ratio(whole.colour, dark2)
        Log.i(TAG, "android bad-caption $m: the caption's colour ${hex(whole.colour)} against the picture's dark end ${hex(dark2)}: ${f2(q)}:1")
        assertTrue("${f2(q)}", q >= 4.5)
    }

    @Test
    fun badColourOnlyTheChosenTitleDiffersByColourAloneUnder3To1() = inModes { dark ->
        val m = mode(dark)
        open("bad-colour-only")
        val s0 = settled(screenRegion(), "bad-colour-only-$m-before")
        val pagec = page(s0, bounds("v01-bad-colour-only-day"), dark)
        val boxes = VIEWS.associateWith { v ->
            val id = "v01-bad-colour-only-${v.lowercase()}"
            val tile = bounds(id)
            boxOf(id, pieceOf(s0, id, tile.shrunk(dp(1), dp(1)), "bad-colour-only $v").grown(2))
        }

        fun titles(s: V01Shot, what: String): Map<String, V01Text> = VIEWS.associateWith { v ->
            val box = boxes.getValue(v).now()
            val t = assertText(s, "bad-colour-only $m $what $v", box)
            // Nothing but the title is drawn on the tile: every pixel of the
            // tile outside the title's box is the page's colour.
            val tile = bounds("v01-bad-colour-only-${v.lowercase()}")
            val page = s.at(tile.left + 1, tile.top + 1)
            assertTrue("$v: the tile's corner is the page (${hex(pagec)}), not ${hex(page)}", diff(page, pagec) <= 2)
            var other = 0
            for (y in tile.top until tile.bottom) for (x in tile.left until tile.right) {
                if (!box.contains(x, y) && diff(s.at(x, y), page) > 2) other++
            }
            assertEquals("$v: $other pixels besides the title", 0, other)
            t
        }

        val before = titles(s0, "before")
        val chosen = before.getValue("Week").colour
        for (v in listOf("Day", "Month")) {
            val q = ratio(chosen, before.getValue(v).colour)
            Log.i(TAG, "android bad-colour-only $m: Week ${hex(chosen)} against $v ${hex(before.getValue(v).colour)} ${f2(q)}:1")
            assertTrue("$v is not Week's colour", diff(before.getValue(v).colour, chosen) > 2)
            // Written to fail if the chosen title comes to stand out at 3:1.
            assertTrue("Week against $v: ${f2(q)}", q < 3)
        }
        val day = bounds("v01-bad-colour-only-day")
        assertTrue("tap Day", device.click(day.centerX(), day.centerY()))
        waitFor("Day selected") { nodeNow("v01-bad-colour-only-day").isSelected && !nodeNow("v01-bad-colour-only-week").isSelected }
        Thread.sleep(1_000)
        val after = titles(settled(screenRegion(), "bad-colour-only-$m-after-tap"), "after the tap")
        Log.i(TAG, "android bad-colour-only $m after the tap on Day: Day ${hex(after.getValue("Day").colour)}, Week ${hex(after.getValue("Week").colour)}")
        assertTrue("the colour moved to Day", diff(after.getValue("Day").colour, chosen) <= 2)
        assertTrue("Week took Day's colour", diff(after.getValue("Week").colour, before.getValue("Day").colour) <= 2)
    }

    @Test
    fun badFaintEdgeIsUnder3To1AtRestAndThe3To1EdgeWithFocus() = inModes { dark ->
        val m = mode(dark)
        val id = "v01-bad-faint-edge-email"
        open("bad-faint-edge", keys = true)
        val field = bounds(id)
        val s = settled(screenRegion(), "bad-faint-edge-$m-rest")
        val page = page(s, field, dark)
        val rest = measuredEdge(s, "bad-faint-edge $m rest edge", page, field.left - dp(4), field.centerY(), 1, 0, dp(10))
        // Written to fail if the edge reaches 3:1.
        assertTrue("$rest", rest.outside < 3)
        assertTrue("the edge is drawn: $rest", rest.outside > 1.2)
        val (label, _) = materialField(s, id, page, "bad-faint-edge $m", hint = false)
        assertText(s, "bad-faint-edge $m label", label)
        // The positive control, through the same measure: with keyboard
        // focus the edge is the scheme's primary.
        tabTo("bad-faint-edge", "back")
        tabTo("bad-faint-edge", "email", 1)
        val now = bounds(id)
        val f = settled(now.grown(dp(8)), "bad-faint-edge-$m-focused")
        val focused = measuredEdge(f, "bad-faint-edge $m focused edge", page, now.left - dp(4), now.centerY(), 1, 0, dp(10))
        assertTrue("$focused", focused.outside >= 3)
    }

    /**
     * L4. TalkBack focus moved to each text and control of each example, in
     * order; tool/talkback.py reads what TalkBack says. Skips unless TalkBack
     * is running. A colour is not spoken: the walk records what each part is
     * to TalkBack, the good examples and the bad alike.
     */
    @Test
    fun talkBackWalk() {
        val byName = { marker: String, name: String -> Stop(marker) { all().single { it.name() == name } } }
        val byId = { id: String -> Stop(id) { node(id) } }
        val choice = { slug: String ->
            slug to listOf(byName("v01-$slug-label", CALENDAR)) + VIEWS.map { byId("v01-$slug-${it.lowercase()}") }
        }
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-material" to listOf(
                byName("v01-good-material-body", BODY),
                byId("v01-good-material-email"),
                byId("v01-good-material-updates"),
                byId("v01-good-material-send"),
            ),
            "good-cupertino" to listOf(byId("v01-good-cupertino-email"), byId("v01-good-cupertino-send")),
            "good-caption" to listOf(byName("v01-good-caption-caption", CAPTION)),
            choice("good-selection"),
            "bad-cupertino-placeholder" to listOf(byId("v01-bad-cupertino-placeholder-email")),
            "bad-caption" to listOf(byName("v01-bad-caption-caption", CAPTION)),
            choice("bad-colour-only"),
            "bad-faint-edge" to listOf(byId("v01-bad-faint-edge-email")),
        )
        talkBackWalk(walk, open = { slug -> open(slug) }, dwellMillis = { 5_000 })
    }
}
