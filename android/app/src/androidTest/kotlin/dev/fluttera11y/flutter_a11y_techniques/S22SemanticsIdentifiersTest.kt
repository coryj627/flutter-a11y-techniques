// L3 (tree) and L4 (TalkBack walk) for S22 Semantics identifiers for testing
// on Android.
// Spec: docs/specs/S22-semantics-identifiers.md.
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
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"
private const val EDIT_TEXT = "android.widget.EditText"
private const val VIEW = "android.view.View"

@RunWith(AndroidJUnit4::class)
class S22SemanticsIdentifiersTest {
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
            .putExtra("route", "/t/S22/$slug")
        inst.targetContext.startActivity(intent)
        assertTrue("example $slug did not open",
            device.wait(Until.hasObject(By.res("s22-$slug-count")), 20_000))
        device.waitForIdle()
    }

    private fun collect(root: AccessibilityNodeInfo?, out: MutableList<AccessibilityNodeInfo>) {
        if (root == null) return
        out.add(root)
        for (i in 0 until root.childCount) collect(root.getChild(i), out)
    }

    private fun all(): List<AccessibilityNodeInfo> =
        mutableListOf<AccessibilityNodeInfo>().also { collect(automation.rootInActiveWindow, it) }

    private fun AccessibilityNodeInfo.name(): String = contentDescription?.toString().orEmpty()
    private fun AccessibilityNodeInfo.type(): String = className?.toString().orEmpty()
    private fun AccessibilityNodeInfo.hasClickAction(): Boolean =
        actionList.any { it.id == AccessibilityNodeInfo.ACTION_CLICK }

    private fun node(id: String): AccessibilityNodeInfo =
        all().firstOrNull { it.viewIdResourceName == id } ?: throw AssertionError("no node with id $id")

    /** The nodes of the example with the button class: every one but Back. */
    private fun buttons(): List<AccessibilityNodeInfo> =
        all().filter { it.type() == BUTTON && it.name() != "Back" }

    private fun count(slug: String): Int = node("s22-$slug-count").name().substringAfter(": ").toInt()

    private fun waitForCount(slug: String, expected: Int) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && count(slug) != expected) Thread.sleep(100)
        assertEquals("activation count for $slug", expected, count(slug))
    }


    private fun withId(id: String): List<AccessibilityNodeInfo> = all().filter { it.viewIdResourceName == id }

    /** Everything a node gives a screen reader to say. */
    private fun AccessibilityNodeInfo.spoken(): String = listOf(
        contentDescription, text, hintText, tooltipText, stateDescription, paneTitle,
    ).joinToString(" ") { it?.toString().orEmpty() }

    private fun assertNoIdentifierIsSpoken(slug: String) {
        for (node in all()) assertFalse("$slug: ${node.spoken()}", node.spoken().contains("s22-"))
    }

    // On Android `Semantics(identifier:)` is the node's resource id, which
    // UI Automator finds with By.res and TalkBack does not read.
    // slug -> (identifier, name)
    private val buttons = listOf(
        Triple("good-merged", "s22-good-merged-save", "Save draft"),
        Triple("good-cupertino", "s22-good-cupertino-save", "Save draft"),
        Triple("good-custom", "s22-good-custom-save", "Save draft"),
        Triple("bad-id-as-name", "s22-bad-id-as-name-close", ""),
    )

    @Test
    fun theNodeWithTheIdentifierIsTheButton() {
        for ((slug, id, name) in buttons) {
            open(slug)
            assertEquals(slug, 1, withId(id).size)
            val node = node(id)
            assertEquals(slug, BUTTON, node.type())
            assertEquals(slug, name, node.name())
            assertTrue(slug, node.text.isNullOrEmpty())
            assertTrue(slug, node.tooltipText.isNullOrEmpty())
            assertEquals(slug, 1, buttons().size)
            assertNoIdentifierIsSpoken(slug)
            // UI Automator finds the same node by resource id and can use it.
            val found = device.findObject(By.res(id))
            assertEquals(slug, BUTTON, found.className)
            found.click()
            waitForCount(slug, 1)
            assertTrue(slug, node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount(slug, 2)
            assertEquals(slug, name, node(id).name())
        }
    }

    @Test
    fun goodFieldHasItsNameAndTheIdentifier() {
        open("good-field")
        val field = node("s22-good-field-project")
        assertEquals(EDIT_TEXT, field.type())
        // A text field's name is its hint text on Android.
        assertEquals("Project name", field.hintText?.toString())
        assertTrue(field.name().isEmpty())
        assertNoIdentifierIsSpoken("good-field")
    }

    @Test
    fun badInsideLeavesTheButtonWithNoName() {
        open("bad-inside")
        // Flutter 3.47.5: the identifier makes the text a node of its own,
        // which takes the name out of the button (FL-007). Written to fail
        // if the identifier stops splitting the button.
        val button = buttons().single()
        assertEquals("", button.name())
        assertTrue(button.text.isNullOrEmpty())
        assertTrue(button.viewIdResourceName.isNullOrEmpty())
        val text = withId("s22-bad-inside-save").single()
        assertEquals(VIEW, text.type())
        assertEquals("Save draft", text.name())
        assertFalse(text.isClickable)
        assertFalse(text.hasClickAction())
        assertEquals(button, text.parent)
        assertTrue(button.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("bad-inside", 1)
    }

    @Test
    fun badWrapperHasTheIdentifierOnANodeAroundTheButton() {
        open("bad-wrapper")
        // Flutter 3.47.5: FilledButton is a semantics container, so the
        // identifier stays on a node of its own. Written to fail if it
        // starts to join the button.
        val marked = withId("s22-bad-wrapper-save").single()
        assertEquals(VIEW, marked.type())
        assertEquals("", marked.name())
        assertFalse(marked.isClickable)
        assertFalse(marked.hasClickAction())
        val button = buttons().single()
        assertEquals("Save draft", button.name())
        assertTrue(button.viewIdResourceName.isNullOrEmpty())
        assertEquals(marked, button.parent)
        assertTrue(button.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("bad-wrapper", 1)
    }

    @Test
    fun badDuplicateHasTwoButtonsWithOneIdentifier() {
        open("bad-duplicate")
        val marked = withId("s22-bad-duplicate-action")
        assertEquals(listOf("Save draft", "Discard draft"), marked.map { it.name() })
        assertTrue(marked.all { it.type() == BUTTON })
        assertEquals(2, device.findObjects(By.res("s22-bad-duplicate-action")).size)
        // findObject gives no sign that there are two: it returns the first.
        assertEquals("Save draft", device.findObject(By.res("s22-bad-duplicate-action")).contentDescription)
    }

    /**
     * Moves TalkBack focus to the node [find] returns and fails the test if
     * it cannot. A node that already has accessibility focus refuses the
     * action, so focus is cleared and the action tried once more. Without
     * this check a failed focus would pass silently and the transcript would
     * credit the wrong speech to the element.
     */
    private fun talkBackFocus(what: String, find: () -> AccessibilityNodeInfo) {
        if (find().performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)) return
        find().performAction(AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS)
        Thread.sleep(500)
        assertTrue("TalkBack focus on $what",
            find().performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS))
    }

    /**
     * L4. Moves TalkBack focus to each control of every example and logs
     * markers; tool/talkback.py reads the speech from logcat. Skipped unless
     * TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
        val byId = { id: String -> id to { node(id) } }
        val walk: List<Pair<String, List<Pair<String, () -> AccessibilityNodeInfo>>>> =
            buttons.map { (slug, id, _) -> slug to listOf(byId(id)) } + listOf(
                "good-field" to listOf(byId("s22-good-field-project")),
                // The button has no identifier here; it is the only button.
                "bad-inside" to listOf(
                    "s22-bad-inside-button" to { buttons().single() },
                    byId("s22-bad-inside-save")),
                "bad-wrapper" to listOf("s22-bad-wrapper-button" to { buttons().single() }),
                "bad-duplicate" to listOf(
                    "s22-bad-duplicate-save" to { buttons().single { it.name() == "Save draft" } },
                    "s22-bad-duplicate-discard" to { buttons().single { it.name() == "Discard draft" } }),
            )
        for ((slug, elements) in walk) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for ((marker, find) in elements) {
                Log.i("S22TB", "FOCUS $marker")
                talkBackFocus(marker, find)
                Thread.sleep(6_000)
            }
            Log.i("S22TB", "END $slug")
        }
    }
}
