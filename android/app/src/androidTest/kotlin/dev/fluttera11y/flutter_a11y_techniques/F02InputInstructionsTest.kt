// L3 (tree) and L4 (TalkBack walk) for F02 Input instructions on Android.
// Spec: docs/specs/F02-input-instructions.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Until
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val EDIT_TEXT = "android.widget.EditText"
private const val USERNAME = "Username"
private const val RULE = "4 to 10 characters, no spaces."
private const val DISPLAY_RULE = "Shown on your posts. 2 to 30 letters or numbers."

@RunWith(AndroidJUnit4::class)
class F02InputInstructionsTest : TechniqueTest("F02") {
    private fun open(slug: String) = openExample(slug, By.res("f02-$slug-count"))

    override val countName: String get() = "change count"

    /** The nodes that read [text] as their name: the instruction as text. */
    private fun withName(text: String) = all().filter { it.name() == text }

    private fun hint(id: String): String = node(id).hintText?.toString().orEmpty()

    private fun keyboardUp(): Boolean =
        automation.windows.any { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD }

    /**
     * Puts the soft keyboard away if it is up, then waits up to 5 seconds
     * for the example's count to be in the tree again. CI's emulator is 320
     * by 640 at 160 dpi with no hardware keyboard: there the soft keyboard
     * came up after typing and the count of `bad-helper-only` was then
     * missing from the tree (run 44261623828). A widget test at that size,
     * with a keyboard-sized inset at the bottom, showed the count of the
     * bad examples, below their longer description, scrolled out of view and
     * marked hidden; that this is what happened on CI is likely, not shown.
     * Back is pressed only while the keyboard is up, so it never leaves the
     * example.
     */
    private fun closeKeyboard(slug: String) {
        if (keyboardUp()) {
            device.pressBack()
            val end = System.currentTimeMillis() + 3_000
            while (System.currentTimeMillis() < end && keyboardUp()) Thread.sleep(100)
        }
        assertTrue("the count of $slug is in the tree",
            device.wait(Until.hasObject(By.res("f02-$slug-count")), 5_000))
    }

    // Android has no description for a field. Flutter's bridge writes the
    // label and the hint into the node's hint text, "label, hint"
    // (FL-039, FL-015), so that is where the instruction is looked for.
    // slug, identifier, hint text, instruction on the screen.
    private val fields = listOf(
        listOf("good-helper", "f02-good-helper-username", "$USERNAME, $RULE", RULE),
        listOf("good-cupertino", "f02-good-cupertino-username", "$USERNAME, $RULE", RULE),
        listOf("good-before", "f02-good-before-username", "$USERNAME, $RULE", RULE),
        listOf("bad-helper-only", "f02-bad-helper-only-username", USERNAME, RULE),
        listOf("bad-helper-cut-off", "f02-bad-helper-cut-off-name", "Display name, $DISPLAY_RULE", DISPLAY_RULE),
    )

    @Test
    fun fieldsHaveTheirLabelAndInstructionInTheHintTextBeforeAndAfterTyping() {
        for ((slug, id, hintText, rule) in fields) {
            open(slug)
            val field = node(id)
            assertEquals(slug, EDIT_TEXT, field.type())
            assertTrue(slug, field.isEditable)
            assertEquals(slug, hintText, hint(id))
            assertTrue(slug, field.name().isEmpty())
            // The instruction on the screen is an element of its own, and
            // the only node that reads it as its name.
            assertEquals(slug, 1, withName(rule).size)
            assertFalse(slug, withName(rule).single().isClickable)
            type(id, "abc")
            closeKeyboard(slug)
            assertEquals(slug, "abc", node(id).text?.toString())
            // Still only in the hint text, which TalkBack does not read for
            // a field with a value (FL-015); the walk records that.
            assertEquals(slug, hintText, hint(id))
            assertEquals(slug, 1, withName(rule).size)
            waitForCount(slug, 3)
        }
    }

    @Test
    fun goodBeforeHasTheInstructionAboveTheField() {
        open("good-before")
        val ruleTop = android.graphics.Rect().also { withName(RULE).single().getBoundsInScreen(it) }
        val fieldTop = android.graphics.Rect().also { node("f02-good-before-username").getBoundsInScreen(it) }
        assertTrue("$ruleTop above $fieldTop", ruleTop.bottom <= fieldTop.top)
    }

    @Test
    fun badPlaceholderFormatIsInTheHintTextOnlyWhileEditingAnEmptyField() {
        open("bad-placeholder-format")
        val id = "f02-bad-placeholder-format-birthday"
        assertEquals("Date of birth", hint(id))
        assertEquals(0, all().count { "DD/MM" in it.name() || "DD/MM" in it.text?.toString().orEmpty() })
        // Editing and empty: the placeholder joins the label in the hint text.
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && hint(id) == "Date of birth") Thread.sleep(100)
        assertEquals("Date of birth\nDD/MM/YYYY", hint(id))
        // One character in, and it is gone.
        type(id, "1")
        closeKeyboard("bad-placeholder-format")
        assertEquals("Date of birth", hint(id))
        waitForCount("bad-placeholder-format", 1)
    }

    /**
     * L4. Moves TalkBack focus to the field and to the instruction of every
     * example, and logs markers; tool/talkback.py reads the speech from
     * logcat. Skipped unless TalkBack is running. Not
     * TechniqueTest.talkBackWalk: one field is read a second time once
     * filled, as in S15HintsTest.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        val byId = { id: String -> id to { nodeInAnyWindow(id) } }
        val rule = { marker: String, text: String -> marker to { withName(text).single() } }
        // The one example that is typed into comes last. On two of the
        // first three runs the example after the second field that had been
        // typed into went wrong: it did not open in the active window, or
        // TalkBack said nothing on it and on every element after it. So
        // only good-helper is read filled, at the end: what TalkBack drops
        // once a field has a value is the same for every field here
        // (the hint text, FL-015).
        val walk: List<Pair<String, List<Pair<String, () -> AccessibilityNodeInfo>>>> = listOf(
            "good-cupertino" to listOf(byId("f02-good-cupertino-username"), rule("f02-good-cupertino-rule", RULE)),
            // The instruction comes first here.
            "good-before" to listOf(rule("f02-good-before-rule", RULE), byId("f02-good-before-username")),
            "bad-helper-only" to listOf(byId("f02-bad-helper-only-username"), rule("f02-bad-helper-only-rule", RULE)),
            "bad-placeholder-format" to listOf(byId("f02-bad-placeholder-format-birthday")),
            "bad-helper-cut-off" to listOf(
                byId("f02-bad-helper-cut-off-name"), rule("f02-bad-helper-cut-off-rule", DISPLAY_RULE)),
            "good-helper" to listOf(byId("f02-good-helper-username"), rule("f02-good-helper-rule", RULE)),
        )
        // The field read a second time with text in it (FL-015).
        val filled = mapOf("good-helper" to "f02-good-helper-username")
        for ((slug, elements) in walk) {
            // With TalkBack on, the keyboard or a system window can be the
            // active window while the example opens behind it (seen on the
            // first run), so its count is looked for in every window.
            openExampleInAnyWindow(slug) { it.viewIdResourceName == "f02-$slug-count" }
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for ((marker, find) in elements) {
                Log.i(talkBackTag, "FOCUS $marker")
                talkBackFocus(marker, find)
                // Fixed waits, kept as in the other walks: the speech is read
                // from TalkBack's log afterwards, so each wait is the window
                // in which an element's speech is heard.
                Thread.sleep(6_000)
            }
            val field = filled[slug]
            if (field != null) {
                // Move focus away, fill the field, and read it again.
                Log.i(talkBackTag, "END $slug")
                type(field, "abc")
                // Put the keyboard away: with it up, TalkBack said nothing,
                // or only "Editing", when its focus came back to the field
                // (S15).
                closeKeyboard(slug)
                Thread.sleep(5_000)
                // Typing leaves TalkBack on the field, and focusing a node
                // that already has focus says nothing. Move away first.
                talkBackFocus("the Example heading") { all().first { it.name() == "Example" } }
                Thread.sleep(4_000)
                Log.i(talkBackTag, "FOCUS $field-filled")
                talkBackFocus("$field (filled)") { node(field) }
                Thread.sleep(6_000)
                // The field no longer gives the instruction; the helper text
                // is still an element of its own, and TalkBack reads it whole
                // when focus is put on it. Focus is moved by action: a swipe,
                // Alt or Meta with an arrow key, and `input swipe` from the
                // filled field did not move TalkBack focus on the emulator
                // (tried in F02 as in S03), so whether a swipe lands here is
                // not tested.
                Log.i(talkBackTag, "FOCUS f02-$slug-rule-filled")
                talkBackFocus("the rule of $slug (filled)") { withName(RULE).single() }
                Thread.sleep(6_000)
            }
            Log.i(talkBackTag, "END $slug")
        }
    }
}
