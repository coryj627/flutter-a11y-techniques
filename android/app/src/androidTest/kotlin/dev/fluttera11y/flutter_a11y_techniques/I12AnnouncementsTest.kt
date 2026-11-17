// L3 (tree) and L4 (TalkBack) for I12 Announcements and live regions on Android.
// Spec: docs/specs/I12-announcements.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.util.Log
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class I12AnnouncementsTest : TechniqueTest("I12") {
    private val titles = mapOf(
        "good-live-region" to "Status message in a live region",
        "good-announce" to "Announcement sent from code, with a fallback",
        "good-snackbar" to "SnackBar",
        "bad-silent-update" to "Status message that is not announced",
        "bad-chatty-live-region" to "Live region that changes every second",
        "bad-status-role-only" to "Status role with no live region",
        "bad-alert-role-only" to "Alert role with no live region",
    )

    // Waits for this example's own title, looked for in every window.
    private fun open(slug: String) {
        val title = titles.getValue(slug)
        openExampleInAnyWindow(slug) { it.contentDescription?.toString() == title }
    }

    // Nodes are looked for in every window, with a retry (nodeInAnyWindow).
    private fun status(slug: String): AccessibilityNodeInfo = nodeInAnyWindow("i12-$slug-status")

    private fun press(slug: String) =
        assertTrue("$slug action", nodeInAnyWindow("i12-$slug-action").performAction(AccessibilityNodeInfo.ACTION_CLICK))

    private fun waitForText(slug: String, text: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end &&
            status(slug).contentDescription?.toString() != text) Thread.sleep(100)
        assertEquals("$slug status text", text, status(slug).contentDescription?.toString())
    }

    @Test
    fun goodLiveRegionIsPoliteAndItsTextChanges() {
        open("good-live-region")
        assertEquals(View.ACCESSIBILITY_LIVE_REGION_POLITE, status("good-live-region").liveRegion)
        assertEquals("Cart is empty", status("good-live-region").contentDescription?.toString())
        press("good-live-region")
        waitForText("good-live-region", "1 item in cart")
    }

    @Test
    fun goodAnnounceFallsBackToALiveRegionOnAndroid() {
        // Android does not support announcements sent from code, so the
        // example makes its visible confirmation a live region here.
        open("good-announce")
        press("good-announce")
        waitForText("good-announce", "Link copied")
        assertEquals(View.ACCESSIBILITY_LIVE_REGION_POLITE, status("good-announce").liveRegion)
    }

    // VAL-3: each bad example is asserted to have its named defect.

    @Test
    fun badChattyLiveRegionKeepsChanging() {
        open("bad-chatty-live-region")
        assertEquals(View.ACCESSIBILITY_LIVE_REGION_POLITE, status("bad-chatty-live-region").liveRegion)
        press("bad-chatty-live-region")
        val seen = mutableSetOf<String>()
        val end = System.currentTimeMillis() + 4_500
        while (System.currentTimeMillis() < end) {
            status("bad-chatty-live-region").contentDescription?.toString()?.let(seen::add)
            Thread.sleep(200)
        }
        assertTrue("several different messages in a few seconds, got $seen", seen.size >= 3)
    }

    @Test
    fun badMessagesAreNotLiveRegionsOnAndroid() {
        // bad-silent-update has nothing. The status and alert roles are
        // Flutter limitations: on Android they set no live region. If either
        // becomes a live region after an upgrade, the limitation is fixed.
        for ((slug, text) in listOf(
            "bad-silent-update" to "1 item in cart",
            "bad-status-role-only" to "1 item in cart",
            "bad-alert-role-only" to "Could not save. Attempt 1 failed.")) {
            open(slug)
            press(slug)
            waitForText(slug, text)
            assertEquals("$slug live region", View.ACCESSIBILITY_LIVE_REGION_NONE, status(slug).liveRegion)
        }
    }

    /**
     * L4. Presses each example's button and logs markers around it;
     * tool/talkback.py reads what TalkBack announced from logcat. Focus is
     * parked on the screen title first, so anything spoken after the press
     * is an announcement, not a focus change. Skipped unless TalkBack is
     * running. Not TechniqueTest.talkBackWalk: it presses, and moves no focus.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        for (slug in titles.keys) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            Log.i("I12TB", "FOCUS i12-$slug-announced")
            press(slug)
            // The chatty example needs a few seconds to show its defect.
            Thread.sleep(if (slug == "bad-chatty-live-region") 7_000 else 5_000)
            if (slug == "good-announce") {
                // A second press must be announced too, although the message
                // on screen ends up the same.
                Log.i("I12TB", "FOCUS i12-$slug-announced-again")
                press(slug)
                Thread.sleep(5_000)
            }
            Log.i("I12TB", "END $slug")
        }
    }
}
