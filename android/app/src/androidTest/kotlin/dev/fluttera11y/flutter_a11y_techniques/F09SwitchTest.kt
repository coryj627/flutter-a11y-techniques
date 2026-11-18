// L3 (tree) and L4 (TalkBack walk) for F09 Switch on Android.
// Spec: docs/specs/F09-switch.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BLUETOOTH = "Bluetooth"
private const val BUTTON = "android.widget.Button"
private const val SWITCH = "android.widget.Switch"
private const val VIEW = "android.view.View"

@RunWith(AndroidJUnit4::class)
class F09SwitchTest : TechniqueTest("F09") {
    private fun open(slug: String) = openExample(slug, By.res("f09-$slug-count"))

    private fun switches(): List<AccessibilityNodeInfo> = all().filter { it.type() == SWITCH }

    @Suppress("DEPRECATION")
    private fun isOn(node: AccessibilityNodeInfo): Boolean = node.isChecked

    private fun waitForState(find: () -> AccessibilityNodeInfo, expected: Boolean, what: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && isOn(find()) != expected) Thread.sleep(100)
        assertEquals("state of $what", expected, isOn(find()))
    }

    // slug, identifier, name. Each starts off.
    private val controls = listOf(
        Triple("good-tile", "f09-good-tile-bluetooth", BLUETOOTH),
        Triple("good-cupertino", "f09-good-cupertino-bluetooth", BLUETOOTH),
        Triple("good-custom", "f09-good-custom-bluetooth", BLUETOOTH),
        Triple("good-group", "f09-good-group-messages", "Messages"),
        Triple("good-group", "f09-good-group-reminders", "Reminders"),
    )

    @Test
    fun switchesHaveTheirNameRoleAndState() {
        for ((slug, id, name) in controls) {
            open(slug)
            val node = node(id)
            assertEquals(id, SWITCH, node.type())
            assertEquals(id, name, node.name())
            assertTrue(id, node.isCheckable)
            assertFalse(id, isOn(node))
            assertTrue(id, node.isEnabled)
            assertTrue(id, node.isClickable)
            assertTrue(id, node.stateDescription.isNullOrEmpty())
            // The label is part of the switch, not a node of its own.
            assertEquals(id, 1, all().count { it.name() == name })
            assertTrue(id, node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForState({ node(id) }, true, id)
            assertEquals(id, name, node(id).name())
            assertTrue(id, node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForState({ node(id) }, false, id)
            waitForCount(slug, 2)
        }
    }

    @Test
    fun goodGroupHasTheQuestionOnANodeAroundTheSwitches() {
        open("good-group")
        val group = node("f09-good-group-notify")
        assertEquals(VIEW, group.type())
        assertEquals("Notify me about", group.name())
        assertFalse(group.isClickable)
        assertEquals(group, node("f09-good-group-messages").parent)
        assertEquals(group, node("f09-good-group-reminders").parent)
        // The visible text is not a second node.
        assertEquals(1, all().count { it.name().contains("Notify me about") })
    }

    @Test
    fun badUnlabelledHasASwitchWithNoName() {
        open("bad-unlabelled")
        val control = switches().single()
        assertEquals("", control.name())
        assertTrue(control.text.isNullOrEmpty())
        val text = named(BLUETOOTH)
        assertEquals(VIEW, text.type())
        assertFalse(text.isCheckable)
        assertFalse(text.isClickable)
    }

    @Test
    fun badTileNotMergedIsAButtonAroundASwitchWithNoName() {
        open("bad-tile-not-merged")
        for ((clicks, on) in listOf(0 to false, 1 to true)) {
            val row = named(BLUETOOTH)
            assertEquals(BUTTON, row.type())
            assertFalse(row.isCheckable)
            assertTrue(row.isClickable)
            val control = switches().single()
            assertEquals("", control.name())
            assertEquals(row, control.parent)
            waitForState({ switches().single() }, on, "the switch")
            waitForCount("bad-tile-not-merged", clicks)
            if (clicks == 0) assertTrue(row.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        }
    }

    @Test
    fun badLabelChangesHasANameThatChangesWithTheState() {
        open("bad-label-changes")
        val id = "f09-bad-label-changes-bluetooth"
        assertEquals(SWITCH, node(id).type())
        assertEquals("Bluetooth off", node(id).name())
        assertFalse(isOn(node(id)))
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForState({ node(id) }, true, id)
        assertEquals("Bluetooth on", node(id).name())
    }

    @Test
    fun badNoStateIsAButtonWithNoState() {
        open("bad-no-state")
        val id = "f09-bad-no-state-bluetooth"
        assertEquals(0, switches().size)
        for (clicks in 1..2) {
            val node = node(id)
            assertEquals(BUTTON, node.type())
            assertEquals(BLUETOOTH, node.name())
            assertFalse(node.isCheckable)
            assertTrue(node.stateDescription.isNullOrEmpty())
            assertFalse(node.isSelected)
            assertTrue(node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount("bad-no-state", clicks)
        }
    }

    /**
     * L4. Moves TalkBack focus to each control of every example and logs
     * markers; tool/talkback.py reads the speech from logcat. To read the
     * state after a change, the control is changed and focused a second
     * time. Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        fun byId(id: String) = Stop(id) { node(id) }
        // Focus is taken off the element before it is changed, so that what
        // is logged is what TalkBack reads on arriving, not a change notice.
        fun afterClick(marker: String, slug: String, click: () -> AccessibilityNodeInfo, find: () -> AccessibilityNodeInfo) =
            Stop("$marker-changed", {
                node("f09-$slug-count").performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
                Thread.sleep(3_000)
                click().performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Thread.sleep(2_000)
            }, find)
        fun afterClick(id: String, slug: String) = afterClick(id, slug, { node(id) }, { node(id) })
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-tile" to listOf(
                byId("f09-good-tile-bluetooth"), afterClick("f09-good-tile-bluetooth", "good-tile")),
            "good-cupertino" to listOf(
                byId("f09-good-cupertino-bluetooth"), afterClick("f09-good-cupertino-bluetooth", "good-cupertino")),
            "good-custom" to listOf(
                byId("f09-good-custom-bluetooth"), afterClick("f09-good-custom-bluetooth", "good-custom")),
            "good-group" to listOf(
                byId("f09-good-group-notify"),
                byId("f09-good-group-messages"),
                byId("f09-good-group-reminders")),
            // No identifiers here: the nodes are found by what they are.
            "bad-unlabelled" to listOf(
                Stop("f09-bad-unlabelled-switch") { switches().single() },
                Stop("f09-bad-unlabelled-text") { named(BLUETOOTH) }),
            "bad-tile-not-merged" to listOf(
                Stop("f09-bad-tile-not-merged-tile") { named(BLUETOOTH) },
                Stop("f09-bad-tile-not-merged-switch") { switches().single() },
                afterClick("f09-bad-tile-not-merged-tile", "bad-tile-not-merged",
                    { named(BLUETOOTH) }, { named(BLUETOOTH) })),
            "bad-label-changes" to listOf(
                byId("f09-bad-label-changes-bluetooth"),
                afterClick("f09-bad-label-changes-bluetooth", "bad-label-changes")),
            "bad-no-state" to listOf(
                byId("f09-bad-no-state-bluetooth"), afterClick("f09-bad-no-state-bluetooth", "bad-no-state")),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}
