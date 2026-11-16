// L3 (tree) and L4 (TalkBack walk) for S14 Values and state descriptions on
// Android. Spec: docs/specs/S14-values-and-state-descriptions.md.
//
// Android has no value of its own for a Flutter node: the engine writes
// "value, label" into the content description.
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
private const val SEEK_BAR = "android.widget.SeekBar"

@RunWith(AndroidJUnit4::class)
class S14ValuesAndStateDescriptionsTest : TechniqueTest("S14") {
    private fun open(slug: String) = openExample(slug, By.res("s14-$slug-count"))

    override val countName = "change count"

    private fun waitForName(id: String, expected: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && node(id).name() != expected) Thread.sleep(100)
        assertEquals("description of $id", expected, node(id).name())
    }

    // Flutter's increase and decrease actions are scroll forward and
    // backward on Android, which is what a SeekBar offers TalkBack.
    private fun increase(id: String) =
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD))

    private fun decrease(id: String) =
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD))

    @Test
    fun goodRatingIsASeekBarWhoseDescriptionHasTheValue() {
        open("good-rating")
        val id = "s14-good-rating-rating"
        assertEquals(SEEK_BAR, node(id).type())
        assertEquals("3 out of 5, Rating", node(id).name())
        increase(id)
        waitForName(id, "4 out of 5, Rating")
        decrease(id)
        decrease(id)
        waitForName(id, "2 out of 5, Rating")
        waitForCount("good-rating", 3)
        // The stars are not nodes of their own.
        assertEquals(0, node(id).childCount)
    }

    @Test
    fun goodStepIsOneNodeWithTheStep() {
        open("good-step")
        val id = "s14-good-step-progress"
        assertEquals("Step 2 of 4, Progress", node(id).name())
        assertEquals(0, all().count { it.name() in setOf("1", "2", "3", "4") })
        assertTrue(node("s14-good-step-next").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForName(id, "Step 3 of 4, Progress")
    }

    @Test
    fun goodButtonValueIsAButtonWhoseDescriptionHasTheMode() {
        open("good-button-value")
        val id = "s14-good-button-value-repeat"
        assertEquals(BUTTON, node(id).type())
        assertTrue(node(id).isClickable)
        assertFalse(node(id).isCheckable)
        for (mode in listOf("Off", "All", "One", "Off")) {
            waitForName(id, "$mode, Repeat")
            assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        }
    }

    @Test
    fun goodSliderFormatHasItsValueInMinutes() {
        open("good-slider-format")
        val id = "s14-good-slider-format-timer"
        assertEquals(SEEK_BAR, node(id).type())
        assertEquals("15 minutes, Timer", node(id).name())
        increase(id)
        waitForName(id, "20 minutes, Timer")
    }

    // Each bad example is asserted to have its named defect.

    @Test
    fun badRatingNoValueHasOnlyItsName() {
        open("bad-rating-no-value")
        val id = "s14-bad-rating-no-value-rating"
        assertEquals(SEEK_BAR, node(id).type())
        assertEquals("Rating", node(id).name())
        assertTrue(node(id).text.isNullOrEmpty())
        assertTrue(node(id).stateDescription.isNullOrEmpty())
        increase(id)
        waitForCount("bad-rating-no-value", 1)
        assertEquals("Rating", node(id).name())
    }

    @Test
    fun badStaleValueKeepsItsFirstValue() {
        open("bad-stale-value")
        val id = "s14-bad-stale-value-rating"
        assertEquals("3 out of 5, Rating", node(id).name())
        increase(id)
        waitForCount("bad-stale-value", 1)
        increase(id)
        waitForCount("bad-stale-value", 2)
        // The rating is now 5. Flutter's Android bridge puts increasedValue
        // in place of the value as soon as it sends the action, and the app
        // never sends another: the node says 4, which is wrong as well.
        assertEquals("4 out of 5, Rating", node(id).name())
    }

    @Test
    fun badStepNoValueIsFourNumbers() {
        open("bad-step-no-value")
        for (press in 0..1) {
            for (n in listOf("1", "2", "3", "4")) {
                val node = named(n)
                assertFalse("$n selected", node.isSelected)
                assertTrue("$n state", node.stateDescription.isNullOrEmpty())
            }
            assertEquals(0, all().count {
                it.name().contains("Progress") || Regex("Step \\d of 4").containsMatchIn(it.name())
            })
            assertTrue(node("s14-bad-step-no-value-next").performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount("bad-step-no-value", press + 1)
        }
    }

    @Test
    fun badButtonNoValueHasTheSameDescriptionInEveryMode() {
        open("bad-button-no-value")
        val id = "s14-bad-button-no-value-repeat"
        for (press in 1..3) {
            assertEquals(BUTTON, node(id).type())
            assertEquals("Repeat", node(id).name())
            assertFalse(node(id).isCheckable)
            assertFalse(node(id).isSelected)
            assertTrue(node(id).stateDescription.isNullOrEmpty())
            assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount("bad-button-no-value", press)
        }
    }

    @Test
    fun badValueOnSwitchHasTheCheckedStateAndTheValue() {
        open("bad-value-on-switch")
        val id = "s14-bad-value-on-switch-alarm"
        assertEquals(SWITCH, node(id).type())
        assertTrue(node(id).isCheckable)
        assertFalse(node(id).isChecked)
        // The value does not replace the state: it is added to the name.
        assertEquals("Deactivated, Home alarm", node(id).name())
        assertTrue(node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForName(id, "Activated, Home alarm")
        assertTrue(node(id).isChecked)
    }

    /**
     * L4. Moves TalkBack focus to each element and logs markers;
     * tool/talkback.py reads the speech from logcat. Where a value should
     * follow a change, the element is changed and focused a second time.
     * Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        fun byId(id: String) = Stop(id) { node(id) }
        // Focus is taken off the element before it is changed, so that what
        // is logged is what TalkBack reads on arriving, not a change notice.
        fun afterChange(id: String, slug: String, change: () -> Unit) = Stop("$id-changed", {
            node("s14-$slug-count").performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
            Thread.sleep(3_000)
            change()
            Thread.sleep(2_000)
        }) { node(id) }
        val click = { id: String -> { node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK); Unit } }
        val walk: List<Pair<String, List<Stop>>> = listOf(
            "good-rating" to listOf(
                byId("s14-good-rating-rating"),
                afterChange("s14-good-rating-rating", "good-rating") { increase("s14-good-rating-rating") }),
            "good-step" to listOf(
                byId("s14-good-step-progress"),
                afterChange("s14-good-step-progress", "good-step", click("s14-good-step-next"))),
            "good-button-value" to listOf(
                byId("s14-good-button-value-repeat"),
                afterChange("s14-good-button-value-repeat", "good-button-value",
                    click("s14-good-button-value-repeat"))),
            "good-slider-format" to listOf(byId("s14-good-slider-format-timer")),
            "bad-rating-no-value" to listOf(byId("s14-bad-rating-no-value-rating")),
            "bad-stale-value" to listOf(
                byId("s14-bad-stale-value-rating"),
                // Twice, to five stars: after one increase the bridge's
                // guess (FL-038) happens to be right.
                afterChange("s14-bad-stale-value-rating", "bad-stale-value") {
                    increase("s14-bad-stale-value-rating")
                    Thread.sleep(1_000)
                    increase("s14-bad-stale-value-rating")
                }),
            "bad-step-no-value" to listOf(
                Stop("s14-bad-step-no-value-one") { named("1") },
                Stop("s14-bad-step-no-value-two") { named("2") }),
            "bad-button-no-value" to listOf(
                byId("s14-bad-button-no-value-repeat"),
                afterChange("s14-bad-button-no-value-repeat", "bad-button-no-value",
                    click("s14-bad-button-no-value-repeat"))),
            "bad-value-on-switch" to listOf(byId("s14-bad-value-on-switch-alarm")),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}
