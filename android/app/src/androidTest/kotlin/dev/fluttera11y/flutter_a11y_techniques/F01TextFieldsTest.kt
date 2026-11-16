// L3 (tree) and L4 (TalkBack walk) for F01 Text fields and labels on Android.
// Spec: docs/specs/F01-text-fields.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val EDIT_TEXT = "android.widget.EditText"

@RunWith(AndroidJUnit4::class)
class F01TextFieldsTest : TechniqueTest("F01") {
    // Waits for this example's own title.
    private fun open(slug: String) = openExample(slug, By.desc(titles.getValue(slug)))

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

    /**
     * What names the field for a screen reader: its content description or,
     * as Flutter exposes a field's label on Android, its hint text.
     */
    private fun name(id: String): String = node(id).let {
        it.contentDescription?.toString().orEmpty().ifEmpty { it.hintText?.toString().orEmpty() }
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
     * L4. Moves TalkBack focus to each field and logs markers;
     * tool/talkback.py reads the speech from logcat. The placeholder fields
     * are also read after text has been entered. Skipped unless TalkBack is
     * running. Not TechniqueTest.talkBackWalk, because of that second read.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
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
                    talkBackFocus("the Example heading") { named("Example") }
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
