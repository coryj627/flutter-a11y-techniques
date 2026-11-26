// L3 (tree) and L4 (TalkBack) for S06 Screen and page titles on Android.
// Spec: docs/specs/S06-screen-titles.md.
//
// Each example is a button that opens a screen (a route pushed on the
// app's Navigator). Flutter gives Android a screen's name as the pane title
// of its FlutterView: the label of the node with namesRoute in the last
// route, or a single space when there is none (AccessibilityBridge,
// onWindowNameChange, read in the source; the S06 probe,
// docs/evidence/probes/s06/android-tree.txt). Every reading after an
// action waits in a bounded loop for the state it expects.
package dev.fluttera11y.flutter_a11y_techniques

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"
private const val TEXT = "Three orders in the last 30 days."

@RunWith(AndroidJUnit4::class)
class S06ScreenTitlesTest : TechniqueTest("S06") {
    private fun open(slug: String) = openExample(slug, By.desc(s06Titles.getValue(slug)), settleMillis = 500)

    private fun openId(slug: String) = "s06-$slug-open"
    private fun textId(slug: String) = "s06-$slug-text"

    /**
     * Every node of the application windows, depth first. The system's
     * windows are left out: the status bar has a pane title of its own,
     * "Status bar" (the probe).
     */
    private fun everywhere(): List<AccessibilityNodeInfo> {
        val out = mutableListOf<AccessibilityNodeInfo>()
        fun collect(n: AccessibilityNodeInfo?) {
            if (n == null) return
            out.add(n)
            for (i in 0 until n.childCount) collect(n.getChild(i))
        }
        for (w in automation.windows) if (w.type == AccessibilityWindowInfo.TYPE_APPLICATION) collect(w.root)
        return out
    }

    /**
     * The pane titles in the app's windows: one per node that has one. The
     * FlutterView has one, the screen's name, once a route has been shown.
     * A read that fails while a window changes counts as none.
     */
    private fun paneTitles(): List<String> = try {
        everywhere().mapNotNull { it.paneTitle?.toString() }
    } catch (e: Exception) {
        emptyList()
    }

    /** The titles of the app's windows. */
    private fun windowTitles(): List<String> =
        automation.windows.filter { it.type == AccessibilityWindowInfo.TYPE_APPLICATION }.map { it.title?.toString().orEmpty() }

    /** Waits up to [ms] for [check] to be true, reading every 100 ms; a miss is caught, not thrown. */
    private fun waitFor(ms: Long, check: () -> Boolean): Boolean {
        val end = System.currentTimeMillis() + ms
        while (System.currentTimeMillis() < end) {
            try {
                if (check()) return true
            } catch (e: Throwable) {
                // A node can go away while it is read.
            }
            Thread.sleep(100)
        }
        return try { check() } catch (e: Throwable) { false }
    }

    private fun hasId(id: String) = everywhere().any { it.viewIdResourceName == id }

    /** Presses the example's button with the click action and waits for the screen it opens. */
    private fun openScreen(slug: String) {
        assertTrue("click on ${openId(slug)}", node(openId(slug)).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        assertTrue("$slug: the screen opened", waitFor(5_000) { hasId(textId(slug)) })
    }

    /** Closes the opened screen with the system Back, and waits for the example screen. */
    private fun closeScreen(slug: String) {
        device.pressBack()
        assertTrue("$slug: the screen closed", waitFor(5_000) { !hasId(textId(slug)) && hasId(openId(slug)) })
    }

    private fun expectPane(what: String, expected: String) {
        waitFor(5_000) { paneTitles() == listOf(expected) }
        assertEquals(what, listOf(expected), paneTitles())
    }

    @Test
    fun theButtonOpensAScreenAndThePaneTitleIsItsNameOrNothing() {
        for (slug in s06Titles.keys) {
            open(slug)
            val button = node(openId(slug))
            assertEquals("$slug button class", BUTTON, button.type())
            assertEquals("$slug button name", "Open orders", button.name())
            // The example screen's own name, from the app's app bar.
            expectPane("$slug: the example screen", s06Titles.getValue(slug))
            openScreen(slug)
            expectPane("$slug: the opened screen", s06PaneTitles.getValue(slug))
            // The window keeps the app's label whatever the screen (the probe).
            assertEquals("$slug: the window title", listOf("Flutter A11Y Techniques"), windowTitles())
            closeScreen(slug)
            // Back gives the example screen its name again.
            expectPane("$slug: after Back", s06Titles.getValue(slug))
        }
    }

    @Test
    fun theOpenedScreensTitleIsAHeadingExceptInBadNoTitle() {
        for (slug in s06Titles.keys) {
            open(slug)
            openScreen(slug)
            val heading = s06Headings[slug]
            val headings = everywhere().filter { it.isHeading }.map { it.name().ifEmpty { it.text?.toString().orEmpty() } }
            if (heading == null) {
                assertEquals("$slug: no heading", emptyList<String>(), headings)
                assertTrue("$slug: the large text is there", everywhere().any { it.name() == "Orders" || it.text?.toString() == "Orders" })
            } else {
                assertEquals("$slug headings", listOf(heading), headings)
            }
            closeScreen(slug)
        }
    }

    @Test
    fun cupertinosBackButtonTakesTheClickOnANodeWithNoName() {
        // FL-303. Material's Back is the positive control, in the same launch.
        for (slug in listOf("good-material", "good-cupertino", "bad-cupertino-unnamed")) {
            open(slug)
            openScreen(slug)
            val clickable = everywhere().filter { it.isClickable && it.viewIdResourceName == null }
            val named = everywhere().filter { it.name() == "Back" }
            Log.i("S06", "$slug: clickable ${clickable.map { "${it.type()} \"${it.name()}\"" }}; named Back ${named.map { "${it.type()} clickable=${it.isClickable}" }}")
            if (slug == "good-material") {
                assertEquals("$slug: one node named Back", 1, named.size)
                assertTrue("$slug: it takes the click", named.single().isClickable)
            } else {
                assertEquals("$slug: one node named Back", 1, named.size)
                assertTrue("$slug: the node named Back takes no click", !named.single().isClickable)
                assertTrue("$slug: a clickable node with no name",
                    clickable.any { it.name().isEmpty() && it.text.isNullOrEmpty() })
            }
            closeScreen(slug)
        }
    }

    @Test
    fun tabReachesTheButtonAndEnterOpensTheScreen() {
        for (slug in listOf("good-material", "good-cupertino")) {
            open(slug)
            var reached = false
            for (i in 0 until 4) {
                device.executeShellCommand("input keyevent KEYCODE_TAB")
                Thread.sleep(500)
                if (node(openId(slug)).isFocused) {
                    reached = true
                    break
                }
            }
            assertTrue("$slug: Tab reached the button", reached)
            assertTrue("$slug: not open before Enter", !hasId(textId(slug)))
            device.executeShellCommand("input keyevent KEYCODE_ENTER")
            assertTrue("$slug: Enter opened the screen", waitFor(5_000) { hasId(textId(slug)) })
            expectPane("$slug: opened by Enter", s06PaneTitles.getValue(slug))
            closeScreen(slug)
        }
    }

    /**
     * L4. For each example: TalkBack focus on its button (`-open`); then
     * the button pressed with the click action, the marker logged first, and
     * everything TalkBack says for eight seconds as the screen opens
     * (`-opened`); then the system Back, the marker logged first, and eight
     * seconds as the screen closes (`-closed`). tool/talkback.py reads the
     * speech between the markers and judges the walk whole.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        for (slug in s06Titles.keys) {
            openExampleInAnyWindow(slug) { it.name() == s06Titles.getValue(slug) }
            Thread.sleep(8_000)
            Log.i(talkBackTag, "FOCUS s06-$slug-open")
            talkBackFocus("s06-$slug-open") { nodeInAnyWindow(openId(slug)) }
            Thread.sleep(4_000)
            Log.i(talkBackTag, "FOCUS s06-$slug-opened")
            assertTrue(nodeInAnyWindow(openId(slug)).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            Thread.sleep(8_000)
            assertTrue("$slug: the screen opened", waitFor(2_000) { hasId(textId(slug)) })
            Log.i(talkBackTag, "FOCUS s06-$slug-closed")
            device.pressBack()
            Thread.sleep(8_000)
            assertTrue("$slug: the screen closed", waitFor(2_000) { !hasId(textId(slug)) })
            Log.i(talkBackTag, "END $slug")
        }
    }
}

private val s06Titles = linkedMapOf(
    "good-material" to "Material screen title",
    "good-cupertino" to "Cupertino screen title",
    "bad-no-title" to "Screen with no title",
    "bad-vague-title" to "Screen titled Details",
    "bad-no-document-title" to "Screen with no document title",
    "bad-cupertino-unnamed" to "Cupertino bar that names no screen",
)

/** The FlutterView's pane title once each example's screen is open: a single space where no node names the route. */
private val s06PaneTitles = mapOf(
    "good-material" to "Orders",
    "good-cupertino" to "Orders",
    "bad-no-title" to " ",
    "bad-vague-title" to "Details",
    "bad-no-document-title" to "Orders",
    "bad-cupertino-unnamed" to " ",
)

/** The opened screen's one heading; null for none. */
private val s06Headings = mapOf(
    "good-material" to "Orders",
    "good-cupertino" to "Orders",
    "bad-no-title" to null,
    "bad-vague-title" to "Details",
    "bad-no-document-title" to "Orders",
    "bad-cupertino-unnamed" to "Orders",
)
