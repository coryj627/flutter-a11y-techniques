// L3 (tree) and L4 (TalkBack walk) for S05 Headings on Android.
// Spec: docs/specs/S05-headings.md.
//
// Elements are found by their text: headings have no controls to identify,
// and their text is what the tests are about.
package dev.fluttera11y.flutter_a11y_techniques

import android.app.UiAutomation
import android.content.Intent
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Configurator
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class S05HeadingsTest {
    private val inst = InstrumentationRegistry.getInstrumentation()

    // Without this flag a connected test switches TalkBack off.
    private val automation: UiAutomation = run {
        Configurator.getInstance().setUiAutomationFlags(
            UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        inst.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
    }
    private val device: UiDevice = UiDevice.getInstance(inst)

    private fun open(slug: String) {
        val intent = Intent(inst.targetContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            .putExtra("route", "/t/S05/$slug")
        inst.targetContext.startActivity(intent)
        // Wait for this example's own title. A text every example screen has
        // would also match the previous screen while the new one loads.
        assertTrue("example $slug did not open",
            device.wait(Until.hasObject(By.desc(titles.getValue(slug))), 20_000))
        device.waitForIdle()
    }

    private val titles = mapOf(
        "good-levels" to "Headings with levels",
        "good-cupertino" to "Cupertino section heading",
        "bad-visual-only" to "Heading by appearance only",
        "bad-fake-label" to "The word \"heading\" in the name",
        "bad-skipped-level" to "Skipped heading level",
        "bad-header-only" to "Heading with no level",
        "bad-emphasis-heading" to "Heading used for emphasis",
        "bad-cupertino-section-header" to "Cupertino section header that is not a heading",
    )

    private fun find(root: AccessibilityNodeInfo?, text: String): AccessibilityNodeInfo? {
        if (root == null) return null
        if (root.contentDescription?.toString() == text) return root
        for (i in 0 until root.childCount) find(root.getChild(i), text)?.let { return it }
        return null
    }

    private fun node(text: String): AccessibilityNodeInfo =
        find(automation.rootInActiveWindow, text) ?: throw AssertionError("no node with text \"$text\"")

    private fun assertHeading(text: String) = assertTrue("\"$text\" should be a heading", node(text).isHeading)

    private fun assertNotHeading(text: String) =
        assertFalse("\"$text\" should not be a heading", node(text).isHeading)

    @Test
    fun goodLevelsAreHeadingsAndBodyTextIsNot() {
        open("good-levels")
        listOf("Profile", "Contact details", "Email preferences", "Security").forEach(::assertHeading)
        assertNotHeading("Choose which messages you receive.")
        // The screen title and the shell's section heading are headings too.
        assertHeading("Headings with levels")
        assertHeading("Example")
    }

    @Test
    fun goodCupertinoSectionHeaderIsAHeading() {
        open("good-cupertino")
        assertHeading("Notifications")
        assertNotHeading("Order updates")
    }

    // VAL-3: each bad example is asserted to have its named defect.

    @Test
    fun badVisualOnlyIsNotAHeading() {
        open("bad-visual-only")
        assertNotHeading("Profile")
    }

    @Test
    fun badFakeLabelIsNotAHeading() {
        open("bad-fake-label")
        assertNotHeading("Profile, heading")
    }

    @Test
    fun badSkippedLevelExposesNoLevelsOnAndroid() {
        // Android has one heading level: both are headings and the skipped
        // level cannot be seen here. It is asserted in the widget and web tests.
        open("bad-skipped-level")
        assertHeading("Profile")
        assertHeading("Contact details")
    }

    @Test
    fun badHeaderOnlyIsNotAHeadingOnAndroid() {
        // Flutter limitation FL-005: Android takes the heading property from
        // headingLevel only. If "Profile" becomes a heading after an upgrade,
        // the limitation is fixed.
        open("bad-header-only")
        assertNotHeading("Profile")
    }

    @Test
    fun badEmphasisHeadingMarksASentenceAsAHeading() {
        open("bad-emphasis-heading")
        assertHeading("Please check your address before you pay.")
    }

    @Test
    fun badCupertinoSectionHeaderIsNotAHeading() {
        // Flutter limitation: CupertinoListSection does not expose its header.
        open("bad-cupertino-section-header")
        assertNotHeading("Notifications")
    }

    /**
     * L4. Moves TalkBack focus to each listed element and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running.
     */
    @Test
    fun talkBackWalk() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
        // slug -> (key suffix, text of the element)
        val walk = listOf(
            "good-levels" to listOf(
                "profile" to "Profile", "contact-details" to "Contact details",
                "email-preferences" to "Email preferences", "security" to "Security",
                "body" to "Choose which messages you receive."),
            "good-cupertino" to listOf("notifications" to "Notifications"),
            "bad-visual-only" to listOf("profile" to "Profile"),
            "bad-fake-label" to listOf("profile" to "Profile, heading"),
            "bad-skipped-level" to listOf("profile" to "Profile", "contact-details" to "Contact details"),
            "bad-header-only" to listOf("profile" to "Profile"),
            "bad-emphasis-heading" to listOf("notice" to "Please check your address before you pay."),
            "bad-cupertino-section-header" to listOf("notifications" to "Notifications"),
        )
        for ((slug, elements) in walk) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for ((key, text) in elements) {
                Log.i("S05TB", "FOCUS s05-$slug-$key")
                node(text).performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
                Thread.sleep(4_500)
            }
            Log.i("S05TB", "END $slug")
        }
    }
}
