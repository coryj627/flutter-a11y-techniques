// L3 (tree) and L4 (TalkBack walk) for S04 Functional images on Android.
// Spec: docs/specs/S04-functional-images.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"
private const val IMAGE = "android.widget.ImageView"
private const val GUIDE = "Open trail guide"

@RunWith(AndroidJUnit4::class)
class S04FunctionalImagesTest : TechniqueTest("S04") {
    // Waits for the count, then for the picture, which is decoded after the
    // first frame.
    private fun open(slug: String) = openExample(slug, By.res("s04-$slug-count"), settleMillis = 500)

    private fun images(): List<AccessibilityNodeInfo> = all().filter { it.type() == IMAGE }

    /** The clickable nodes of the example: every one but the app bar's Back. */
    private fun clickables(): List<AccessibilityNodeInfo> =
        all().filter { it.isClickable && it.name() != "Back" }

    private val good = mapOf(
        "good-image-button" to mapOf("s04-good-image-button-guide" to GUIDE),
        "good-icon-label" to mapOf("s04-good-icon-label-search" to "Search"),
        "good-image-with-text" to mapOf(
            "s04-good-image-with-text-guide" to "Trail guide",
            "s04-good-image-with-text-print" to "Print"),
        "good-cupertino" to mapOf("s04-good-cupertino-search" to "Search"),
        "good-custom" to mapOf("s04-good-custom-guide" to GUIDE),
        "good-image-regions" to mapOf(
            "s04-good-image-regions-west" to "West trail",
            "s04-good-image-regions-east" to "East trail"),
    )

    @Test
    fun goodExamplesAreNamedButtonsWithNoImage() {
        for ((slug, buttons) in good) {
            open(slug)
            var n = 0
            for ((id, expectedName) in buttons) {
                val node = node(id)
                assertEquals("$id class", BUTTON, node.type())
                assertEquals("$id name", expectedName, node.name())
                assertTrue("$id enabled", node.isEnabled)
                assertTrue("$id clickable", node.isClickable)
                assertTrue("$id focusable", node.isFocusable)
                assertTrue("$id click", node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForCount(slug, ++n)
            }
            assertEquals("$slug image nodes", 0, images().size)
            assertEquals("$slug clickable nodes", buttons.size, clickables().size)
        }
    }

    // Each bad example is asserted to have its named defect.

    @Test
    fun badNoNameHasNoName() {
        open("bad-no-name")
        val node = node("s04-bad-no-name-guide")
        assertEquals("", node.name())
        assertTrue(node.text.isNullOrEmpty())
        assertTrue(node.isClickable)
        // Flutter 3.47.5: the picture's image flag also replaces the button
        // class, so the node is an ImageView that can be clicked.
        assertEquals(IMAGE, node.type())
    }

    @Test
    fun badLabelOnImageLeavesTheButtonUnnamed() {
        open("bad-label-on-image")
        val button = clickables().single()
        assertEquals(BUTTON, button.type())
        assertEquals("", button.name())
        assertTrue(button.text.isNullOrEmpty())
        // The name is on a second node, which is not the button.
        val image = images().single()
        assertEquals(GUIDE, image.name())
        assertFalse(image.isClickable)
        assertEquals(1, button.childCount)
        assertEquals(GUIDE, button.getChild(0).name())
        assertTrue(button.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("bad-label-on-image", 1)
    }

    @Test
    fun badTapGestureIsAnImageNotAButton() {
        open("bad-tap-gesture")
        assertEquals(0, all().count { it.type() == BUTTON && it.name() != "Back" })
        val image = images().single()
        assertEquals(GUIDE, image.name())
        assertFalse(image.isClickable)
        // The tap is on a node of its own with no class of a control and no
        // name. Keyboard access is asserted in the widget tests and on web.
        val tappable = clickables().single()
        assertEquals("", tappable.name())
        assertEquals("android.view.View", tappable.type())
    }

    @Test
    fun badDescribesPictureIsNamedAfterTheIcon() {
        open("bad-describes-picture")
        val node = node("s04-bad-describes-picture-search")
        assertEquals(BUTTON, node.type())
        assertEquals("Magnifying glass", node.name())
    }

    @Test
    fun badImageNotExcludedIsAnImage() {
        open("bad-image-not-excluded")
        val node = node("s04-bad-image-not-excluded-guide")
        assertEquals("Trail guide", node.name())
        assertTrue(node.isClickable)
        // The button class is lost to the picture's image flag.
        assertEquals(IMAGE, node.type())
    }

    @Test
    fun badRedundantLabelNamesTheButtonTwice() {
        open("bad-redundant-label")
        val node = node("s04-bad-redundant-label-print")
        assertEquals(BUTTON, node.type())
        assertEquals("Printer\nPrint", node.name())
    }

    /**
     * L4. Moves TalkBack focus to each control of every example and logs
     * markers; tool/talkback.py reads the speech from logcat. Skipped unless
     * TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        // slug -> stops. The two examples with no identifier have their
        // nodes found by what they are.
        val byId = { id: String -> Stop(id) { node(id) } }
        val walk: List<Pair<String, List<Stop>>> =
            good.map { (slug, buttons) -> slug to buttons.keys.map(byId) } + listOf(
                "bad-no-name" to listOf(byId("s04-bad-no-name-guide")),
                "bad-label-on-image" to listOf(
                    Stop("s04-bad-label-on-image-button") { clickables().single() },
                    Stop("s04-bad-label-on-image-image") { images().single() }),
                "bad-tap-gesture" to listOf(
                    Stop("s04-bad-tap-gesture-tappable") { clickables().single() },
                    Stop("s04-bad-tap-gesture-image") { images().single() }),
                "bad-describes-picture" to listOf(byId("s04-bad-describes-picture-search")),
                "bad-image-not-excluded" to listOf(byId("s04-bad-image-not-excluded-guide")),
                "bad-redundant-label" to listOf(byId("s04-bad-redundant-label-print")),
            )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}
