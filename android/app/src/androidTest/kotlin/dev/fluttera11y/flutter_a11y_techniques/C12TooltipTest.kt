// L3 (tree) and L4 (TalkBack walk) for C12 Tooltip on Android.
// Spec: docs/specs/C12-tooltip.md.
//
// Whether a tooltip is drawn is read from screenshots: the pixels of a band
// under the control in the colour of Material's light tooltip box, its
// grey 700 at 90% over the page, that were not that colour in a screenshot
// taken just after the example opened (`drawn`). The C12 probe read any
// changed pixel, and a touch's ink left up to 7600 changed pixels in the
// band after the tooltip had gone (docs/evidence/probes/c12/android-tree.txt),
// so this counts the box's colour only. A touch held 800 ms is a long press
// and a mouse is a hover, each injected through UiAutomation; in the probe
// an injected hover showed a tooltip and held it (t02 to t13).
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Bitmap
import android.graphics.Rect
import android.os.SystemClock
import android.view.InputDevice
import android.view.MotionEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"

@RunWith(AndroidJUnit4::class)
class C12TooltipTest : TechniqueTest("C12") {
    private fun open(slug: String) = openExample(slug, By.desc(c12Titles.getValue(slug)), settleMillis = 500)

    private val good = listOf("good-material", "good-cupertino", "good-description")

    private val control = mapOf(
        "good-material" to "c12-good-material-delete",
        "good-cupertino" to "c12-good-cupertino-delete",
        "good-description" to "c12-good-description-download",
        "bad-not-hoverable" to "c12-bad-not-hoverable-delete",
        "bad-hover-only" to "c12-bad-hover-only-info",
        "bad-repeats-name" to "c12-bad-repeats-name-download",
    )

    private fun rect(n: AccessibilityNodeInfo) = Rect().also { n.getBoundsInScreen(it) }

    private fun dp(v: Int) = (v * inst.targetContext.resources.displayMetrics.density).toInt()

    /** The pixels of the band under [c]: 40 dp high, 300 dp wide. */
    private fun band(c: Rect): IntArray {
        val shot: Bitmap = automation.takeScreenshot()
        val top = c.bottom
        val bottom = minOf(shot.height - 1, c.bottom + dp(40))
        val left = maxOf(0, c.left - dp(10))
        val right = minOf(shot.width - 1, c.left + dp(300))
        val out = IntArray((bottom - top) * (right - left))
        shot.getPixels(out, 0, right - left, left, top, right - left, bottom - top)
        return out
    }

    /** Whether pixel [p] is the light tooltip box's colour, about (112, 112, 113). */
    private fun boxColour(p: Int) =
        Math.abs(((p shr 16) and 255) - 112) <= 12 &&
            Math.abs(((p shr 8) and 255) - 112) <= 12 &&
            Math.abs((p and 255) - 113) <= 12

    /** How many pixels of the band under [c] are the box's colour and were not in [base]. */
    private fun differing(c: Rect, base: IntArray): Int {
        val now = band(c)
        var n = 0
        for (i in now.indices) if (boxColour(now[i]) && !boxColour(base[i])) n++
        return n
    }

    /** A box drawn there: more than 1000 dp² of the band in its colour. */
    private fun drawn(c: Rect, base: IntArray) = differing(c, base) > dp(1) * dp(1) * 1000

    /** Waits up to [ms] for [drawn] to be [expected]; returns what it read last. */
    private fun waitDrawn(c: Rect, base: IntArray, expected: Boolean, ms: Long = 3_000): Boolean {
        val end = System.currentTimeMillis() + ms
        var now = drawn(c, base)
        while (now != expected && System.currentTimeMillis() < end) {
            Thread.sleep(150)
            now = drawn(c, base)
        }
        return now
    }

    /** A finger held on the centre of [c] for [holdMs], then lifted. */
    private fun press(c: Rect, holdMs: Long) {
        val t = SystemClock.uptimeMillis()
        val x = c.exactCenterX()
        val y = c.exactCenterY()
        val down = MotionEvent.obtain(t, t, MotionEvent.ACTION_DOWN, x, y, 0)
        down.source = InputDevice.SOURCE_TOUCHSCREEN
        assertTrue(automation.injectInputEvent(down, true))
        Thread.sleep(holdMs)
        val up = MotionEvent.obtain(t, SystemClock.uptimeMillis(), MotionEvent.ACTION_UP, x, y, 0)
        up.source = InputDevice.SOURCE_TOUCHSCREEN
        assertTrue(automation.injectInputEvent(up, true))
    }

    private fun mouse(action: Int, x: Float, y: Float) {
        val t = SystemClock.uptimeMillis()
        val props = arrayOf(MotionEvent.PointerProperties().apply { id = 0; toolType = MotionEvent.TOOL_TYPE_MOUSE })
        val coords = arrayOf(MotionEvent.PointerCoords().apply { this.x = x; this.y = y })
        val e = MotionEvent.obtain(t, t, action, 1, props, coords, 0, 0, 1f, 1f, 0, 0, InputDevice.SOURCE_MOUSE, 0)
        assertTrue(automation.injectInputEvent(e, true))
    }

    /**
     * The mouse enters at the left edge of the screen level with [c], and
     * moves to its centre in ten steps. First the mouse enters, moves, and
     * leaves once at that point: in the probe the first injected hover of a
     * run showed no tooltip and the later ones did (t01 against t02 to t13,
     * docs/evidence/probes/c12/android-tree.txt), and the first C12 run
     * failed the same way on its first hover. Why was not found.
     */
    private fun hover(c: Rect) {
        val y = c.exactCenterY()
        mouse(MotionEvent.ACTION_HOVER_ENTER, 1f, y)
        mouse(MotionEvent.ACTION_HOVER_MOVE, 2f, y)
        Thread.sleep(200)
        mouse(MotionEvent.ACTION_HOVER_EXIT, 2f, y)
        Thread.sleep(500)
        mouse(MotionEvent.ACTION_HOVER_ENTER, 1f, y)
        for (i in 1..10) {
            mouse(MotionEvent.ACTION_HOVER_MOVE, 1f + (c.exactCenterX() - 1f) * i / 10, y)
            Thread.sleep(16)
        }
    }

    /** The mouse moves in ten steps from the centre of [c] to 16 dp under its bottom edge, on the tooltip. */
    private fun glideOntoTheTooltip(c: Rect) {
        val toY = c.bottom + dp(16).toFloat()
        for (i in 1..10) {
            mouse(MotionEvent.ACTION_HOVER_MOVE, c.exactCenterX(), c.exactCenterY() + (toY - c.exactCenterY()) * i / 10)
            Thread.sleep(16)
        }
    }

    /**
     * The mouse moves off the example to the left edge of the screen, then
     * leaves. In the first C12 run a hover exit alone, sent at the top left
     * corner, left the tooltip drawn.
     */
    private fun mouseAway(c: Rect) {
        for (i in 1..10) {
            mouse(MotionEvent.ACTION_HOVER_MOVE, c.exactCenterX() - (c.exactCenterX() - 1f) * i / 10, c.exactCenterY())
            Thread.sleep(16)
        }
        Thread.sleep(300)
        mouse(MotionEvent.ACTION_HOVER_EXIT, 1f, c.exactCenterY())
    }

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

    /** The name of the deepest node with input focus. */
    private fun focusedName(): String {
        val f = all().lastOrNull { it.isFocused } ?: return "(none)"
        return f.viewIdResourceName ?: f.name()
    }

    private fun tooltip(n: AccessibilityNodeInfo) = n.tooltipText?.toString().orEmpty()

    @Test
    fun goodControlsAreNamedButtonsWithTheirTooltip() {
        val expected = mapOf(
            // The icon's label is the name; Tooltip's own copy is left out.
            "good-material" to Triple("Delete draft", "", BUTTON),
            // The tooltip is the name, and the tooltip text as well.
            "good-cupertino" to Triple("Delete draft", "Delete draft", BUTTON),
            // The button's text is the name; the tooltip is its tooltip text.
            "good-description" to Triple("Download", "Saves a PDF copy", BUTTON),
        )
        for (slug in good) {
            open(slug)
            val n = node(control.getValue(slug))
            val (name, tip, type) = expected.getValue(slug)
            assertEquals("$slug class", type, n.type())
            assertEquals("$slug name", name, n.name())
            assertEquals("$slug tooltip text", tip, tooltip(n))
            assertTrue("$slug clickable", n.isClickable)
            assertTrue("$slug focusable", n.isFocusable)
            assertEquals("$slug: clickable nodes but Back", 1, all().count { it.isClickable && it.name() != "Back" })
        }
    }

    @Test
    fun aLongPressShowsTheTooltipAndItGoesAfterTheTouchEnds() {
        for (slug in good + "bad-not-hoverable") {
            open(slug)
            val c = rect(node(control.getValue(slug)))
            val base = band(c)
            assertFalse("$slug: not drawn before", drawn(c, base))
            press(c, 800)
            assertTrue("$slug: drawn after a long press", waitDrawn(c, base, true, 1_500))
            // Tooltip's default: it goes 1.5 s after the touch ends.
            assertFalse("$slug: gone within 4 s of the touch's end", waitDrawn(c, base, false, 4_000))
            assertEquals("$slug: a long press does not activate", 0, count(slug))
        }
    }

    // FL-248. Written to fail when a tooltip shows on keyboard focus.
    @Test
    fun keyboardFocusDoesNotShowTheTooltip() {
        for (slug in good) {
            open(slug)
            val id = control.getValue(slug)
            val c = rect(node(id))
            val base = band(c)
            tabTo(id)
            Thread.sleep(2_000)
            assertTrue("$slug: focus is on the control", revealed(id).isFocused)
            assertFalse("$slug: focus did not draw the tooltip (${differing(c, base)} px differ)", drawn(c, base))
            // The positive control in the same launch: a long press draws it.
            press(c, 800)
            assertTrue("$slug: a long press draws it", waitDrawn(c, base, true, 1_500))
            waitDrawn(c, base, false, 4_000)
        }
    }

    @Test
    fun goodControlsActivateByTheClickActionATapAndEnter() {
        for (slug in good) {
            open(slug)
            val id = control.getValue(slug)
            assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount(slug, 1)
            val c = rect(node(id))
            assertTrue(device.click(c.centerX(), c.centerY()))
            waitForCount(slug, 2)
            tabTo(id)
            key("ENTER")
            waitForCount(slug, 3)
        }
    }

    @Test
    fun aHoverShowsTheTooltipAndThePointerCanMoveOntoIt() {
        for (slug in good) {
            open(slug)
            val c = rect(node(control.getValue(slug)))
            val base = band(c)
            try {
                hover(c)
                assertTrue("$slug: a hover draws it", waitDrawn(c, base, true, 1_500))
                Thread.sleep(5_000)
                assertTrue("$slug: still drawn after 5 s of hover", drawn(c, base))
                glideOntoTheTooltip(c)
                Thread.sleep(600)
                assertTrue("$slug: still drawn with the pointer on it (${differing(c, base)})", drawn(c, base))
            } finally {
                mouseAway(c)
            }
            assertFalse("$slug: gone when the pointer leaves", waitDrawn(c, base, false, 2_000))
        }
    }

    @Test
    fun badNotHoverableGoesWhenThePointerMovesOntoIt() {
        val slug = "bad-not-hoverable"
        open(slug)
        val c = rect(node(control.getValue(slug)))
        val base = band(c)
        try {
            hover(c)
            // The positive control: the same hover draws it.
            assertTrue("a hover draws it", waitDrawn(c, base, true, 1_500))
            glideOntoTheTooltip(c)
            assertFalse("gone with the pointer on it", waitDrawn(c, base, false, 1_500))
            Thread.sleep(600)
            assertFalse("still gone (${differing(c, base)})", drawn(c, base))
        } finally {
            mouseAway(c)
        }
    }

    @Test
    fun badNotHoverableIsAnIconButtonNamedByItsTooltip() {
        open("bad-not-hoverable")
        val n = node(control.getValue("bad-not-hoverable"))
        assertEquals(BUTTON, n.type())
        assertEquals("Delete draft", n.name())
        assertEquals("Delete draft", tooltip(n))
    }

    @Test
    fun badHoverOnlyNoKeyShowsTheRuleALongPressDoes() {
        val slug = "bad-hover-only"
        open(slug)
        val info = node(control.getValue(slug))
        assertEquals("At least 8 characters", info.name())
        assertEquals("At least 8 characters", tooltip(info))
        assertFalse("not focusable", info.isFocusable)
        assertFalse("not clickable", info.isClickable)
        val c = rect(info)
        val base = band(c)
        // Every Tab stop, and Enter at Sign up: never the icon, and the
        // tooltip never drawn. Enter at Sign up activating it is the positive
        // control for the keys.
        val stops = mutableListOf<String>()
        for (i in 0 until 5) {
            key("TAB")
            stops.add(focusedName())
            assertFalse("$slug: tooltip drawn after Tab ${i + 1}", drawn(c, base))
        }
        assertFalse("$slug: Tab stops $stops", stops.contains(control.getValue(slug)))
        assertTrue("$slug: Tab stops $stops", stops.contains("c12-bad-hover-only-sign-up"))
        tabTo("c12-bad-hover-only-sign-up")
        key("ENTER")
        waitForCount(slug, 1)
        assertFalse("$slug: tooltip drawn after Enter", drawn(c, base))
        // The positive control: a long press draws it.
        press(c, 800)
        assertTrue("$slug: a long press draws it", waitDrawn(c, base, true, 1_500))
    }

    @Test
    fun badRepeatsNameHasTheSameWordsAsNameAndTooltip() {
        open("bad-repeats-name")
        val n = node(control.getValue("bad-repeats-name"))
        assertEquals(BUTTON, n.type())
        assertEquals("Download", n.name())
        assertEquals("Download", tooltip(n))
    }

    @Test
    fun badOutsideButtonPutsTheTooltipOnANodeOfItsOwn() {
        open("bad-outside-button")
        val outer = node("c12-bad-outside-button-tooltip")
        assertEquals("Delete draft", outer.name())
        assertEquals("Delete draft", tooltip(outer))
        assertFalse("the tooltip's node is not clickable", outer.isClickable)
        assertTrue(outer.type() != BUTTON)
        val buttons = all().filter { it.type() == BUTTON && it.name() != "Back" }
        assertEquals(1, buttons.size)
        assertEquals("", buttons.single().name())
        assertEquals("", tooltip(buttons.single()))
        assertTrue(buttons.single().isClickable)
    }

    @Test
    fun talkBackWalk() {
        fun byId(id: String) = { nodeInAnyWindow(id) }
        fun outsideButton() = {
            nodeInAnyWindow("c12-bad-outside-button-tooltip").let { outer ->
                (0 until outer.childCount).map { outer.getChild(it) }.first { it.type() == BUTTON }
            }
        }
        val walk = listOf(
            "good-material" to listOf(Stop("c12-good-material-delete", find = byId("c12-good-material-delete"))),
            "good-cupertino" to listOf(Stop("c12-good-cupertino-delete", find = byId("c12-good-cupertino-delete"))),
            "good-description" to listOf(Stop("c12-good-description-download", find = byId("c12-good-description-download"))),
            "bad-not-hoverable" to listOf(Stop("c12-bad-not-hoverable-delete", find = byId("c12-bad-not-hoverable-delete"))),
            "bad-hover-only" to listOf(
                Stop("c12-bad-hover-only-info", find = byId("c12-bad-hover-only-info")),
                Stop("c12-bad-hover-only-sign-up", find = byId("c12-bad-hover-only-sign-up")),
            ),
            "bad-repeats-name" to listOf(Stop("c12-bad-repeats-name-download", find = byId("c12-bad-repeats-name-download"))),
            "bad-outside-button" to listOf(
                Stop("c12-bad-outside-button-tooltip", find = byId("c12-bad-outside-button-tooltip")),
                Stop("c12-bad-outside-button-button", find = outsideButton()),
            ),
        )
        talkBackWalk(
            walk,
            open = { slug -> openExampleInAnyWindow(slug) { it.name() == c12Titles.getValue(slug) } },
            dwellMillis = { 5_000 },
        )
    }
}

private val c12Titles = mapOf(
    "good-material" to "Material tooltip",
    "good-cupertino" to "Tooltip on a Cupertino button",
    "good-description" to "Tooltip that describes a button",
    "bad-not-hoverable" to "Tooltip the pointer cannot reach",
    "bad-hover-only" to "Information only on hover",
    "bad-repeats-name" to "Tooltip that repeats the name",
    "bad-outside-button" to "Tooltip outside its button",
)
