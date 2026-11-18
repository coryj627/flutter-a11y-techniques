// L3 (tree, keyboard, and autofill) and L4 (TalkBack walk) for F03 Keyboard
// types on Android. Spec: docs/specs/F03-keyboard-types.md.
//
// Which keyboard a field gets is not in the accessibility tree. It is read
// in three places here:
//
// - what the app asked the input method for: the focused editor's
//   EditorInfo (input type and IME options) in `dumpsys input_method`, run
//   through UiAutomation;
// - what the keyboard then shows: the labels of the keys in the input
//   method's own window, which Gboard exposes to accessibility (checked
//   only where the keyboard is Gboard, as on the emulator the evidence
//   runs use);
// - what the autofill framework is told: this test runs in the app's
//   process, so it asks the FlutterView for its autofill structure with a
//   ViewStructure that records the calls, as an autofill service would get
//   them (AutofillRecorder below).
package dev.fluttera11y.flutter_a11y_techniques

import android.graphics.Matrix
import android.os.Bundle
import android.os.LocaleList
import android.os.ParcelFileDescriptor
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.view.ViewStructure
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.runner.lifecycle.ActivityLifecycleMonitorRegistry
import androidx.test.runner.lifecycle.Stage
import androidx.test.uiautomator.By
import io.flutter.embedding.android.FlutterView
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val EDIT_TEXT = "android.widget.EditText"

// android.view.inputmethod.EditorInfo.IME_ACTION_*: the low byte of imeOptions.
private const val IME_ACTION_NEXT = 5
private const val IME_ACTION_DONE = 6

/**
 * One field's autofill entry as the autofill framework receives it: its
 * hints, and whether it is the field being edited (the only one that is
 * given its real size; the others are 1 by 1).
 */
internal data class AutofillEntry(val hints: List<String>, val current: Boolean)

/**
 * A ViewStructure that records what Flutter's text input plugin gives the
 * autofill framework (`TextInputPlugin.onProvideAutofillVirtualStructure`).
 * Only the calls that plugin makes are recorded; the rest do nothing.
 */
internal class AutofillRecorder(private val parentId: AutofillId?) : ViewStructure() {
    val children = mutableListOf<AutofillRecorder>()
    var hints: List<String> = emptyList()
    var width = 0
    var height = 0

    fun entries(): List<AutofillEntry> =
        children.map { AutofillEntry(it.hints, !(it.width == 1 && it.height == 1)) }

    override fun addChildCount(num: Int): Int = children.size
    override fun asyncCommit() {}
    override fun asyncNewChild(index: Int): ViewStructure = newChild(index)
    override fun getAutofillId(): AutofillId? = parentId
    override fun getChildCount(): Int = children.size
    override fun getExtras(): Bundle = Bundle()
    override fun getHint(): CharSequence? = null
    override fun getText(): CharSequence? = null
    override fun getTextSelectionEnd(): Int = 0
    override fun getTextSelectionStart(): Int = 0
    override fun hasExtras(): Boolean = false
    override fun newChild(index: Int): ViewStructure = AutofillRecorder(null).also { children.add(it) }
    override fun newHtmlInfoBuilder(tagName: String): HtmlInfo.Builder? = null
    override fun setAccessibilityFocused(state: Boolean) {}
    override fun setActivated(state: Boolean) {}
    override fun setAlpha(alpha: Float) {}
    override fun setAutofillHints(hints: Array<out String>?) { this.hints = hints?.toList().orEmpty() }
    override fun setAutofillId(id: AutofillId) {}
    override fun setAutofillId(parentId: AutofillId, virtualId: Int) {}
    override fun setAutofillOptions(options: Array<out CharSequence>?) {}
    override fun setAutofillType(type: Int) {}
    override fun setAutofillValue(value: AutofillValue?) {}
    override fun setCheckable(state: Boolean) {}
    override fun setChecked(state: Boolean) {}
    override fun setChildCount(num: Int) {}
    override fun setClassName(className: String?) {}
    override fun setClickable(state: Boolean) {}
    override fun setContentDescription(contentDescription: CharSequence?) {}
    override fun setContextClickable(state: Boolean) {}
    override fun setDataIsSensitive(sensitive: Boolean) {}
    override fun setDimens(left: Int, top: Int, scrollX: Int, scrollY: Int, width: Int, height: Int) {
        this.width = width
        this.height = height
    }
    override fun setElevation(elevation: Float) {}
    override fun setEnabled(state: Boolean) {}
    override fun setFocusable(state: Boolean) {}
    override fun setFocused(state: Boolean) {}
    override fun setHint(hint: CharSequence?) {}
    override fun setHtmlInfo(htmlInfo: HtmlInfo) {}
    override fun setId(id: Int, packageName: String?, typeName: String?, entryName: String?) {}
    override fun setInputType(inputType: Int) {}
    override fun setLocaleList(localeList: LocaleList?) {}
    override fun setLongClickable(state: Boolean) {}
    override fun setOpaque(opaque: Boolean) {}
    override fun setSelected(state: Boolean) {}
    override fun setText(text: CharSequence?) {}
    override fun setText(text: CharSequence?, selectionStart: Int, selectionEnd: Int) {}
    override fun setTextLines(charOffsets: IntArray?, baselines: IntArray?) {}
    override fun setTextStyle(size: Float, fgColor: Int, bgColor: Int, style: Int) {}
    override fun setTransformation(matrix: Matrix?) {}
    override fun setVisibility(visibility: Int) {}
    override fun setWebDomain(domain: String?) {}
}

/**
 * What a field must ask the keyboard and the autofill framework for.
 * [inputType] is the whole EditorInfo input type; [action] the IME action;
 * [keys] key labels the keyboard must show and [noKeys] labels it must not;
 * [autofill] the hints of the field being edited.
 */
private data class Expected(
    val slug: String,
    val id: String,
    val name: String,
    val inputType: Int,
    val action: Int,
    val keys: List<String>,
    val noKeys: List<String>,
    val autofill: List<String>,
    val password: Boolean = false,
)

// android.text.InputType values, written out so that a failure shows the
// number the engine sent.
private const val TEXT = 0x1
private const val NUMBER = 0x2
private const val PHONE = 0x3
private const val NUMBER_DECIMAL = 0x2000
private const val EMAIL = 0x20
private const val PERSON_NAME = 0x60
private const val PASSWORD = 0x80
private const val FILTER = 0xb0
private const val CAP_WORDS = 0x2000
private const val AUTO_CORRECT = 0x8000
private const val NO_SUGGESTIONS = 0x80000

private val EXPECTED = listOf(
    // A name: the name variation, capital letters, the letter keyboard.
    Expected("good-contact", "f03-good-contact-name", "Name",
        TEXT or PERSON_NAME or CAP_WORDS or AUTO_CORRECT, IME_ACTION_NEXT,
        keys = listOf("q", "Next"), noKeys = listOf("@"), autofill = listOf("personName")),
    // An email address: "@" on the first page.
    Expected("good-contact", "f03-good-contact-email", "Email", TEXT or EMAIL, IME_ACTION_NEXT,
        keys = listOf("@", "Next"), noKeys = emptyList(), autofill = listOf("emailAddress")),
    // A phone number: the dial pad, with letters printed under the digits.
    Expected("good-contact", "f03-good-contact-phone", "Phone", PHONE, IME_ACTION_DONE,
        keys = listOf("1", "WXYZ", "Done"), noKeys = listOf("q"), autofill = listOf("phoneNumber")),
    Expected("good-amount", "f03-good-amount-amount", "Amount", NUMBER or NUMBER_DECIMAL, IME_ACTION_DONE,
        keys = listOf("1", "Period", "Done"), noKeys = listOf("q"), autofill = emptyList()),
    Expected("good-cupertino", "f03-good-cupertino-email", "Email", TEXT or EMAIL, IME_ACTION_NEXT,
        keys = listOf("@", "Next"), noKeys = emptyList(), autofill = listOf("emailAddress")),
    Expected("good-cupertino", "f03-good-cupertino-phone", "Phone", PHONE, IME_ACTION_DONE,
        keys = listOf("1", "WXYZ", "Done"), noKeys = listOf("q"), autofill = listOf("phoneNumber")),
    Expected("good-sign-in", "f03-good-sign-in-username", "Username", TEXT, IME_ACTION_NEXT,
        keys = listOf("q", "Next"), noKeys = emptyList(), autofill = listOf("username")),
    Expected("good-sign-in", "f03-good-sign-in-password", "Password",
        TEXT or PASSWORD or NO_SUGGESTIONS, IME_ACTION_DONE,
        keys = listOf("q", "Done"), noKeys = emptyList(), autofill = listOf("password"), password = true),
    // Bad examples: the defect must be visible in what was asked for and
    // in the keys shown.
    Expected("bad-number-for-name", "f03-bad-number-for-name-name", "Name", NUMBER, IME_ACTION_DONE,
        keys = listOf("1", "Done"), noKeys = listOf("q", "ABC"), autofill = listOf("personName")),
    Expected("bad-default-keyboard", "f03-bad-default-keyboard-email", "Email", TEXT, IME_ACTION_DONE,
        keys = listOf("q"), noKeys = listOf("@"), autofill = listOf("emailAddress")),
    Expected("bad-no-purpose", "f03-bad-no-purpose-name", "Name",
        TEXT or PERSON_NAME or CAP_WORDS or AUTO_CORRECT, IME_ACTION_DONE,
        keys = listOf("q"), noKeys = emptyList(), autofill = emptyList()),
    // FL-160: the email variation and the "no suggestions" flags are joined
    // with a bitwise or, which makes the filter variation: no "@" key.
    // Written to fail when the engine keeps the email variation.
    Expected("bad-email-no-suggestions", "f03-bad-email-no-suggestions-email", "Email",
        TEXT or FILTER or NO_SUGGESTIONS, IME_ACTION_DONE,
        keys = listOf("q"), noKeys = listOf("@"), autofill = listOf("emailAddress")),
)

@RunWith(AndroidJUnit4::class)
class F03KeyboardTypesTest : TechniqueTest("F03") {
    override val countName: String get() = "change count"

    private fun open(slug: String) = openExample(slug, By.res("f03-$slug-count"))

    private fun shell(command: String): String =
        ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command))
            .bufferedReader().readText()

    /**
     * The input type and IME options of the editor the input method is
     * serving for this app, from `dumpsys input_method`, or null if it is
     * serving none. The dump prints an EditorInfo as an "inputType=…
     * imeOptions=…" line followed, a few lines on, by its package name.
     */
    private fun editorInfo(): Pair<Int, Int>? {
        val lines = shell("dumpsys input_method").lines().map { it.trim() }
        val pattern = Regex("""^inputType=0x([0-9a-f]+) imeOptions=0x([0-9a-f]+) privateImeOptions=""")
        for ((i, line) in lines.withIndex()) {
            val match = pattern.find(line) ?: continue
            val ours = (i + 1..minOf(i + 6, lines.size - 1)).any {
                lines[it].startsWith("packageName=${inst.targetContext.packageName} ")
            }
            if (!ours) continue
            return match.groupValues[1].toInt(16) to match.groupValues[2].toInt(16)
        }
        return null
    }

    /**
     * Whether the keyboard is Gboard, whose keys are in the accessibility
     * tree and are checked by label. Another keyboard, such as the AOSP one
     * on a CI image, may expose its keys only while a screen reader runs,
     * or not show at all with a hardware keyboard configured; there only
     * what the field asked for is checked.
     */
    private val gboard: Boolean by lazy {
        shell("settings get secure default_input_method").trim()
            .startsWith("com.google.android.inputmethod.latin/")
    }

    private fun keyboardWindow(): AccessibilityWindowInfo? =
        automation.windows.firstOrNull { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD }

    /** The labels of the keys the on-screen keyboard shows; empty if it is down. */
    private fun keyLabels(): Set<String> {
        val labels = mutableSetOf<String>()
        fun walk(n: AccessibilityNodeInfo?) {
            if (n == null) return
            (n.contentDescription ?: n.text)?.toString()?.let { if (it.isNotEmpty()) labels.add(it) }
            for (i in 0 until n.childCount) walk(n.getChild(i))
        }
        walk(keyboardWindow()?.root)
        return labels
    }

    private fun flutterView(): FlutterView {
        var found: FlutterView? = null
        inst.runOnMainSync {
            val activity = ActivityLifecycleMonitorRegistry.getInstance().getActivitiesInStage(Stage.RESUMED).first()
            fun find(v: View) {
                if (v is FlutterView) found = v
                if (v is ViewGroup) for (i in 0 until v.childCount) find(v.getChildAt(i))
            }
            find(activity.window.decorView)
        }
        return found ?: throw AssertionError("no FlutterView")
    }

    /** What the autofill framework is given now, one entry per field. */
    private fun autofill(): List<AutofillEntry> {
        val view = flutterView()
        val root = AutofillRecorder(view.autofillId)
        inst.runOnMainSync { view.onProvideAutofillVirtualStructure(root, 0) }
        return root.entries()
    }

    /**
     * Puts the keyboard away if it is up. Back with no keyboard up would
     * leave the app, so it is pressed only while the keyboard's window is
     * there.
     */
    private fun closeKeyboard() {
        if (keyboardWindow() == null) return
        device.pressBack()
        val end = System.currentTimeMillis() + 5_000
        while (keyboardWindow() != null && System.currentTimeMillis() < end) Thread.sleep(200)
        assertTrue("the keyboard went away", keyboardWindow() == null)
    }

    /**
     * Clicks the field and waits for the input method to serve an editor
     * with [inputType] and for the keyboard to show [keys]; returns what it
     * served. Waiting for the expected values is what makes this robust to
     * the keyboard coming up late; a wrong value fails after the wait.
     */
    private fun startEditing(e: Expected): Triple<Pair<Int, Int>?, Set<String>, List<AutofillEntry>> {
        assertTrue("${e.id} click", node(e.id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        val end = System.currentTimeMillis() + 8_000
        var info = editorInfo()
        var keys = keyLabels()
        while (System.currentTimeMillis() < end &&
            (info?.first != e.inputType || (gboard && !keys.containsAll(e.keys)) || !node(e.id).isFocused)) {
            Thread.sleep(250)
            info = editorInfo()
            keys = keyLabels()
        }
        val fill = autofill()
        Log.i("F03", "EDITING ${e.id} inputType=0x${Integer.toHexString(info?.first ?: -1)} " +
            "imeOptions=0x${Integer.toHexString(info?.second ?: -1)} autofill=$fill keys=${keys.sorted()}")
        return Triple(info, keys, fill)
    }

    @Test
    fun fieldsAskForTheirKeyboardAndPurpose() {
        for ((slug, fields) in EXPECTED.groupBy { it.slug }) {
            open(slug)
            for (e in fields) {
                val field = node(e.id)
                assertEquals(e.id, EDIT_TEXT, field.type())
                assertTrue(e.id, field.isEditable)
                // Flutter puts a field's label in its hint text (FL-015).
                assertEquals(e.id, e.name, field.hintText?.toString())
                assertEquals("${e.id} password", e.password, field.isPassword)
                val (info, keys, fill) = startEditing(e)
                assertTrue("${e.id} focused", node(e.id).isFocused)
                assertEquals("${e.id} input type", "0x" + Integer.toHexString(e.inputType),
                    "0x" + Integer.toHexString(info?.first ?: -1))
                assertEquals("${e.id} IME action", e.action, (info?.second ?: 0) and 0xff)
                if (gboard) {
                    for (key in e.keys) assertTrue("${e.id}: key \"$key\" in $keys", key in keys)
                    for (key in e.noKeys) assertFalse("${e.id}: no key \"$key\" in $keys", key in keys)
                } else {
                    Log.i("F03", "not Gboard: the keys of ${e.id} are not checked")
                }
                val current = fill.filter { it.current }
                assertEquals("${e.id} autofill entries $fill", 1, current.size)
                assertEquals("${e.id} autofill hints", e.autofill, current.single().hints)
                // Nothing else is read with the keyboard up: put it away.
                closeKeyboard()
                assertEquals("${e.id} password after editing", e.password, node(e.id).isPassword)
            }
        }
    }

    @Test
    fun signInFieldsAreOneAutofillGroup() {
        open("good-sign-in")
        val (_, _, fill) = startEditing(EXPECTED.first { it.id == "f03-good-sign-in-password" })
        // Both fields are offered to the autofill framework together, the
        // password as the one being edited.
        assertEquals(fill.toString(), 2, fill.size)
        assertEquals(listOf("username"), fill.single { !it.current }.hints)
        assertEquals(listOf("password"), fill.single { it.current }.hints)
        closeKeyboard()
    }

    @Test
    fun passwordIsObscuredInTheTree() {
        open("good-sign-in")
        val id = "f03-good-sign-in-password"
        assertTrue(node(id).isPassword)
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        Thread.sleep(1_000)
        inst.sendStringSync("abc")
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && node(id).text?.toString() != "•••") Thread.sleep(100)
        // The text is three bullets, not what was typed, while editing and
        // after the keyboard is put away.
        assertEquals("•••", node(id).text?.toString())
        assertTrue(node(id).isPassword)
        closeKeyboard()
        assertEquals("•••", node(id).text?.toString())
        assertTrue(node(id).isPassword)
        waitForCount("good-sign-in", 3)
    }

    /**
     * L4. Moves TalkBack focus to every field and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless
     * TalkBack is running. No field is typed into except the password, the
     * last stop of the walk: F02's walk went wrong after a second field had
     * been typed into, and the keyboard types are not heard anyway.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        val walk = listOf(
            "good-contact" to listOf("f03-good-contact-name", "f03-good-contact-email", "f03-good-contact-phone"),
            "good-amount" to listOf("f03-good-amount-amount"),
            "good-cupertino" to listOf("f03-good-cupertino-email", "f03-good-cupertino-phone"),
            "bad-number-for-name" to listOf("f03-bad-number-for-name-name"),
            "bad-default-keyboard" to listOf("f03-bad-default-keyboard-email"),
            "bad-no-purpose" to listOf("f03-bad-no-purpose-name"),
            "bad-email-no-suggestions" to listOf("f03-bad-email-no-suggestions-email"),
            "good-sign-in" to listOf("f03-good-sign-in-username", "f03-good-sign-in-password"),
        )
        for ((slug, ids) in walk) {
            // With TalkBack on, the keyboard or a system window can be the
            // active window while the example opens behind it.
            openExampleInAnyWindow(slug) { it.viewIdResourceName == "f03-$slug-count" }
            Thread.sleep(8_000)
            for (id in ids) {
                Log.i(talkBackTag, "FOCUS $id")
                talkBackFocus(id) { nodeInAnyWindow(id) }
                Thread.sleep(5_000)
            }
            if (slug == "good-sign-in") {
                // The password, read again with "abc" typed into it.
                Log.i(talkBackTag, "END $slug")
                val id = "f03-good-sign-in-password"
                assertTrue(nodeInAnyWindow(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
                Thread.sleep(1_500)
                inst.sendStringSync("abc")
                Thread.sleep(1_500)
                // Put the keyboard away: with it up, TalkBack said nothing,
                // or only "Editing", when its focus came back to a field (S15).
                closeKeyboard()
                Thread.sleep(3_000)
                talkBackFocus("the Example heading") { all().first { it.name() == "Example" } }
                Thread.sleep(4_000)
                Log.i(talkBackTag, "FOCUS $id-filled")
                talkBackFocus("$id (filled)") { nodeInAnyWindow(id) }
                Thread.sleep(5_000)
            }
            Log.i(talkBackTag, "END $slug")
        }
    }
}
