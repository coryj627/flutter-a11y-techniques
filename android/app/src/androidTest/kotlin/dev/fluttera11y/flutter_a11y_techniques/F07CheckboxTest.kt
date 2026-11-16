// L3 (tree) and L4 (TalkBack walk) for F07 Checkbox on Android.
// Spec: docs/specs/F07-checkbox.md.
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
private const val CHECK_BOX = "android.widget.CheckBox"
private const val UPDATES = "Email me product updates"
private const val EDIT_TEXT = "android.widget.EditText"
private const val VIEW = "android.view.View"

@RunWith(AndroidJUnit4::class)
class F07CheckboxTest {
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
            .putExtra("route", "/t/F07/$slug")
        inst.targetContext.startActivity(intent)
        assertTrue("example $slug did not open",
            device.wait(Until.hasObject(By.res("f07-$slug-count")), 20_000))
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

    private fun count(slug: String): Int = node("f07-$slug-count").name().substringAfter(": ").toInt()

    private fun waitForCount(slug: String, expected: Int) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && count(slug) != expected) Thread.sleep(100)
        assertEquals("activation count for $slug", expected, count(slug))
    }


    private fun named(name: String): AccessibilityNodeInfo =
        all().firstOrNull { it.name() == name } ?: throw AssertionError("no node named $name")

    private fun checkBoxes(): List<AccessibilityNodeInfo> = all().filter { it.type() == CHECK_BOX }

    /**
     * The checked state of a node: true, false, or partial. Android 16 (API
     * 36) added the third state, and the Flutter engine sets it there.
     */
    private fun AccessibilityNodeInfo.state(): Int = checked

    private fun waitForState(id: String, expected: Int) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && node(id).state() != expected) Thread.sleep(100)
        assertEquals("checked state of $id", expected, node(id).state())
    }

    private val on = AccessibilityNodeInfo.CHECKED_STATE_TRUE
    private val off = AccessibilityNodeInfo.CHECKED_STATE_FALSE
    private val partial = AccessibilityNodeInfo.CHECKED_STATE_PARTIAL

    // slug, identifier, name. Each starts not checked.
    private val boxes = listOf(
        Triple("good-tile", "f07-good-tile-updates", UPDATES),
        Triple("good-cupertino", "f07-good-cupertino-updates", UPDATES),
        Triple("good-custom", "f07-good-custom-updates", UPDATES),
        Triple("good-group", "f07-good-group-phone", "Phone"),
        Triple("good-group", "f07-good-group-post", "Post"),
        Triple("bad-group-unlabelled", "f07-bad-group-unlabelled-phone", "Phone"),
    )

    @Test
    fun checkBoxesHaveTheirNameRoleAndState() {
        for ((slug, id, name) in boxes) {
            open(slug)
            val node = node(id)
            assertEquals(id, CHECK_BOX, node.type())
            assertEquals(id, name, node.name())
            assertTrue(id, node.isCheckable)
            assertEquals(id, off, node.state())
            assertTrue(id, node.isEnabled)
            assertTrue(id, node.isClickable)
            assertTrue(id, node.stateDescription.isNullOrEmpty())
            // The label is part of the checkbox, not a node of its own.
            assertEquals(id, 1, all().count { it.name() == name })
            assertTrue(id, node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForState(id, on)
            assertEquals(id, name, node(id).name())
            assertTrue(id, node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForState(id, off)
        }
    }

    @Test
    fun goodMixedIsPartiallyChecked() {
        assumeTrue("the partial state needs Android 16", android.os.Build.VERSION.SDK_INT >= 36)
        open("good-mixed")
        val all = "f07-good-mixed-all"
        assertEquals(CHECK_BOX, node(all).type())
        assertEquals("Select all", node(all).name())
        assertEquals(on, node("f07-good-mixed-email").state())
        assertEquals(off, node("f07-good-mixed-text").state())
        assertEquals(partial, node(all).state())
        // The old two-state property calls it not checked.
        @Suppress("DEPRECATION")
        assertFalse(node(all).isChecked)
        // From mixed, "Select all" checks both; from checked, it clears both.
        assertTrue(node(all).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForState(all, on)
        waitForState("f07-good-mixed-text", on)
        assertTrue(node(all).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForState(all, off)
        waitForState("f07-good-mixed-email", off)
        assertTrue(node("f07-good-mixed-email").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForState(all, partial)
    }

    @Test
    fun goodGroupHasTheQuestionOnANodeAroundTheCheckBoxes() {
        open("good-group")
        val group = node("f07-good-group-contact")
        assertEquals(VIEW, group.type())
        assertEquals("Contact me by", group.name())
        assertFalse(group.isClickable)
        assertEquals(group, node("f07-good-group-phone").parent)
        assertEquals(group, node("f07-good-group-post").parent)
        // The visible text is not a second node.
        assertEquals(1, all().count { it.name().contains("Contact me by") })
    }

    @Test
    fun badUnlabelledHasACheckBoxWithNoName() {
        open("bad-unlabelled")
        val box = checkBoxes().single()
        assertEquals("", box.name())
        assertTrue(box.text.isNullOrEmpty())
        val text = named(UPDATES)
        assertEquals(VIEW, text.type())
        assertFalse(text.isCheckable)
        assertFalse(text.isClickable)
    }

    @Test
    fun badNoStateIsAButtonWithNoState() {
        open("bad-no-state")
        val id = "f07-bad-no-state-updates"
        assertEquals(0, checkBoxes().size)
        for (clicks in 1..2) {
            val node = node(id)
            assertEquals(BUTTON, node.type())
            assertEquals(UPDATES, node.name())
            assertFalse(node.isCheckable)
            assertTrue(node.stateDescription.isNullOrEmpty())
            assertFalse(node.isSelected)
            assertTrue(node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount("bad-no-state", clicks)
        }
    }

    @Test
    fun badMixedAsUncheckedIsNotCheckedWhileOneBoxIs() {
        open("bad-mixed-as-unchecked")
        assertEquals(on, node("f07-bad-mixed-as-unchecked-email").state())
        assertEquals(off, node("f07-bad-mixed-as-unchecked-text").state())
        assertEquals(off, node("f07-bad-mixed-as-unchecked-all").state())
    }

    @Test
    fun badGroupUnlabelledHasTheQuestionBesideTheCheckBoxes() {
        open("bad-group-unlabelled")
        val question = named("Contact me by")
        assertEquals(VIEW, question.type())
        assertEquals(0, question.childCount)
        assertEquals(question.parent, node("f07-bad-group-unlabelled-phone").parent)
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

    private class Stop(val marker: String, val before: () -> Unit = {}, val find: () -> AccessibilityNodeInfo)

    /**
     * L4. Moves TalkBack focus to each control of every example and logs
     * markers; tool/talkback.py reads the speech from logcat. To read the
     * state after a change, the control is changed and focused a second
     * time. Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
        fun byId(id: String) = Stop(id) { node(id) }
        // Focus is taken off the element before it is changed, so that what
        // is logged is what TalkBack reads on arriving, not a change notice.
        fun afterClick(id: String, slug: String, find: () -> AccessibilityNodeInfo = { node(id) }) =
            Stop("$id-changed", {
                node("f07-$slug-count").performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
                Thread.sleep(3_000)
                find().performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Thread.sleep(2_000)
            }, find)
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-tile" to listOf(
                byId("f07-good-tile-updates"), afterClick("f07-good-tile-updates", "good-tile")),
            "good-cupertino" to listOf(
                byId("f07-good-cupertino-updates"), afterClick("f07-good-cupertino-updates", "good-cupertino")),
            "good-custom" to listOf(
                byId("f07-good-custom-updates"), afterClick("f07-good-custom-updates", "good-custom")),
            // Mixed at first; after one click, checked.
            "good-mixed" to listOf(
                byId("f07-good-mixed-all"),
                byId("f07-good-mixed-email"),
                byId("f07-good-mixed-text"),
                afterClick("f07-good-mixed-all", "good-mixed")),
            "good-group" to listOf(
                byId("f07-good-group-contact"),
                byId("f07-good-group-phone"),
                byId("f07-good-group-post")),
            // No identifiers here: the two nodes are found by what they are.
            "bad-unlabelled" to listOf(
                Stop("f07-bad-unlabelled-box") { checkBoxes().single() },
                Stop("f07-bad-unlabelled-text") { named(UPDATES) }),
            "bad-no-state" to listOf(
                byId("f07-bad-no-state-updates"), afterClick("f07-bad-no-state-updates", "bad-no-state")),
            "bad-mixed-as-unchecked" to listOf(byId("f07-bad-mixed-as-unchecked-all")),
            "bad-group-unlabelled" to listOf(
                Stop("f07-bad-group-unlabelled-question") { named("Contact me by") },
                byId("f07-bad-group-unlabelled-phone")),
        )
        for ((slug, stops) in walk) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for (stop in stops) {
                stop.before()
                Log.i("F07TB", "FOCUS ${stop.marker}")
                talkBackFocus(stop.marker, stop.find)
                Thread.sleep(6_000)
            }
            Log.i("F07TB", "END $slug")
        }
    }
}
