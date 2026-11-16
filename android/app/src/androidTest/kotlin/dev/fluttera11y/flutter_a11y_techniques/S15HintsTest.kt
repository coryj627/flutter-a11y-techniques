// L3 (tree) and L4 (TalkBack walk) for S15 Hints on Android.
// Spec: docs/specs/S15-hints.md.
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
private const val RULE = "3 to 12 letters or numbers."
private const val SONG = "Night Ferry\nThe Lanterns"

@RunWith(AndroidJUnit4::class)
class S15HintsTest {
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
            .putExtra("route", "/t/S15/$slug")
        inst.targetContext.startActivity(intent)
        assertTrue("example $slug did not open",
            device.wait(Until.hasObject(By.res("s15-$slug-count")), 20_000))
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

    private fun count(slug: String): Int = node("s15-$slug-count").name().substringAfter(": ").toInt()

    private fun waitForCount(slug: String, expected: Int) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && count(slug) != expected) Thread.sleep(100)
        assertEquals("activation count for $slug", expected, count(slug))
    }


    // Android has no hint of its own for a control. Flutter's bridge writes
    // "label, hint" into the content description (FL-039), so that is what
    // each button is expected to have.
    // slug -> (identifier, name, hint)
    private val buttons = listOf(
        Triple("good-result", "s15-good-result-favorite", "Favorite" to "Adds this item to your favorites."),
        Triple("good-row", "s15-good-row-song", SONG to "Plays the song."),
        Triple("good-cupertino", "s15-good-cupertino-share", "Share" to "Shares the current page."),
        Triple("good-custom", "s15-good-custom-archive", "Archive" to "Moves this message out of the inbox."),
        Triple("bad-gesture", "s15-bad-gesture-favorite",
            "Favorite" to "Double tap to add this item to your favorites."),
        Triple("bad-repeats-label", "s15-bad-repeats-label-delete", "Delete" to "Delete"),
        Triple("bad-control-type", "s15-bad-control-type-share",
            "Share" to "This button shares the current page."),
        Triple("bad-no-hint", "s15-bad-no-hint-song", SONG to ""),
    )

    @Test
    fun buttonsHaveTheirNameAndHintInTheDescription() {
        for ((slug, id, text) in buttons) {
            open(slug)
            val (name, hint) = text
            val node = node(id)
            assertEquals(slug, BUTTON, node.type())
            assertEquals(slug, if (hint.isEmpty()) name else "$name, $hint", node.name())
            // Nothing is in a field of its own: no hint text, no tooltip,
            // no state description.
            assertTrue(slug, node.hintText.isNullOrEmpty())
            assertTrue(slug, node.tooltipText.isNullOrEmpty())
            assertTrue(slug, node.stateDescription.isNullOrEmpty())
            assertEquals(slug, 1, buttons().size)
            assertTrue(slug, node.isClickable)
            assertTrue(slug, node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount(slug, 1)
            assertEquals(slug, if (hint.isEmpty()) name else "$name, $hint", node(id).name())
        }
    }

    @Test
    fun goodFieldHasTheRuleInItsHintTextAndOnTheScreen() {
        open("good-field")
        val field = node("s15-good-field-username")
        assertEquals(EDIT_TEXT, field.type())
        // A text field is the one control with a hint on Android: label and
        // hint go into the node's hint text.
        assertEquals("Username, $RULE", field.hintText?.toString())
        assertTrue(field.name().isEmpty())
        val rule = all().filter { it.name() == RULE }
        assertEquals(1, rule.size)
        assertEquals(VIEW, rule.single().type())
    }

    /** The text in a field; an empty EditText reports its hint as its text. */
    private fun value(id: String): String = node(id).let {
        if (it.isShowingHintText) "" else it.text?.toString().orEmpty()
    }

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

    @Test
    fun aFilledFieldHasTheRuleInHintTextOnly() {
        // Label and hint are only ever in the node's hint text. TalkBack
        // reads hint text for an empty field and stops once the field has a
        // value (FL-015); the walk records that.
        open("good-field")
        val id = "s15-good-field-username"
        assertEquals("", value(id))
        type(id, "abc")
        val field = node(id)
        assertEquals("abc", field.text?.toString())
        assertEquals("Username, $RULE", field.hintText?.toString())
        assertTrue(field.name().isEmpty())
        // The rule on the screen is still an element of its own.
        assertEquals(1, all().count { it.name() == RULE })
    }

    @Test
    fun badHintDetachedHasTheHintOnANodeOfItsOwn() {
        open("bad-hint-detached")
        val button = buttons().single()
        // Flutter 3.47.5: the hint does not join the Material button
        // (FL-040). Written to fail if it starts to.
        assertEquals("Favorite", button.name())
        val hint = all().filter { it.name() == "Adds this item to your favorites." }
        assertEquals(1, hint.size)
        assertEquals(VIEW, hint.single().type())
        assertFalse(hint.single().isClickable)
        assertFalse(hint.single().hasClickAction())
        assertTrue(button.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("bad-hint-detached", 1)
    }

    @Test
    fun badHintOnlyHasTheRuleInTheHintTextAndNowhereElse() {
        open("bad-hint-only")
        val field = node("s15-bad-hint-only-username")
        assertEquals("Username, $RULE", field.hintText?.toString())
        assertEquals(0, all().count { it.name().contains("3 to 12") })
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
                "good-field" to listOf(
                    byId("s15-good-field-username"),
                    "s15-good-field-rule" to { all().single { it.name() == RULE } }),
                // No identifiers here: the two nodes are found by what they say.
                "bad-hint-detached" to listOf(
                    "s15-bad-hint-detached-hint" to
                        { all().single { it.name() == "Adds this item to your favorites." } },
                    "s15-bad-hint-detached-favorite" to { buttons().single() }),
                "bad-hint-only" to listOf(byId("s15-bad-hint-only-username")),
            )
        // The fields are read a second time with text in them (FL-015).
        val filled = mapOf(
            "good-field" to "s15-good-field-username",
            "bad-hint-only" to "s15-bad-hint-only-username")
        for ((slug, elements) in walk) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for ((marker, find) in elements) {
                Log.i("S15TB", "FOCUS $marker")
                talkBackFocus(marker, find)
                Thread.sleep(6_000)
            }
            val field = filled[slug]
            if (field != null) {
                // Move focus away, fill the field, and read it again.
                Log.i("S15TB", "END $slug")
                type(field, "abc")
                // Put the keyboard away: with it up, TalkBack said nothing,
                // or only "Editing", when its focus came back to the field.
                device.pressBack()
                // TalkBack says "keyboard hidden"; let it finish.
                Thread.sleep(5_000)
                // Typing leaves TalkBack on the field, and focusing a node
                // that already has focus says nothing. Move away first.
                talkBackFocus("the Example heading") { all().first { it.name() == "Example" } }
                Thread.sleep(4_000)
                Log.i("S15TB", "FOCUS $field-filled")
                talkBackFocus("$field (filled)") { node(field) }
                Thread.sleep(6_000)
            }
            Log.i("S15TB", "END $slug")
        }
    }
}
