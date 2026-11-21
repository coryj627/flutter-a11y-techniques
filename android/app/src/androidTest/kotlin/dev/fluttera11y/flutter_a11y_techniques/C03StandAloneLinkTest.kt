// L3 (tree) and L4 (TalkBack walk) for C03 Stand-alone link on Android.
// Spec: docs/specs/C03-stand-alone-link.md.
//
// Android has no link role a node can declare. With linkUrl, Flutter's node
// is an android.view.View whose content description carries a URLSpan with
// the address; without it, the node is an android.widget.Button (FL-032).
// Every link goes to the technique's page, whose title is "Stand-alone
// link"; "followed once" is checked by one Back bringing the example back.
package dev.fluttera11y.flutter_a11y_techniques

import android.text.Spanned
import android.text.style.URLSpan
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"
private const val VIEW = "android.view.View"
private const val IMAGE = "android.widget.ImageView"
private const val NAME = "Read about stand-alone links"
private const val ADDRESS = "#/t/C03"
private const val DESTINATION = "Stand-alone link"

@RunWith(AndroidJUnit4::class)
class C03StandAloneLinkTest : TechniqueTest("C03") {
    /** Waits for the example's own title, then for the picture to decode. */
    private fun open(slug: String) {
        val title = c03Titles.getValue(slug)
        openExample(slug, By.desc(title), settleMillis = 500)
    }

    /** The URLs of the URLSpans in the node's content description. */
    private fun urls(node: AccessibilityNodeInfo): List<String> {
        val desc = node.contentDescription as? Spanned ?: return emptyList()
        return desc.getSpans(0, desc.length, URLSpan::class.java).map { it.url }
    }

    /** The label of the node's click action, "" if it has none. */
    private fun clickLabel(node: AccessibilityNodeInfo): String =
        node.actionList.firstOrNull { it.id == AccessibilityNodeInfo.ACTION_CLICK }?.label?.toString().orEmpty()

    private fun onDestination(): Boolean = anyWindowHas { it.name() == DESTINATION }

    private fun onExample(slug: String): Boolean = anyWindowHas { it.name() == c03Titles.getValue(slug) }

    /** Waits up to 5 seconds for [condition]. */
    private fun waitFor(what: String, condition: () -> Boolean) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !condition()) Thread.sleep(100)
        assertTrue(what, condition())
    }

    /** The technique's page is on screen, then one Back brings [slug] back. */
    private fun expectFollowedOnce(slug: String, how: String) {
        waitFor("$slug: $how opens the technique's page") { onDestination() && !onExample(slug) }
        device.pressBack()
        waitFor("$slug: one Back after $how brings the example back") { onExample(slug) && !onDestination() }
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act (as in I01). */
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

    private val good = mapOf(
        "good-material" to "c03-good-material-link",
        "good-cupertino" to "c03-good-cupertino-link",
        "good-custom" to "c03-good-custom-link",
        "good-image-link" to "c03-good-image-link-link",
    )

    @Test
    fun goodLinksAreNamedNodesWithTheirAddressAndNoButtonClass() {
        for ((slug, id) in good) {
            open(slug)
            val node = node(id)
            assertEquals("$id class", VIEW, node.type())
            assertEquals("$id name", NAME, node.name())
            assertEquals("$id address", listOf(ADDRESS), urls(node))
            assertTrue("$id clickable", node.isClickable)
            assertTrue("$id focusable", node.isFocusable)
            assertTrue("$id enabled", node.isEnabled)
            // onTapHint is the click action's label: what TalkBack says a
            // double tap does.
            assertEquals("$id click label", "open link", clickLabel(node))
            assertEquals("$id: no image node", 0, all().count { it.type() == IMAGE })
        }
    }

    @Test
    fun goodLinksAreFollowedOnceByTheClickAction() {
        // ACTION_CLICK is what TalkBack performs on a double tap.
        for ((slug, id) in good) {
            open(slug)
            assertTrue("$id click", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            expectFollowedOnce(slug, "the click action")
        }
    }

    @Test
    fun goodLinksAreFollowedOnceByATap() {
        for ((slug, id) in good) {
            open(slug)
            val r = android.graphics.Rect().also { node(id).getBoundsInScreen(it) }
            assertTrue("$id tap", device.click(r.centerX(), r.centerY()))
            expectFollowedOnce(slug, "a tap")
        }
    }

    @Test
    fun goodLinksAreReachedByTabAndFollowedByEnter() {
        for ((slug, id) in good) {
            open(slug)
            tabTo(id)
            key("ENTER")
            expectFollowedOnce(slug, "Enter")
        }
    }

    // Each bad example is asserted to have its named defect.

    @Test
    fun badVagueTextIsNamedReadMore() {
        open("bad-vague-text")
        val node = node("c03-bad-vague-text-link")
        assertEquals(VIEW, node.type())
        assertEquals("Read more", node.name())
        assertEquals(listOf(ADDRESS), urls(node))
    }

    @Test
    fun badTapHandlerHasNoAddressAndNoKeyboardFocus() {
        open("bad-tap-handler")
        val id = "c03-bad-tap-handler-link"
        val node = node(id)
        assertEquals(NAME, node.name())
        assertEquals(VIEW, node.type())
        assertEquals(emptyList<String>(), urls(node))
        assertEquals("", clickLabel(node))
        assertTrue(node.isClickable)
        // Tab never gives it focus. The positive control in the same launch:
        // Tab does reach Back, the one other control.
        var backFocused = false
        for (i in 0 until 6) {
            key("TAB")
            assertFalse("Tab ${i + 1} gave it focus", revealed(id).isFocused)
            if (named("Back").isFocused) backFocused = true
        }
        assertTrue("Tab reached Back", backFocused)
        // A click still follows it, which is what hides the defect.
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        expectFollowedOnce("bad-tap-handler", "the click action")
    }

    @Test
    fun badNoAddressIsAButton() {
        open("bad-no-address")
        val node = node("c03-bad-no-address-link")
        assertEquals(BUTTON, node.type())
        assertEquals(NAME, node.name())
        assertEquals(emptyList<String>(), urls(node))
    }

    @Test
    fun badImageNoNameHasNoNameAndNoAddress() {
        open("bad-image-no-name")
        val node = node("c03-bad-image-no-name-link")
        assertEquals("", node.name())
        assertTrue(node.text.isNullOrEmpty())
        assertTrue(node.isClickable)
        // The address rides on the name, so with no name it is gone too, and
        // the picture's image flag gives the node the ImageView class.
        assertEquals(emptyList<String>(), urls(node))
        assertEquals(IMAGE, node.type())
    }

    @Test
    fun badLabelOnImageLeavesTheLinkUnnamed() {
        open("bad-label-on-image")
        val link = all().single { it.isClickable && it.name() != "Back" }
        assertEquals(VIEW, link.type())
        assertEquals("", link.name())
        assertEquals(emptyList<String>(), urls(link))
        // The name is on a second node, the picture.
        val image = all().single { it.type() == IMAGE }
        assertEquals(NAME, image.name())
        assertFalse(image.isClickable)
        assertEquals(1, link.childCount)
        assertEquals(NAME, link.getChild(0).name())
    }

    @Test
    fun badCupertinoButtonIsAButton() {
        open("bad-cupertino-button")
        val node = node("c03-bad-cupertino-button-link")
        // The button flag wins over the address: the class is Button even
        // though the address is there.
        assertEquals(BUTTON, node.type())
        assertEquals(NAME, node.name())
        assertEquals(listOf(ADDRESS), urls(node))
    }

    @Test
    fun badAppAlsoFollowsIsFollowedOnceOffTheWeb() {
        // The defect is on the web only (web_tests/c03_stand_alone_link.spec.js).
        open("bad-app-also-follows")
        val id = "c03-bad-app-also-follows-link"
        assertEquals(VIEW, node(id).type())
        assertEquals(listOf(ADDRESS), urls(node(id)))
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        expectFollowedOnce("bad-app-also-follows", "the click action")
    }

    /**
     * L4. Moves TalkBack focus to each link and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running.
     */
    @Test
    fun talkBackWalk() {
        val byId = { id: String -> Stop(id) { node(id) } }
        val walk: List<Pair<String, List<Stop>>> =
            good.map { (slug, id) -> slug to listOf(byId(id)) } + listOf(
                "bad-vague-text" to listOf(byId("c03-bad-vague-text-link")),
                "bad-tap-handler" to listOf(byId("c03-bad-tap-handler-link")),
                "bad-no-address" to listOf(byId("c03-bad-no-address-link")),
                "bad-image-no-name" to listOf(byId("c03-bad-image-no-name-link")),
                // Only the picture, which has the name. What TalkBack says for
                // the unnamed link round it is not checked: a check that
                // passes on silence would also pass on a lost capture
                // (tool/techniques/c03_stand_alone_link.py).
                "bad-label-on-image" to listOf(
                    Stop("c03-bad-label-on-image-image") { all().single { it.type() == IMAGE } }),
                "bad-cupertino-button" to listOf(byId("c03-bad-cupertino-button-link")),
                "bad-app-also-follows" to listOf(byId("c03-bad-app-also-follows-link")),
            )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val c03Titles = mapOf(
    "good-material" to "Material link",
    "good-cupertino" to "Cupertino link",
    "good-custom" to "Link built from Semantics",
    "good-image-link" to "Picture link named on the link",
    "bad-vague-text" to "Link that says \"Read more\"",
    "bad-tap-handler" to "Underlined text with a tap handler",
    "bad-no-address" to "Link with no address",
    "bad-image-no-name" to "Picture link with no name",
    "bad-label-on-image" to "Name put on the picture inside the link",
    "bad-cupertino-button" to "Link round a Cupertino button",
    "bad-app-also-follows" to "Link the app follows on the web too",
)
