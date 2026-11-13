// L3 (tree) and L4 (TalkBack walk) for C01 Button on Android.
// Spec: docs/specs/C01-button.md.
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
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"

@RunWith(AndroidJUnit4::class)
class C01ButtonTest {
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
            .putExtra("route", "/t/C01/$slug")
        inst.targetContext.startActivity(intent)
        assertTrue("example $slug did not open",
            device.wait(Until.hasObject(By.res("c01-$slug-count")), 20_000))
    }

    private fun find(root: AccessibilityNodeInfo?, id: String): AccessibilityNodeInfo? {
        if (root == null) return null
        if (root.viewIdResourceName == id) return root
        for (i in 0 until root.childCount) find(root.getChild(i), id)?.let { return it }
        return null
    }

    private fun node(id: String): AccessibilityNodeInfo =
        find(automation.rootInActiveWindow, id) ?: throw AssertionError("no node with id $id")

    private fun name(id: String): String = node(id).contentDescription?.toString().orEmpty()

    private fun count(slug: String): Int = name("c01-$slug-count").substringAfter(": ").toInt()

    private fun waitForCount(slug: String, expected: Int) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && count(slug) != expected) Thread.sleep(100)
        assertEquals("activation count for $slug", expected, count(slug))
    }

    private val enabledGood = mapOf(
        "good-text" to mapOf(
            "c01-good-text-filled" to "Save",
            "c01-good-text-outlined" to "Cancel",
            "c01-good-text-text" to "Learn more"),
        "good-icon" to mapOf("c01-good-icon-close" to "Close"),
        "good-unique-names" to mapOf(
            "c01-good-unique-names-username" to "Edit username",
            "c01-good-unique-names-email" to "Edit email",
            "c01-good-unique-names-password" to "Edit password"),
        "good-cupertino" to mapOf("c01-good-cupertino-save" to "Save"),
        "good-custom" to mapOf("c01-good-custom-save" to "Save"),
    )

    private val disabledGood = mapOf(
        "good-disabled" to mapOf("c01-good-disabled-submit" to "Submit"),
        "good-cupertino" to mapOf("c01-good-cupertino-delete" to "Delete"),
    )

    @Test
    fun goodButtonsExposeNameRoleStateAndActivate() {
        for ((slug, buttons) in enabledGood) {
            open(slug)
            var n = 0
            for ((id, expectedName) in buttons) {
                val node = node(id)
                assertEquals("$id class", BUTTON, node.className?.toString())
                assertEquals("$id name", expectedName, name(id))
                assertTrue("$id enabled", node.isEnabled)
                assertTrue("$id clickable", node.isClickable)
                assertTrue("$id focusable", node.isFocusable)
                assertTrue("$id click", node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForCount(slug, ++n)
            }
        }
    }

    @Test
    fun goodDisabledButtonsReportDisabledAndDoNotAct() {
        for ((slug, buttons) in disabledGood) {
            open(slug)
            for ((id, expectedName) in buttons) {
                val node = node(id)
                assertEquals("$id class", BUTTON, node.className?.toString())
                assertEquals("$id name", expectedName, name(id))
                assertFalse("$id enabled", node.isEnabled)
                node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                device.click(node.boundsInScreenCenterX(), node.boundsInScreenCenterY())
            }
            Thread.sleep(500)
            assertEquals("$slug count", 0, count(slug))
        }
    }

    // VAL-3: each bad example is asserted to have its named defect.

    @Test
    fun badUnlabelledIconHasNoName() {
        open("bad-unlabelled-icon")
        val node = node("c01-bad-unlabelled-icon-close")
        assertEquals(BUTTON, node.className?.toString())
        assertEquals("", name("c01-bad-unlabelled-icon-close"))
        assertTrue(node.text.isNullOrEmpty())
    }

    @Test
    fun badGestureOnlyIsNotAButton() {
        open("bad-gesture-only")
        val node = node("c01-bad-gesture-only-save")
        assertNotEquals(BUTTON, node.className?.toString())
        assertEquals("Save", name("c01-bad-gesture-only-save"))
        // Android reports the node as focusable and clickable, so the missing
        // role is the defect visible here. Keyboard access is asserted in the
        // widget tests and on web.
        assertTrue(node.isClickable)
    }

    @Test
    fun badRoleInNameEndsWithRole() {
        open("bad-role-in-name")
        assertTrue(name("c01-bad-role-in-name-close").lowercase().endsWith("button"))
    }

    @Test
    fun badDuplicateNamesAreIdentical() {
        open("bad-duplicate-names")
        val names = listOf("username", "email", "password").map { name("c01-bad-duplicate-names-$it") }
        assertEquals(listOf("Edit", "Edit", "Edit"), names)
    }

    @Test
    fun badNameMismatchLacksVisibleText() {
        open("bad-name-mismatch")
        val name = name("c01-bad-name-mismatch-edit")
        assertEquals("Change username", name)
        assertFalse(name.lowercase().contains("edit"))
    }

    @Test
    fun badFakeDisabledReportsEnabledAndActs() {
        open("bad-fake-disabled")
        val node = node("c01-bad-fake-disabled-submit")
        assertTrue(node.isEnabled)
        node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        waitForCount("bad-fake-disabled", 1)
    }

    @Test
    fun badCupertinoDisabledReportsEnabled() {
        // Flutter limitation: no disabled state. If this fails after an
        // upgrade, the limitation is fixed.
        open("bad-cupertino-disabled")
        val node = node("c01-bad-cupertino-disabled-delete")
        assertEquals(BUTTON, node.className?.toString())
        assertTrue(node.isEnabled)
    }

    /**
     * L4. Moves TalkBack focus to every identified node of every example and
     * logs markers; tool/talkback.py reads the speech from logcat. Skipped
     * unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
        val slugs = listOf(
            "good-text", "good-icon", "good-disabled", "good-unique-names", "good-cupertino",
            "good-custom", "bad-unlabelled-icon", "bad-gesture-only", "bad-role-in-name",
            "bad-duplicate-names", "bad-name-mismatch", "bad-fake-disabled", "bad-cupertino-disabled")
        for (slug in slugs) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            val ids = mutableListOf<String>()
            fun collect(n: AccessibilityNodeInfo?) {
                if (n == null) return
                val id = n.viewIdResourceName
                if (id != null && id.startsWith("c01-") && !id.endsWith("-count")) ids.add(id)
                for (i in 0 until n.childCount) collect(n.getChild(i))
            }
            collect(automation.rootInActiveWindow)
            for (id in ids) {
                Log.i("C01TB", "FOCUS $id")
                node(id).performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
                Thread.sleep(4_500)
            }
            Log.i("C01TB", "END $slug")
        }
    }
}

private fun AccessibilityNodeInfo.bounds() =
    android.graphics.Rect().also { getBoundsInScreen(it) }
private fun AccessibilityNodeInfo.boundsInScreenCenterX() = bounds().centerX()
private fun AccessibilityNodeInfo.boundsInScreenCenterY() = bounds().centerY()
