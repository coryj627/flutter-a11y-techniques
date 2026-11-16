// L3 (tree) and L4 (TalkBack walk) for S13 Roles and traits on Android.
// Spec: docs/specs/S13-roles-and-traits.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"
private const val SWITCH = "android.widget.Switch"
private const val CHECKBOX = "android.widget.CheckBox"
private const val VIEW = "android.view.View"

@RunWith(AndroidJUnit4::class)
class S13RolesAndTraitsTest : TechniqueTest("S13") {
    private fun open(slug: String) = openExample(slug, By.res("s13-$slug-count"))

    /** Sends a click and checks that, a second later, nothing was activated. */
    private fun clickDoesNothing(slug: String, node: AccessibilityNodeInfo) {
        // Flutter's bridge answers true to ACTION_CLICK on any node and
        // passes it on as a tap; the framework drops it when the node has
        // no tap action. So the result of performAction proves nothing.
        node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        Thread.sleep(1_000)
        assertEquals("activation count for $slug", 0, count(slug))
    }

    // slug -> identifier -> (name, class)
    private val good = mapOf(
        "good-standard" to mapOf(
            "s13-good-standard-save" to ("Save" to BUTTON),
            "s13-good-standard-wifi" to ("Wi-Fi" to SWITCH),
            "s13-good-standard-remember" to ("Remember me" to CHECKBOX)),
        "good-cupertino" to mapOf(
            "s13-good-cupertino-save" to ("Save" to BUTTON),
            "s13-good-cupertino-wifi" to ("Wi-Fi" to SWITCH)),
        "good-custom-button" to mapOf("s13-good-custom-button-scan" to ("Scan barcode" to BUTTON)),
        "good-custom-switch" to mapOf("s13-good-custom-switch-dark" to ("Dark mode" to SWITCH)),
        "good-selected" to mapOf(
            "s13-good-selected-day" to ("Day" to BUTTON),
            "s13-good-selected-week" to ("Week" to BUTTON),
            "s13-good-selected-month" to ("Month" to BUTTON)),
    )

    @Test
    fun goodExamplesHaveTheirRoleNameAndAction() {
        for ((slug, controls) in good) {
            open(slug)
            var n = 0
            for ((id, expected) in controls) {
                val (expectedName, expectedClass) = expected
                val node = node(id)
                assertEquals("$id class", expectedClass, node.type())
                assertEquals("$id name", expectedName, node.name())
                assertTrue("$id enabled", node.isEnabled)
                assertTrue("$id clickable", node.isClickable)
                assertTrue("$id click action", node.hasClickAction())
                assertTrue("$id focusable", node.isFocusable)
                val checkable = expectedClass != BUTTON
                assertEquals("$id checkable", checkable, node.isCheckable)
                assertFalse("$id checked at first", node.isChecked)
                assertTrue("$id click", node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForCount(slug, ++n)
                assertEquals("$id checked after a click", checkable, node(id).isChecked)
            }
            assertEquals("$slug button nodes",
                controls.values.count { it.second == BUTTON }, buttons().size)
        }
    }

    @Test
    fun goodSelectedMarksTheChosenButton() {
        open("good-selected")
        fun selected() = listOf("day", "week", "month").filter { node("s13-good-selected-$it").isSelected }
        assertEquals(listOf("week"), selected())
        node("s13-good-selected-month").performAction(AccessibilityNodeInfo.ACTION_CLICK)
        waitForCount("good-selected", 1)
        assertEquals(listOf("month"), selected())
    }

    // Each bad example is asserted to have its named defect.

    @Test
    fun badNoRoleIsAPlainView() {
        open("bad-no-role")
        val node = node("s13-bad-no-role-scan")
        assertEquals("Scan barcode", node.name())
        assertEquals(VIEW, node.type())
        assertEquals(0, buttons().size)
        // It can still be activated: the role is all that is missing.
        assertTrue(node.isClickable)
        assertTrue(node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("bad-no-role", 1)
    }

    @Test
    fun badWrongRoleIsAButtonWithNoState() {
        open("bad-wrong-role")
        for (n in 0..1) {
            val node = node("s13-bad-wrong-role-dark")
            assertEquals("Dark mode", node.name())
            assertEquals(BUTTON, node.type())
            assertFalse(node.isCheckable)
            assertFalse(node.isChecked)
            assertFalse(node.isSelected)
            assertTrue(node.stateDescription.isNullOrEmpty())
            assertTrue(node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount("bad-wrong-role", n + 1)
        }
    }

    @Test
    fun badRoleOnTextIsAButtonThatCannotBeClicked() {
        open("bad-role-on-text")
        val node = node("s13-bad-role-on-text-delivery")
        assertEquals("Free delivery", node.name())
        assertEquals(BUTTON, node.type())
        assertFalse(node.isClickable)
        assertFalse(node.hasClickAction())
        clickDoesNothing("bad-role-on-text", node)
    }

    @Test
    fun badRoleOnStandardHasAnUnnamedButtonAroundTheRealOne() {
        open("bad-role-on-standard")
        val buttons = buttons()
        assertEquals(2, buttons.size)
        val outer = buttons.single { it.name().isEmpty() }
        val inner = buttons.single { it.name() == "Save" }
        assertFalse(outer.isClickable)
        assertTrue(outer.text.isNullOrEmpty())
        assertEquals(1, outer.childCount)
        assertEquals("Save", outer.getChild(0).name())
        assertTrue(inner.isClickable)
        assertTrue(inner.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("bad-role-on-standard", 1)
    }

    @Test
    fun badActionHiddenHasNoClickAction() {
        open("bad-action-hidden")
        val node = node("s13-bad-action-hidden-scan")
        assertEquals("Scan barcode", node.name())
        assertEquals(BUTTON, node.type())
        assertTrue(node.isEnabled)
        // Nothing for TalkBack, Switch Access, or Voice Access to call.
        // That it works by touch and keyboard is asserted in the widget
        // tests and on web.
        assertFalse(node.isClickable)
        assertFalse(node.hasClickAction())
        clickDoesNothing("bad-action-hidden", node)
    }

    @Test
    fun badSwitchNotEnabledIsAnOrdinarySwitchOnAndroid() {
        // The defect is on iOS only (FL-033).
        open("bad-switch-not-enabled")
        val node = node("s13-bad-switch-not-enabled-dark")
        assertEquals("Dark mode", node.name())
        assertEquals(SWITCH, node.type())
        assertTrue(node.isEnabled)
        assertTrue(node.isCheckable)
        assertTrue(node.performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForCount("bad-switch-not-enabled", 1)
        assertTrue(node("s13-bad-switch-not-enabled-dark").isChecked)
    }

    /**
     * L4. Moves TalkBack focus to each control of every example and logs
     * markers; tool/talkback.py reads the speech from logcat. Skipped unless
     * TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val byId = { id: String -> Stop(id) { node(id) } }
        val walk: List<Pair<String, List<Stop>>> =
            good.map { (slug, controls) -> slug to controls.keys.map(byId) } + listOf(
                "bad-no-role" to listOf(byId("s13-bad-no-role-scan")),
                "bad-wrong-role" to listOf(byId("s13-bad-wrong-role-dark")),
                "bad-role-on-text" to listOf(byId("s13-bad-role-on-text-delivery")),
                // No identifiers here: the two buttons are found by name.
                "bad-role-on-standard" to listOf(
                    Stop("s13-bad-role-on-standard-outer") { buttons().single { it.name().isEmpty() } },
                    Stop("s13-bad-role-on-standard-save") { buttons().single { it.name() == "Save" } }),
                "bad-action-hidden" to listOf(byId("s13-bad-action-hidden-scan")),
                "bad-switch-not-enabled" to listOf(byId("s13-bad-switch-not-enabled-dark")),
            )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}
