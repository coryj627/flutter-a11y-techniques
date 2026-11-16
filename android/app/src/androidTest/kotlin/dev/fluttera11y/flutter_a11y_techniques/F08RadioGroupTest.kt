// L3 (tree) and L4 (TalkBack walk) for F08 Radio group on Android.
// Spec: docs/specs/F08-radio-group.md.
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
private const val CHECK_BOX = "android.widget.CheckBox"
private const val RADIO_BUTTON = "android.widget.RadioButton"
private const val RADIO_GROUP = "android.widget.RadioGroup"
private const val QUESTION = "Delivery speed"
private const val VIEW = "android.view.View"

@RunWith(AndroidJUnit4::class)
class F08RadioGroupTest : TechniqueTest("F08") {
    private fun open(slug: String) = openExample(slug, By.res("f08-$slug-count"))

    private fun ofType(type: String): List<AccessibilityNodeInfo> = all().filter { it.type() == type }

    @Suppress("DEPRECATION")
    private fun AccessibilityNodeInfo.on(): Boolean = isChecked

    private val options = listOf("standard" to "Standard", "express" to "Express", "next-day" to "Next day")

    /** The id segment of the one option that is checked. */
    private fun chosen(slug: String): String =
        options.map { it.first }.filter { node("f08-$slug-$it").on() }.also {
            assertEquals("one option of $slug is checked", 1, it.size)
        }.single()

    private fun waitForChosen(slug: String, expected: String) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !node("f08-$slug-$expected").on()) Thread.sleep(100)
        assertEquals("chosen option of $slug", expected, chosen(slug))
    }

    // Examples whose options are radio buttons in the tree, "Express" chosen.
    private val radioExamples =
        listOf("good-group", "good-cupertino", "good-custom", "bad-group-unlabelled", "bad-checked-only")

    @Test
    fun radioButtonsHaveTheirNameRoleAndState() {
        for (slug in radioExamples) {
            open(slug)
            assertEquals(slug, 3, ofType(RADIO_BUTTON).size)
            for ((option, name) in options) {
                val node = node("f08-$slug-$option")
                assertEquals("$slug $option", RADIO_BUTTON, node.type())
                assertEquals("$slug $option", name, node.name())
                assertTrue("$slug $option", node.isCheckable)
                assertEquals("$slug $option", option == "express", node.on())
                assertTrue("$slug $option", node.isEnabled)
                assertTrue("$slug $option", node.isClickable)
                // The label is part of the radio button, not a node of its own.
                assertEquals("$slug $option", 1, all().count { it.name() == name })
            }
            // Choosing one clears the other.
            assertTrue(slug, node("f08-$slug-standard").performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForChosen(slug, "standard")
            assertTrue(slug, node("f08-$slug-next-day").performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForChosen(slug, "next-day")
            waitForCount(slug, 2)
        }
    }

    @Test
    fun goodExamplesHaveTheQuestionAsTheNameOfTheRadioGroup() {
        for ((slug, question, count) in listOf(
            Triple("good-group", QUESTION, 3),
            Triple("good-cupertino", QUESTION, 3),
            Triple("good-custom", QUESTION, 3),
            Triple("good-context", "Are you at home?", 2),
        )) {
            open(slug)
            // The visible question is a Text inside the RadioGroup, which
            // makes it the description of the group's own node.
            val group = ofType(RADIO_GROUP).single()
            assertEquals(slug, question, group.name())
            assertFalse(slug, group.isClickable)
            assertEquals(slug, count, ofType(RADIO_BUTTON).size)
            assertTrue(slug, ofType(RADIO_BUTTON).all { it.parent == group })
            assertEquals(slug, count, group.childCount)
            // The question is not a second node.
            assertEquals(slug, 1, all().count { it.name().contains(question) })
        }
    }

    @Test
    fun goodContextAnswersCarryTheQuestion() {
        open("good-context")
        assertEquals("Yes, I am at home", node("f08-good-context-yes").name())
        assertEquals("No, I am not at home", node("f08-good-context-no").name())
        assertTrue(node("f08-good-context-no").on())
        assertFalse(node("f08-good-context-yes").on())
    }

    @Test
    fun badUnlabelledHasRadioButtonsWithNoNames() {
        open("bad-unlabelled")
        val radios = ofType(RADIO_BUTTON)
        assertEquals(3, radios.size)
        assertTrue(radios.all { it.name().isEmpty() && it.text.isNullOrEmpty() })
        // The texts are not lost: with nothing to join, they become the
        // description of the group node around the buttons.
        val group = ofType(RADIO_GROUP).single()
        assertEquals("Standard\nExpress\nNext day", group.name())
    }

    @Test
    fun badGroupUnlabelledHasTheQuestionBesideTheGroup() {
        open("bad-group-unlabelled")
        val group = ofType(RADIO_GROUP).single()
        assertEquals("", group.name())
        val question = named(QUESTION)
        assertEquals(VIEW, question.type())
        assertEquals(0, question.childCount)
        assertEquals(question.parent, group.parent)
    }

    @Test
    fun badNoStateHasButtonsWithNoState() {
        open("bad-no-state")
        assertEquals(0, ofType(RADIO_BUTTON).size)
        for (pass in 1..2) {
            for ((option, name) in options) {
                val node = node("f08-bad-no-state-$option")
                assertEquals(BUTTON, node.type())
                assertEquals(name, node.name())
                assertFalse(node.isCheckable)
                assertFalse(node.isSelected)
                assertTrue(node.stateDescription.isNullOrEmpty())
            }
            assertTrue(node("f08-bad-no-state-standard").performAction(AccessibilityNodeInfo.ACTION_CLICK))
            waitForCount("bad-no-state", 1)
        }
    }

    @Test
    fun badCheckboxRoleHasCheckBoxes() {
        open("bad-checkbox-role")
        assertEquals(0, ofType(RADIO_BUTTON).size)
        assertEquals(3, ofType(CHECK_BOX).size)
        assertTrue(node("f08-bad-checkbox-role-express").on())
        assertTrue(node("f08-bad-checkbox-role-standard").performAction(AccessibilityNodeInfo.ACTION_CLICK))
        waitForChosen("bad-checkbox-role", "standard")
    }

    @Test
    fun badCheckedOnlyHasRadioButtonsAndNoGroup() {
        // The defect of this example is on iOS. On Android the buttons are
        // correct radio buttons; what is missing is the group.
        open("bad-checked-only")
        assertEquals(3, ofType(RADIO_BUTTON).size)
        assertEquals(0, ofType(RADIO_GROUP).size)
    }

    /**
     * L4. Moves TalkBack focus to the controls of every example and logs
     * markers; tool/talkback.py reads the speech from logcat. To read the
     * state after a change, an option is chosen and focused a second time.
     * Skipped unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        fun byId(id: String) = Stop(id) { node(id) }
        // Focus is taken off the element before it is changed, so that what
        // is logged is what TalkBack reads on arriving, not a change notice.
        fun afterClick(id: String, slug: String) = Stop("$id-changed", {
            node("f08-$slug-count").performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
            Thread.sleep(3_000)
            node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK)
            Thread.sleep(2_000)
        }) { node(id) }
        // The question, an option that is not chosen, the one that is, and
        // the first again after it has been chosen.
        fun group(slug: String) = slug to listOf(
            Stop("f08-$slug-group") { ofType(RADIO_GROUP).single() },
            byId("f08-$slug-standard"),
            byId("f08-$slug-express"),
            afterClick("f08-$slug-standard", slug))
        fun pair(slug: String) = slug to listOf(byId("f08-$slug-standard"), byId("f08-$slug-express"))
        val walk: List<Pair<String, List<Stop>>> = listOf(
            group("good-group"),
            group("good-cupertino"),
            group("good-custom"),
            "good-context" to listOf(
                Stop("f08-good-context-group") { ofType(RADIO_GROUP).single() },
                byId("f08-good-context-yes"),
                byId("f08-good-context-no")),
            // No identifiers here: the nodes are found by what they are.
            "bad-unlabelled" to listOf(
                Stop("f08-bad-unlabelled-first") { ofType(RADIO_BUTTON).first() },
                Stop("f08-bad-unlabelled-second") { ofType(RADIO_BUTTON)[1] }),
            "bad-group-unlabelled" to listOf(
                Stop("f08-bad-group-unlabelled-question") { named(QUESTION) },
                byId("f08-bad-group-unlabelled-standard"),
                byId("f08-bad-group-unlabelled-express")),
            "bad-no-state" to listOf(
                byId("f08-bad-no-state-standard"),
                byId("f08-bad-no-state-express"),
                afterClick("f08-bad-no-state-standard", "bad-no-state")),
            pair("bad-checkbox-role"),
            pair("bad-checked-only"),
        )
        talkBackWalk(walk, open = ::open, dwellMillis = { 6_000 })
    }
}
