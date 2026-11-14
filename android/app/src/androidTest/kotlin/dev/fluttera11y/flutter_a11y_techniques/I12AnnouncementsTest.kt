// L3 (tree) and L4 (TalkBack) for I12 Announcements and live regions on Android.
// Spec: docs/specs/I12-announcements.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.app.UiAutomation
import android.content.Intent
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.Configurator
import androidx.test.uiautomator.UiDevice
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class I12AnnouncementsTest {
    private val inst = InstrumentationRegistry.getInstrumentation()

    // Without this flag a connected test switches TalkBack off.
    private val automation: UiAutomation = run {
        Configurator.getInstance().setUiAutomationFlags(
            UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        inst.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
    }
    private val device: UiDevice = UiDevice.getInstance(inst)

    private val titles = mapOf(
        "good-live-region" to "Status message in a live region",
        "good-announce" to "Announcement sent from code, with a fallback",
        "good-snackbar" to "SnackBar",
        "bad-silent-update" to "Status message that is not announced",
        "bad-chatty-live-region" to "Live region that changes every second",
        "bad-status-role-only" to "Status role with no live region",
        "bad-alert-role-only" to "Alert role with no live region",
    )

    private fun open(slug: String) {
        val intent = Intent(inst.targetContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            .putExtra("route", "/t/I12/$slug")
        inst.targetContext.startActivity(intent)
        // Wait for this example's own title. A text every example screen has
        // would also match the previous screen while the new one loads.
        // Looked for in every window: with TalkBack running a system dialog
        // can be the active window while the app is on screen behind it.
        val title = titles.getValue(slug)
        val end = System.currentTimeMillis() + 20_000
        while (!anyWindowHas { it.contentDescription?.toString() == title }) {
            assertTrue("example $slug did not open", System.currentTimeMillis() < end)
            Thread.sleep(250)
        }
        device.waitForIdle()
    }

    private fun anyWindowHas(match: (AccessibilityNodeInfo) -> Boolean): Boolean {
        fun search(n: AccessibilityNodeInfo?): Boolean {
            if (n == null) return false
            if (match(n)) return true
            for (i in 0 until n.childCount) if (search(n.getChild(i))) return true
            return false
        }
        return search(automation.rootInActiveWindow) || automation.windows.any { search(it.root) }
    }

    private fun find(root: AccessibilityNodeInfo?, id: String): AccessibilityNodeInfo? {
        if (root == null) return null
        if (root.viewIdResourceName == id) return root
        for (i in 0 until root.childCount) find(root.getChild(i), id)?.let { return it }
        return null
    }

    /**
     * Finds a node by test identifier, looking in every window and waiting a
     * few seconds. With TalkBack running, a system dialog or TalkBack's own
     * overlay can be the active window for a moment, so the active window
     * alone is not a reliable place to look.
     */
    private fun node(id: String): AccessibilityNodeInfo {
        val end = System.currentTimeMillis() + 8_000
        while (true) {
            find(automation.rootInActiveWindow, id)?.let { return it }
            for (window in automation.windows) find(window.root, id)?.let { return it }
            if (System.currentTimeMillis() > end) {
                throw AssertionError("no node with id $id; on screen: ${describeScreen()}")
            }
            Thread.sleep(250)
        }
    }

    /** Identifiers and texts in every window, for a failure message. */
    private fun describeScreen(): String {
        val seen = mutableListOf<String>()
        fun walk(n: AccessibilityNodeInfo?) {
            if (n == null) return
            val label = n.viewIdResourceName ?: n.contentDescription?.toString()
            if (!label.isNullOrEmpty()) seen.add(label.take(40))
            for (i in 0 until n.childCount) walk(n.getChild(i))
        }
        automation.windows.forEach { seen.add("[window ${it.title}]"); walk(it.root) }
        return seen.joinToString(" | ")
    }

    private fun status(slug: String): AccessibilityNodeInfo = node("i12-$slug-status")

    private fun press(slug: String) =
        assertTrue("$slug action", node("i12-$slug-action").performAction(AccessibilityNodeInfo.ACTION_CLICK))

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
     * running.
     */
    @Test
    fun talkBackWalk() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
        for (slug in titles.keys) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            Log.i("I12TB", "FOCUS i12-$slug-announced")
            press(slug)
            // The chatty example needs a few seconds to show its defect.
            Thread.sleep(if (slug == "bad-chatty-live-region") 7_000 else 5_000)
            Log.i("I12TB", "END $slug")
        }
    }
}
