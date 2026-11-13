// L3 (tree) and L4 (TalkBack walk) for F01 Text fields and labels on Android.
// Spec: docs/specs/F01-text-fields.md.
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
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val EDIT_TEXT = "android.widget.EditText"

@RunWith(AndroidJUnit4::class)
class F01TextFieldsTest {
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
            .putExtra("route", "/t/F01/$slug")
        inst.targetContext.startActivity(intent)
        // Wait for this example's own title. A text every example screen has
        // would also match the previous screen while the new one loads.
        assertTrue("example $slug did not open",
            device.wait(Until.hasObject(By.desc(titles.getValue(slug))), 20_000))
        device.waitForIdle()
    }

    private val titles = mapOf(
        "good-label" to "Fields with a label",
        "good-label-above" to "Label above the field",
        "good-cupertino" to "Cupertino field with a label",
        "bad-placeholder-only" to "Placeholder used as the label",
        "bad-unassociated-label" to "Label that is only nearby text",
        "bad-no-label" to "Field with only an icon",
        "bad-name-mismatch" to "Name does not match the visible label",
        "bad-cupertino-placeholder" to "Cupertino field with only a placeholder",
        "bad-cupertino-prefix" to "Cupertino form row prefix as the label",
    )

    private fun find(root: AccessibilityNodeInfo?, id: String): AccessibilityNodeInfo? {
        if (root == null) return null
        if (root.viewIdResourceName == id) return root
        for (i in 0 until root.childCount) find(root.getChild(i), id)?.let { return it }
        return null
    }

    private fun findByText(root: AccessibilityNodeInfo?, text: String): AccessibilityNodeInfo? {
        if (root == null) return null
        if (root.contentDescription?.toString() == text) return root
        for (i in 0 until root.childCount) findByText(root.getChild(i), text)?.let { return it }
        return null
    }

    private fun node(id: String): AccessibilityNodeInfo =
        find(automation.rootInActiveWindow, id) ?: throw AssertionError("no node with id $id")

    /**
     * What names the field for a screen reader: its content description or,
     * as Flutter exposes a field's label on Android, its hint text.
     */
    private fun name(id: String): String = node(id).let {
        it.contentDescription?.toString().orEmpty().ifEmpty { it.hintText?.toString().orEmpty() }
    }

    private fun value(id: String): String = node(id).let {
        // An empty EditText reports its hint as its text.
        if (it.isShowingHintText) "" else it.text?.toString().orEmpty()
    }

    /** Types into the field the way a person does: focus it, then key by key. */
    private fun type(id: String, text: String) {
        assertTrue("$id click", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        Thread.sleep(1_000)
        inst.sendStringSync(text)
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && value(id) != text) Thread.sleep(100)
        assertEquals("$id value", text, value(id))
        // Give the rest of the field's semantics time to follow the value.
        Thread.sleep(1_500)
    }

    private fun describe(id: String) = node(id).let {
        "id=$id class=${it.className} desc=${it.contentDescription} hint=${it.hintText} " +
            "text=${it.text} showingHint=${it.isShowingHintText} editable=${it.isEditable}"
    }

    private val good = mapOf(
        "good-label" to mapOf("f01-good-label-email" to "Email", "f01-good-label-message" to "Message"),
        "good-label-above" to mapOf("f01-good-label-above-name" to "Full name"),
        "good-cupertino" to mapOf("f01-good-cupertino-email" to "Email"),
    )

    @Test
    fun goodFieldsAreEditableAndKeepTheirNameWhenFilled() {
        for ((slug, fields) in good) {
            open(slug)
            for ((id, expectedName) in fields) {
                Log.i("F01", "EMPTY " + describe(id))
                assertEquals("$id class", EDIT_TEXT, node(id).className?.toString())
                assertTrue("$id editable", node(id).isEditable)
                assertEquals("$id name", expectedName, name(id))
                type(id, "abc")
                Log.i("F01", "TYPED " + describe(id))
                assertEquals("$id name after typing", expectedName, name(id))
            }
        }
    }

    // VAL-3: each bad example is asserted to have its named defect.

    @Test
    fun badPlaceholderFieldsLoseTheirNameWhenFilled() {
        for ((slug, id) in listOf(
            "bad-placeholder-only" to "f01-bad-placeholder-only-email",
            "bad-cupertino-placeholder" to "f01-bad-cupertino-placeholder-email")) {
            open(slug)
            Log.i("F01", "EMPTY " + describe(id))
            assertEquals("$id name while empty", "Email", name(id))
            type(id, "abc")
            Log.i("F01", "TYPED " + describe(id))
            assertEquals("$id name after typing", "", name(id))
        }
    }

    @Test
    fun badFieldsWithNoNameHaveNoName() {
        for ((slug, id) in listOf(
            "bad-unassociated-label" to "f01-bad-unassociated-label-email",
            "bad-no-label" to "f01-bad-no-label-search",
            "bad-cupertino-prefix" to "f01-bad-cupertino-prefix-email")) {
            open(slug)
            Log.i("F01", "EMPTY " + describe(id))
            assertEquals("$id class", EDIT_TEXT, node(id).className?.toString())
            assertEquals("$id name", "", name(id))
        }
    }

    @Test
    fun badNameMismatchLacksTheVisibleLabel() {
        open("bad-name-mismatch")
        assertEquals("Contact address", name("f01-bad-name-mismatch-email"))
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
     * L4. Moves TalkBack focus to each field and logs markers;
     * tool/talkback.py reads the speech from logcat. The placeholder fields
     * are also read after text has been entered. Skipped unless TalkBack is
     * running.
     */
    @Test
    fun talkBackWalk() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
        // slug -> field ids; an id listed with true is read again once filled.
        val walk = listOf(
            "good-label" to listOf("f01-good-label-email" to true, "f01-good-label-message" to false),
            "good-label-above" to listOf("f01-good-label-above-name" to false),
            "good-cupertino" to listOf("f01-good-cupertino-email" to false),
            "bad-placeholder-only" to listOf("f01-bad-placeholder-only-email" to true),
            "bad-unassociated-label" to listOf("f01-bad-unassociated-label-email" to false),
            "bad-no-label" to listOf("f01-bad-no-label-search" to false),
            "bad-name-mismatch" to listOf("f01-bad-name-mismatch-email" to false),
            "bad-cupertino-placeholder" to listOf("f01-bad-cupertino-placeholder-email" to true),
            "bad-cupertino-prefix" to listOf("f01-bad-cupertino-prefix-email" to false),
        )
        for ((slug, fields) in walk) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for ((id, alsoFilled) in fields) {
                Log.i("F01TB", "FOCUS $id")
                talkBackFocus(id) { node(id) }
                Thread.sleep(4_500)
                if (alsoFilled) {
                    // Move focus away, fill the field, and read it again.
                    Log.i("F01TB", "END $slug")
                    type(id, "abc")
                    if (slug == "good-label") {
                        // Put the text cursor in the other field, so the
                        // filled one is read while it is not being edited.
                        node("f01-good-label-message").performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        Thread.sleep(1_500)
                    }
                    // Typing leaves TalkBack on the field, and focusing a node
                    // that already has focus says nothing. Move away first.
                    talkBackFocus("the Example heading") {
                        findByText(automation.rootInActiveWindow, "Example")
                            ?: throw AssertionError("no Example heading")
                    }
                    Thread.sleep(4_000)
                    Log.i("F01TB", "FOCUS $id-filled")
                    talkBackFocus("$id (filled)") { node(id) }
                    Thread.sleep(4_500)
                }
            }
            Log.i("F01TB", "END $slug")
        }
    }
}
