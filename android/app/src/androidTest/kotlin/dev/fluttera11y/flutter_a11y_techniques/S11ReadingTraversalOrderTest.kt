// L3 (tree) and L4 (TalkBack walk) for S11 Reading and traversal order on
// Android. Spec: docs/specs/S11-reading-traversal-order.md.
//
// The order TalkBack moves in is the order of the nodes in the tree, which
// Flutter writes in its own reading order and ties together with
// traversal-after links (read in the engine's source, AccessibilityBridge;
// the probe, docs/evidence/probes/s11/, measured TalkBack following it). The
// texts and headings are found by their names, the buttons by their test
// identifiers. Keys come from a keyboard registered with the shell's
// `uinput` tool, as in V14, so that Shift+Tab is a real Shift and Tab.
package dev.fluttera11y.flutter_a11y_techniques

import android.app.UiAutomation
import android.graphics.Rect
import android.os.ParcelFileDescriptor
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * A USB keyboard registered with the shell's `uinput` tool for as long as
 * the session is open, as V14's test registers one: its keys reach the app
 * through the kernel, as a real keyboard's do. Closing it removes the
 * device.
 */
private class S11Keyboard(automation: UiAutomation, dumpsys: () -> String) : AutoCloseable {
    private val fds: Array<ParcelFileDescriptor> = automation.executeShellCommandRw("uinput -")
    private val stdin = ParcelFileDescriptor.AutoCloseOutputStream(fds[1])

    init {
        send("""{"id":1,"command":"register","name":"$NAME","vid":4660,"pid":22145,"bus":"usb",""" +
            """"configuration":[{"type":"UI_SET_EVBIT","data":["EV_KEY","EV_SYN"]},""" +
            """{"type":"UI_SET_KEYBIT","data":["KEY_TAB","KEY_SPACE","KEY_ENTER","KEY_LEFTSHIFT",""" +
            """"KEY_LEFTMETA","KEY_RIGHT","KEY_LEFT"]}]}""")
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

    /** Presses [keys] down in order, then lets them go in reverse order: KEY_LEFTSHIFT, KEY_TAB. */
    fun press(vararg keys: String) {
        val down = keys.joinToString(",") { "\"EV_KEY\",\"$it\",1,\"EV_SYN\",\"SYN_REPORT\",0" }
        val up = keys.reversed().joinToString(",") { "\"EV_KEY\",\"$it\",0,\"EV_SYN\",\"SYN_REPORT\",0" }
        send("""{"id":1,"command":"inject","events":[$down,$up]}""")
    }

    override fun close() {
        stdin.close()
        ParcelFileDescriptor.AutoCloseInputStream(fds[0]).use { it.readBytes() }
    }

    companion object {
        const val NAME = "S11 test keyboard"
    }
}

private const val ROUTE = "Route"
private const val BRING = "Bring"
private val STEPS = listOf("Park at the gate.", "Climb the ridge.", "Walk back.")
private val ITEMS = listOf("Water", "A map")

/** The order meant: the route column, then the bring column, then the counts. */
private val MEANT = listOf(
    "$ROUTE | heading", STEPS[0], STEPS[1], STEPS[2], "Save route | button",
    "$BRING | heading", ITEMS[0], ITEMS[1], "Save list | button",
    "Route saves: 0", "List saves: 0",
)

@RunWith(AndroidJUnit4::class)
class S11ReadingTraversalOrderTest : TechniqueTest("S11") {
    private var keyboard: S11Keyboard? = null

    private fun keys(): S11Keyboard =
        keyboard ?: S11Keyboard(automation) { device.executeShellCommand("dumpsys input") }.also { keyboard = it }

    @After
    fun removeKeyboard() {
        keyboard?.close()
        keyboard = null
    }

    /** Waits for the example's own title. */
    private fun open(slug: String) = openExample(slug, By.desc(s11Titles.getValue(slug)), settleMillis = 500)

    private fun id(slug: String, name: String) = "s11-$slug-$name"

    private fun describe(n: AccessibilityNodeInfo): String = listOfNotNull(
        n.name(),
        if (n.isHeading) "heading" else null,
        if (n.type() == "android.widget.Button") "button" else null,
    ).joinToString(" | ")

    /**
     * The example's named nodes after the "Example" heading, in the tree's
     * order, to the last count: the order TalkBack moves in. A node out of
     * view is not in the tree, and on CI's 320 by 640 emulator the end of
     * the example is below the view, so the screen is read from the top and
     * then scrolled a step at a time until the last count is in the tree;
     * each node is kept once, in the order first seen. Two nodes with the
     * same name, class, and identifier would count as one; no example has
     * two.
     */
    private fun readingOrder(slug: String): List<String> {
        val last = id(slug, "list-saves")
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        val seen = mutableSetOf<String>()
        for (step in 0 until 8) {
            for (n in all()) {
                if (seen.add("${n.name()}|${n.type()}|${n.viewIdResourceName}")) nodes.add(n)
            }
            if (nodes.any { it.viewIdResourceName == last }) break
            val view = all().firstOrNull { it.isScrollable } ?: break
            if (!view.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) break
            Thread.sleep(500)
        }
        val start = nodes.indexOfFirst { it.name() == "Example" }
        assertTrue("the Example heading", start >= 0)
        assertTrue("the last count", nodes.any { it.viewIdResourceName == last })
        return nodes.subList(start + 1, nodes.size).filter { it.name().isNotEmpty() }.map(::describe)
    }

    /** The control with keyboard focus: "back", "save-route", "save-list", or "none". */
    private fun stop(slug: String): String {
        val focused = all().filter { it.isFocused && (it.viewIdResourceName != null || it.name().isNotEmpty()) }
        if (focused.isEmpty()) return "none"
        assertEquals("nodes with focus: ${focused.map { it.viewIdResourceName ?: it.name() }}", 1, focused.size)
        val node = focused.single()
        if (node.name() == "Back") return "back"
        val nodeId = node.viewIdResourceName.orEmpty()
        return if (nodeId.startsWith("s11-$slug-")) nodeId.removePrefix("s11-$slug-") else "other: $nodeId ${node.name()}"
    }

    /**
     * Presses Tab (or Shift+Tab) once and waits up to 3 seconds for focus to
     * settle on a stop other than [from]; the key is sent once and never
     * again.
     */
    private fun tab(slug: String, from: String, shift: Boolean = false): String {
        if (shift) keys().press("KEY_LEFTSHIFT", "KEY_TAB") else keys().press("KEY_TAB")
        val end = System.currentTimeMillis() + 3_000
        var now = stop(slug)
        while (now == from && System.currentTimeMillis() < end) {
            Thread.sleep(100)
            now = stop(slug)
        }
        return now
    }

    private fun walk(slug: String, n: Int, shift: Boolean = false): List<String> {
        val stops = mutableListOf<String>()
        var at = stop(slug)
        for (i in 0 until n) {
            at = tab(slug, at, shift)
            stops.add(at)
        }
        return stops
    }

    /** The number a count shows: 2 for "Route saves: 2". */
    private fun countOf(slug: String, name: String): Int = revealed(id(slug, name)).name().substringAfter(": ").toInt()

    private fun counts(slug: String) = mapOf("route" to countOf(slug, "route-saves"), "list" to countOf(slug, "list-saves"))

    /** Waits up to 5 seconds for the counts to be [expected]. */
    private fun waitForCounts(what: String, slug: String, expected: Map<String, Int>) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && counts(slug) != expected) Thread.sleep(100)
        assertEquals(what, expected, counts(slug))
    }

    @Test
    fun theGoodExamplesAreReadInTheOrderMeant() {
        for (slug in listOf("good-columns", "good-sort-keys")) {
            open(slug)
            assertEquals(slug, MEANT, readingOrder(slug))
        }
    }

    /**
     * The order rests on the parts' positions (FL-420), which depend on the
     * screen and the font, so it is the order measured, on the local
     * emulator (1080 by 2424 at 420 dpi) and at CI's size (320 by 640 at 160
     * dpi); on both, the two titles are read first and the order is not the
     * one meant. Written to fail if Flutter starts to read a column as one
     * block by itself.
     */
    @Test
    fun badColumnsMixedIsReadAcrossTheColumns() {
        open("bad-columns-mixed")
        val read = readingOrder("bad-columns-mixed")
        android.util.Log.i("S11TREE", "bad-columns-mixed: $read")
        assertEquals(listOf("$ROUTE | heading", "$BRING | heading"), read.take(2))
        assertNotEquals(MEANT, read)
        assertEquals("every part is read", MEANT.toSet(), read.toSet())
        assertTrue("measured: $read", read in BAD_COLUMNS_MIXED)
    }

    @Test
    fun badKeyMissingReadsTheBringTitleSecond() {
        open("bad-key-missing")
        assertEquals(
            listOf(
                "$ROUTE | heading", "$BRING | heading", STEPS[0], STEPS[1], STEPS[2], "Save route | button",
                ITEMS[0], ITEMS[1], "Save list | button", "Route saves: 0", "List saves: 0",
            ),
            readingOrder("bad-key-missing"),
        )
    }

    /**
     * Tab from the screen as it opens, round to Back, and Shift+Tab the same
     * backwards: in every example the buttons are reached in the order
     * meant, which in the good examples is also their reading order. The
     * first key can be taken leaving touch mode, so the walk starts by
     * reaching Back.
     */
    @Test
    fun tabReachesTheButtonsInTheirReadingOrderAndShiftTabGoesBack() {
        for (slug in s11Titles.keys) {
            open(slug)
            var at = stop(slug)
            for (i in 0 until 3) {
                if (at == "back") break
                at = tab(slug, at)
            }
            assertEquals("$slug: Tab reaches Back first", "back", at)
            assertEquals(slug, listOf("save-route", "save-list", "back"), walk(slug, 3))
            assertEquals("$slug Shift+Tab", listOf("save-list", "save-route", "back"), walk(slug, 3, shift = true))
        }
    }

    @Test
    fun eachButtonIsActivatedAloneByTheClickActionATapAndTabThenEnterOrSpace() {
        for (slug in s11Titles.keys) {
            for ((name, count) in listOf("save-route" to "route", "save-list" to "list")) {
                val one = mapOf("route" to if (count == "route") 1 else 0, "list" to if (count == "list") 1 else 0)
                // The click action: what TalkBack's double tap performs.
                open(slug)
                waitForCounts("$slug before", slug, mapOf("route" to 0, "list" to 0))
                assertTrue("$slug $name click", node(id(slug, name)).performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForCounts("$slug: the click action on $name", slug, one)
                // A tap at its centre.
                open(slug)
                val r = Rect().also { node(id(slug, name)).getBoundsInScreen(it) }
                device.click(r.centerX(), r.centerY())
                waitForCounts("$slug: a tap on $name", slug, one)
                // Tab to it, then Enter, then (from a fresh open) Space.
                for (key in listOf("KEY_ENTER", "KEY_SPACE")) {
                    open(slug)
                    var at = stop(slug)
                    for (i in 0 until 6) {
                        if (at == name) break
                        at = tab(slug, at)
                    }
                    assertEquals("$slug: Tab reaches $name", name, at)
                    keys().press(key)
                    waitForCounts("$slug: Tab then $key on $name", slug, one)
                }
            }
        }
    }

    /**
     * L4. Puts TalkBack's focus on the "Example" heading and moves it with
     * TalkBack's own "next" key, Search (Meta) and Right on the registered
     * keyboard (Alt and Right moved nothing in the probe), logging a marker
     * before each move, to the end of the example;
     * tool/talkback.py reads what was said after each marker, and so the
     * order TalkBack moved in. Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        keys()
        for ((slug, stops) in TALKBACK_STOPS) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            talkBackFocus("the Example heading of $slug") { all().first { it.name() == "Example" } }
            Thread.sleep(3_000)
            for (marker in stops) {
                android.util.Log.i(talkBackTag, "FOCUS s11-$slug-$marker")
                keys().press("KEY_LEFTMETA", "KEY_RIGHT")
                Thread.sleep(3_000)
            }
            android.util.Log.i(talkBackTag, "END $slug")
        }
    }
}

/** The orders of bad-columns-mixed measured on the local emulator and at CI's size. */
private val BAD_COLUMNS_MIXED = listOf(
    listOf(
        "$ROUTE | heading", "$BRING | heading", STEPS[0], ITEMS[0], STEPS[1], ITEMS[1], STEPS[2],
        "Save route | button", "Save list | button", "Route saves: 0", "List saves: 0",
    ),
)

/**
 * The stops of each TalkBack walk, in the order meant to be heard, one per
 * press of "next" after the Example heading; tool/techniques/
 * s11_reading_traversal_order.py says what each must be.
 */
private val TALKBACK_STOPS = mapOf(
    "good-columns" to listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"),
    "good-sort-keys" to listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"),
    "bad-columns-mixed" to listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"),
    "bad-key-missing" to listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"),
)

/** Each example's title, as the app shows it in the app bar. */
private val s11Titles = mapOf(
    "good-columns" to "Two columns, each kept together",
    "good-sort-keys" to "Columns laid out row by row, given an order",
    "bad-columns-mixed" to "Two columns read row by row",
    "bad-key-missing" to "One part with no sort key",
)
