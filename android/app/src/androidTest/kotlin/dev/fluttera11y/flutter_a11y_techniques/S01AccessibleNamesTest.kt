// L3 (tree) and L4 (TalkBack walk) for S01 Accessible names on Android.
// Spec: docs/specs/S01-accessible-names.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val CHECKBOX = "android.widget.CheckBox"
private const val SWITCH = "android.widget.Switch"
private const val SEEKBAR = "android.widget.SeekBar"

@RunWith(AndroidJUnit4::class)
class S01AccessibleNamesTest : TechniqueTest("S01") {
    /**
     * Opens an example and waits for [firstId], a control only it has. No
     * wait for idle after it: S01's tests and its TalkBack transcript were
     * made without one.
     */
    private fun open(slug: String, firstId: String) = openExample(slug, By.res(firstId), idle = false)

    private fun name(id: String): String = node(id).name()

    private fun waitForChecked(id: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !node(id).isChecked) Thread.sleep(100)
        assertTrue("$id is on after a click", node(id).isChecked)
    }

    private fun withText(root: AccessibilityNodeInfo?, text: String, out: MutableList<AccessibilityNodeInfo>) {
        if (root == null) return
        if (root.contentDescription?.toString() == text || root.text?.toString() == text) out.add(root)
        for (i in 0 until root.childCount) withText(root.getChild(i), text, out)
    }

    /** Every node whose description or text is exactly [text]. */
    private fun nodesNamed(text: String): List<AccessibilityNodeInfo> =
        mutableListOf<AccessibilityNodeInfo>().also { withText(automation.rootInActiveWindow, text, it) }

    // slug -> id -> (class, name)
    private val named = mapOf(
        "good-visible-label" to mapOf(
            "s01-good-visible-label-updates" to (CHECKBOX to "Email me order updates"),
            "s01-good-visible-label-dark" to (SWITCH to "Dark mode")),
        "good-merged-label" to mapOf(
            "s01-good-merged-label-remember" to (CHECKBOX to "Remember this device"),
            "s01-good-merged-label-wifi" to (SWITCH to "Wi-Fi")),
        "good-specific-names" to mapOf(
            "s01-good-specific-names-email" to (SWITCH to "Order updates, email"),
            "s01-good-specific-names-sms" to (SWITCH to "Order updates, text message")),
        "good-cupertino" to mapOf(
            "s01-good-cupertino-airplane" to (SWITCH to "Airplane mode")),
    )

    @Test
    fun goodControlsExposeNameRoleStateAndOperate() {
        for ((slug, controls) in named) {
            open(slug, controls.keys.first())
            for ((id, expected) in controls) {
                val (cls, expectedName) = expected
                val node = node(id)
                assertEquals("$id class", cls, node.className?.toString())
                assertEquals("$id name", expectedName, name(id))
                assertTrue("$id checkable", node.isCheckable)
                assertFalse("$id starts off", node.isChecked)
                assertTrue("$id clickable", node.isClickable)
                assertTrue("$id focusable", node.isFocusable)
                // The visible text is part of the control, not a second node.
                assertEquals("$id: nodes named \"$expectedName\"", 1, nodesNamed(expectedName).size)
                assertTrue("$id click", node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForChecked(id)
            }
        }
    }

    // VAL-3: each bad example is asserted to have its named defect.

    @Test
    fun badUnassociatedLabelHasNoName() {
        val id = "s01-bad-unassociated-label-terms"
        open("bad-unassociated-label", id)
        val node = node(id)
        assertEquals(CHECKBOX, node.className?.toString())
        assertEquals("", name(id))
        assertTrue(node.text.isNullOrEmpty())
        // The text is a node of its own.
        val text = nodesNamed("I accept the terms")
        assertEquals(1, text.size)
        assertFalse(text.first().isCheckable)
    }

    @Test
    fun badDuplicateNamesAreIdentical() {
        open("bad-duplicate-names", "s01-bad-duplicate-names-email")
        val names = listOf("email", "sms").map { name("s01-bad-duplicate-names-$it") }
        assertEquals(listOf("Order updates", "Order updates"), names)
    }

    @Test
    fun badRoleInNameEndsWithRole() {
        val id = "s01-bad-role-in-name-dark"
        open("bad-role-in-name", id)
        assertEquals(SWITCH, node(id).className?.toString())
        assertTrue(name(id).lowercase().endsWith("switch"))
    }

    @Test
    fun sliderIsNamedOnAndroid() {
        // FL-028 is a web limitation. On Android the slider has its name, in
        // the description after the value.
        val id = "s01-bad-slider-name-web-volume"
        open("bad-slider-name-web", id)
        val node = node(id)
        assertEquals(SEEKBAR, node.className?.toString())
        assertEquals("40%, Volume", name(id))
        assertTrue(node.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD))
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && name(id) != "50%, Volume") Thread.sleep(100)
        assertEquals("50%, Volume", name(id))
    }

    /**
     * L4. Moves TalkBack focus to every identified node of every example and
     * logs markers; tool/talkback.py reads the speech from logcat. Skipped
     * unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val examples = named.mapValues { it.value.keys.toList() } + mapOf(
            "bad-unassociated-label" to listOf("s01-bad-unassociated-label-terms"),
            "bad-duplicate-names" to listOf(
                "s01-bad-duplicate-names-email", "s01-bad-duplicate-names-sms"),
            "bad-role-in-name" to listOf("s01-bad-role-in-name-dark"),
            "bad-slider-name-web" to listOf("s01-bad-slider-name-web-volume"))
        talkBackWalk(
            examples.map { (slug, ids) -> slug to ids.map { id -> Stop(id) { node(id) } } },
            open = { slug -> open(slug, examples.getValue(slug).first()) },
            // Long enough for the state, a long name, and the role. At 4.5
            // seconds the role was sometimes not spoken yet.
            dwellMillis = { 8_000 })
    }
}
