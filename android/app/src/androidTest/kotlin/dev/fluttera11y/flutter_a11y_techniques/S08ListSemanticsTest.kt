// L3 (tree) and L4 (TalkBack walk) for S08 List semantics on Android.
// Spec: docs/specs/S08-list-semantics.md.
//
// A list's items are found by their names (an identifier on an item would
// be a node of its own); the tiles of a list of tiles by their test
// identifiers. The "Chosen" line under a list of tiles says which tile ran.
package dev.fluttera11y.flutter_a11y_techniques

import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val LIST = "android.widget.ListView"
private const val BUTTON = "android.widget.Button"
private val GROCERIES = listOf("Milk", "Eggs", "Bread")
private val STEPS = listOf("1. Fork the repository", "2. Make the change", "3. Open a pull request")

@RunWith(AndroidJUnit4::class)
class S08ListSemanticsTest : TechniqueTest("S08") {
    private fun open(slug: String) = openExample(slug, By.desc(s08Titles.getValue(slug)), settleMillis = 300)

    /** Every node of the active window, with its depth. */
    private fun tree(): List<Pair<Int, AccessibilityNodeInfo>> {
        val out = mutableListOf<Pair<Int, AccessibilityNodeInfo>>()
        fun walk(n: AccessibilityNodeInfo?, depth: Int) {
            if (n == null) return
            out.add(depth to n)
            for (i in 0 until n.childCount) walk(n.getChild(i), depth + 1)
        }
        walk(automation.rootInActiveWindow, 0)
        return out
    }

    /**
     * The example's nodes, one line each, after the "Example" heading and
     * up to the "Chosen" line or the end: the class, the name, and the
     * collection information, indented by depth under the example. A node
     * with no name and no list class, which only holds others, is left out.
     * The example is short enough for CI's 320 by 640 screen, so the screen
     * is scrolled to its end first and read from there.
     */
    private fun exampleNodes(): List<String> {
        scrollToEnd()
        val all = tree()
        val start = all.indexOfFirst { it.second.name() == "Example" }
        assertTrue("the Example heading", start >= 0)
        val base = all[start].first
        val lines = mutableListOf<String>()
        for ((depth, n) in all.drop(start + 1)) {
            if (n.name().startsWith("Chosen: ")) break
            if (n.name().isEmpty() && n.type() != LIST && n.collectionInfo == null) continue
            val parts = listOfNotNull(
                n.type().substringAfterLast('.'),
                n.name().ifEmpty { null }?.let { "\"${it.replace("\n", "\\n")}\"" },
                n.collectionInfo?.let { "collection ${it.rowCount}x${it.columnCount}" },
                n.collectionItemInfo?.let { "item ${it.rowIndex},${it.columnIndex}" },
            )
            lines.add("  ".repeat(maxOf(0, depth - base)) + parts.joinToString(" "))
        }
        return lines
    }

    /** The "Chosen" line under the list of tiles of [slug]. */
    private fun chosen(slug: String): String = revealed("s08-$slug-chosen").name()

    /**
     * Waits up to 10 seconds for the Chosen line of [slug] to say
     * [expected]. A miss is caught and read again: right after a launch the
     * screen being replaced can still be up (it is the same example), and
     * revealed() throws on a miss.
     */
    private fun waitForChosen(slug: String, expected: String) {
        val end = System.currentTimeMillis() + 10_000
        var last = "(no Chosen line)"
        while (System.currentTimeMillis() < end) {
            last = try {
                chosen(slug)
            } catch (e: AssertionError) {
                "(no Chosen line)"
            }
            if (last == expected) return
            Thread.sleep(200)
        }
        assertEquals(slug, expected, last)
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

    @Test
    fun goodBulletedIsAListOfItsLines() {
        open("good-bulleted")
        assertEquals(listOf("ListView") + GROCERIES.map { "  View \"$it\"" }, exampleNodes())
    }

    @Test
    fun goodNumberedIsAListOfItsSteps() {
        open("good-numbered")
        assertEquals(listOf("ListView") + STEPS.map { "  View \"$it\"" }, exampleNodes())
    }

    @Test
    fun goodMaterialIsAListOfItemsEachHoldingAButton() {
        open("good-material")
        assertEquals(listOf("ListView") + GROCERIES.map { "    Button \"$it\"" }, exampleNodes())
        for (g in GROCERIES) {
            val tile = node("s08-good-material-${g.lowercase()}")
            assertEquals(BUTTON, tile.type())
            assertEquals(g, tile.name())
        }
    }

    @Test
    fun goodCupertinoIsAListNamedByItsHeader() {
        open("good-cupertino")
        assertEquals(listOf("ListView \"Groceries\"") + GROCERIES.map { "  View \"$it\"" }, exampleNodes())
        assertEquals("no button but Back", emptyList<String>(), buttons().map { it.name() })
    }

    @Test
    fun badOneTextIsOneNodeAndNoList() {
        open("bad-one-text")
        assertEquals(listOf("View \"Milk\\nEggs\\nBread\""), exampleNodes())
        assertTrue("no list", tree().none { it.second.type() == LIST || it.second.collectionInfo != null })
    }

    @Test
    fun badNoListHasALineEachAndNoList() {
        open("bad-no-list")
        assertEquals(GROCERIES.map { "View \"$it\"" }, exampleNodes())
        assertTrue("no list", tree().none { it.second.type() == LIST || it.second.collectionInfo != null })
    }

    @Test
    fun badTileInItemIsAButtonOnAndroid() {
        // The defect is on the web (FL-262): on Android the merged item
        // keeps the button.
        open("bad-tile-in-item")
        assertEquals(listOf("ListView") + GROCERIES.map { "  Button \"$it\"" }, exampleNodes())
    }

    /** The scroll view of bad-lazy-list: the scrollable node with collection information. */
    private fun lazyList(): AccessibilityNodeInfo =
        tree().map { it.second }.single { it.isScrollable && it.collectionInfo != null }

    /** Each order in the tree now, with the row its collection item information gives. */
    private fun orderRows(): List<Pair<Int, Int?>> = tree().map { it.second }.mapNotNull { n ->
        Regex("^Order (\\d+)$").find(n.name())?.let { it.groupValues[1].toInt() to n.collectionItemInfo?.rowIndex }
    }

    @Test
    fun badLazyListIsAScrollViewOfThirtyAndNoList() {
        open("bad-lazy-list")
        assertTrue("no list class", tree().none { it.second.type() == LIST })
        val list = lazyList()
        assertEquals("android.widget.ScrollView", list.type())
        assertEquals(30, list.collectionInfo.rowCount)
        assertEquals(1, list.collectionInfo.columnCount)
        // Only the orders near the view are nodes (FL-011), and at the top
        // each has its own row.
        val atStart = orderRows()
        assertTrue("fewer than 30 orders: $atStart", atStart.size < 30)
        assertEquals("Order 1 first", 1, atStart.first().first)
        for ((n, row) in atStart) assertEquals("Order $n", n - 1, row)
    }

    @Test
    fun badLazyListGivesTheWrongRowOnceScrolled() {
        // FL-313: the row is the item's place among the nodes there now,
        // not in the list. Written to fail when the rows are right.
        open("bad-lazy-list")
        for (step in 1..3) {
            assertTrue("scroll $step", lazyList().performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD))
            Thread.sleep(1_000)
        }
        val end = System.currentTimeMillis() + 5_000
        var rows = orderRows()
        while (System.currentTimeMillis() < end && rows.none { it.first > 10 }) {
            Thread.sleep(200)
            rows = orderRows()
        }
        assertTrue("the list scrolled: $rows", rows.any { it.first > 10 })
        assertTrue("an order's row is not its place: $rows", rows.any { (n, row) -> row != null && row != n - 1 })
    }

    @Test
    fun eachTileOpensItsOwnItemByTheClickActionATapAndTabThenEnter() {
        for (slug in listOf("good-material", "bad-tile-in-item")) {
            for (g in GROCERIES) {
                val id = "s08-$slug-${g.lowercase()}"
                // The click action: what TalkBack's double tap performs.
                open(slug)
                waitForChosen(slug, "Chosen: none")
                assertTrue("$id click action", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForChosen(slug, "Chosen: $g")
                // A tap at its centre.
                open(slug)
                waitForChosen(slug, "Chosen: none")
                val r = android.graphics.Rect().also { node(id).getBoundsInScreen(it) }
                assertTrue("$id tap", device.click(r.centerX(), r.centerY()))
                waitForChosen(slug, "Chosen: $g")
                // Tab, then Enter, sent once.
                open(slug)
                waitForChosen(slug, "Chosen: none")
                tabTo(id)
                key("ENTER")
                waitForChosen(slug, "Chosen: $g")
            }
        }
    }

    @Test
    fun noItemHasCollectionItemInformation() {
        // Read in the engine source (BaseRoleConfigurator.java): an item's
        // position is given only to the child of a scrolling list. Written
        // to fail if a list made with the list role starts to have it.
        for (slug in listOf("good-bulleted", "good-numbered", "good-material", "good-cupertino")) {
            open(slug)
            scrollToEnd()
            for ((_, n) in tree()) {
                assertNull("$slug ${n.name()}", n.collectionItemInfo)
                if (n.type() == LIST) assertNull("$slug list", n.collectionInfo)
            }
        }
    }

    /**
     * L4. TalkBack focus moved to each item of each list, and to each line
     * of the bad examples; tool/talkback.py reads what TalkBack says. Skips
     * unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val byName = { marker: String, name: String -> Stop(marker) { all().single { it.name() == name } } }
        val byId = { marker: String, id: String -> Stop(marker) { node(id) } }
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-bulleted" to GROCERIES.map { byName("s08-good-bulleted-${it.lowercase()}", it) },
            "good-numbered" to STEPS.mapIndexed { i, s -> byName("s08-good-numbered-${i + 1}", s) },
            // Then the line after the list, where TalkBack says the list ended.
            "good-material" to GROCERIES.map { byId("s08-good-material-${it.lowercase()}", "s08-good-material-${it.lowercase()}") } +
                byId("s08-good-material-chosen", "s08-good-material-chosen"),
            // The list itself first: its header is its name, and it takes focus.
            "good-cupertino" to listOf(byName("s08-good-cupertino-list", "Groceries")) +
                GROCERIES.map { byName("s08-good-cupertino-${it.lowercase()}", it) },
            "bad-one-text" to listOf(byName("s08-bad-one-text-text", GROCERIES.joinToString("\n"))),
            "bad-no-list" to GROCERIES.map { byName("s08-bad-no-list-${it.lowercase()}", it) },
            "bad-tile-in-item" to GROCERIES.map {
                byId("s08-bad-tile-in-item-${it.lowercase()}", "s08-bad-tile-in-item-${it.lowercase()}")
            } + byId("s08-bad-tile-in-item-chosen", "s08-bad-tile-in-item-chosen"),
        )
        val lazy = "bad-lazy-list" to listOf(1, 2).map { byName("s08-bad-lazy-list-$it", "Order $it") }
        // The lazy list is not scrolled to: scrollToEnd would scroll the
        // list itself where the screen does not scroll.
        talkBackWalk(walk, open = { slug -> open(slug); scrollToEnd() }, dwellMillis = { 5_000 })
        talkBackWalk(listOf(lazy), open = ::open, dwellMillis = { 5_000 })
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val s08Titles = mapOf(
    "good-bulleted" to "Bulleted list",
    "good-numbered" to "Numbered list",
    "good-material" to "List of Material list tiles",
    "good-cupertino" to "Cupertino list section",
    "bad-one-text" to "List in one text",
    "bad-no-list" to "Lines with no list role",
    "bad-tile-in-item" to "List tiles merged into their items",
    "bad-lazy-list" to "Long list in a ListView",
)
