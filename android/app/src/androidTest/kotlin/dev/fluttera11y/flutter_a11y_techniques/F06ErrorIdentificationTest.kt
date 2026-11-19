// L3 (tree) and L4 (TalkBack) for F06 Error identification and announcement
// on Android. Spec: docs/specs/F06-error-identification.md.
package dev.fluttera11y.flutter_a11y_techniques

import android.util.Log
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val EDIT_TEXT = "android.widget.EditText"
private const val NAME_ERROR = "Enter your name."
private const val EMAIL_ERROR = "Enter an email address with an @, like name@example.com."

@RunWith(AndroidJUnit4::class)
class F06ErrorIdentificationTest : TechniqueTest("F06") {
    override val countName: String get() = "sent count"

    private fun open(slug: String) = openExample(slug, By.res("f06-$slug-count"))

    // TalkBack can put a window of its own in front; look everywhere.
    private fun openWithTalkBack(slug: String) =
        openExampleInAnyWindow(slug) { it.viewIdResourceName == "f06-$slug-count" }

    private fun send(slug: String) =
        assertTrue("$slug send", nodeInAnyWindow("f06-$slug-send").performAction(AccessibilityNodeInfo.ACTION_CLICK))

    /** What Flutter gives a text field on Android: its label, then its hint, in the hint text. */
    private fun hint(id: String): String = nodeInAnyWindow(id).hintText?.toString().orEmpty()

    /** The node, in any window, whose content description is [text]. */
    private fun withText(text: String): AccessibilityNodeInfo? {
        var found: AccessibilityNodeInfo? = null
        anyWindowHas { n -> (n.name() == text).also { if (it) found = n } }
        return found
    }

    private fun waitFor(what: String, check: () -> Boolean) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && !check()) Thread.sleep(100)
        assertTrue(what, check())
    }

    /** The soft keyboard stays up after typing on the CI emulator; Back closes it. */
    private fun hideKeyboard() {
        if (automation.windows.any { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD }) {
            device.pressBack()
            waitFor("keyboard hidden") {
                automation.windows.none { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD }
            }
            device.waitForIdle()
        }
    }

    /**
     * Puts the keyboard away, then waits up to 5 seconds for the count of
     * [slug] to be in the tree again, looking in every window. At CI's
     * emulator size, 320 by 640 at 160 dpi, the keyboard that comes up when
     * focus moves to a field in error covers the lower part of the screen:
     * Send and the count below it are then out of view and not in the tree
     * at all, and they are back within three seconds of Back putting the
     * keyboard away (measured on this project's emulator set to that size,
     * docs/evidence/probes/f06/keyboard; CI run 44386619996 failed on the
     * missing count). A first version that waited with UI Automator's
     * `Until.hasObject` failed there; the probe found the count by searching
     * the windows directly, as this does.
     */
    private fun closeKeyboardAndWaitForCount(slug: String) {
        hideKeyboard()
        // On CI the count was once still missing five seconds after the
        // keyboard was put away (run 44417692327, attempt 2), so it is also
        // scrolled to: the shared count() does that when it is not in the
        // tree.
        waitFor("the count of $slug can be read") {
            try { count(slug); true } catch (e: AssertionError) { false }
        }
    }

    /**
     * Waits up to 8 seconds for the count of [slug] to be readable and equal
     * to [expected]. With focus on a field the keyboard can come up again
     * on CI's small screen and take the count out of the tree after it was
     * seen there (one CI run: "no node with id f06-good-form-count" at this
     * point), so the keyboard is put away again on every try.
     */
    private fun waitForCountWithKeyboardAway(slug: String, expected: Int) {
        val end = System.currentTimeMillis() + 8_000
        var last: Int? = null
        while (System.currentTimeMillis() < end) {
            hideKeyboard()
            last = try { count(slug) } catch (e: AssertionError) { null }
            if (last == expected) return
            Thread.sleep(250)
        }
        assertEquals("$countName for $slug (null: not in the tree)", expected, last)
    }

    private val good = mapOf(
        "good-form" to listOf(
            Triple("f06-good-form-name", "Name", NAME_ERROR),
            Triple("f06-good-form-email", "Email", EMAIL_ERROR)),
        "good-cupertino" to listOf(
            Triple("f06-good-cupertino-name", "Name", NAME_ERROR),
            Triple("f06-good-cupertino-email", "Email", EMAIL_ERROR)),
    )

    @Test
    fun goodFieldsShowTheirErrorInTheirHintAndAsALiveRegion() {
        for ((slug, fields) in good) {
            open(slug)
            for ((id, label, _) in fields) {
                assertEquals(id, EDIT_TEXT, node(id).type())
                assertEquals(id, label, hint(id))
            }
            send(slug)
            waitFor("$slug errors shown") { withText(NAME_ERROR) != null }
            // Input focus is on the first field in error.
            waitFor("$slug first field focused") { node(fields[0].first).isFocused }
            assertFalse("$slug second field not focused", node(fields[1].first).isFocused)
            closeKeyboardAndWaitForCount(slug)
            for ((id, label, error) in fields) {
                waitFor("$id and its error in the tree") { withText(error) != null }
                // Flutter joins the label and the error with ", ".
                assertEquals(id, "$label, $error", hint(id))
                assertTrue(id, node(id).contentDescription.isNullOrEmpty())
                // Flutter sets neither of the native error properties.
                assertTrue(id, node(id).error.isNullOrEmpty())
                assertFalse(id, node(id).isContentInvalid)
                assertEquals(id, View.ACCESSIBILITY_LIVE_REGION_NONE, node(id).liveRegion)
                // The visible error is a node of its own, and a live region.
                val message = withText(error)!!
                assertEquals(error, View.ACCESSIBILITY_LIVE_REGION_POLITE, message.liveRegion)
                assertFalse(error, message.isEditable)
            }
            waitForCountWithKeyboardAway(slug, 0)
        }
    }

    @Test
    fun goodFormsMoveToTheNextErrorAndSendOnceRight() {
        for ((slug, fields) in good) {
            open(slug)
            val (name, _, _) = fields[0]
            val (email, _, _) = fields[1]
            send(slug)
            waitFor("$slug name focused") { node(name).isFocused }
            type(name, "Ana")
            type(email, "abc")
            hideKeyboard()
            send(slug)
            waitFor("$slug email focused") { node(email).isFocused }
            // The tree can take a moment longer than focus to update.
            waitFor("$slug name error cleared") { hint(name) == "Name" }
            assertEquals(name, "Name", hint(name))
            assertEquals(email, "Email, $EMAIL_ERROR", hint(email))
            // Put the text cursor at the end of "abc" and add the rest.
            val selection = android.os.Bundle().apply {
                putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_START_INT, 3)
                putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_END_INT, 3)
            }
            assertTrue(email, node(email).performAction(AccessibilityNodeInfo.ACTION_SET_SELECTION, selection))
            Thread.sleep(500)
            inst.sendStringSync("@example.com")
            waitFor("$slug email typed") { value(email) == "abc@example.com" }
            hideKeyboard()
            send(slug)
            waitForCount(slug, 1)
            // A form that goes through is a status message: the count is a
            // polite live region.
            assertEquals("$slug count", View.ACCESSIBILITY_LIVE_REGION_POLITE,
                node("f06-$slug-count").liveRegion)
            assertEquals(email, "Email", hint(email))
            assertTrue("$slug errors gone", withText(EMAIL_ERROR) == null)
        }
    }

    // VAL-3: each bad example is asserted to have its named defect.

    @Test
    fun badColorOnlyHasNoWordsForTheError() {
        open("bad-color-only")
        val id = "f06-bad-color-only-email"
        val before = all().map { it.name() }.toSet()
        send("bad-color-only")
        waitFor("field focused") { node(id).isFocused }
        // Compare with the keyboard away, so that nothing is out of view.
        closeKeyboardAndWaitForCount("bad-color-only")
        // The field is in error and focused, and nothing new can be read.
        // What can be read now is compared with what could be read before
        // for anything added, not for being the same: on a 320 by 640 screen
        // putting the keyboard away and scrolling to the count leaves
        // different parts of the page in view from one run to the next (CI
        // runs 44580353546 and 44615147153 each lacked a different line that
        // was there before).
        assertEquals("Email", hint(id))
        assertEquals(emptySet<String>(), all().map { it.name() }.toSet() - before)
    }

    @Test
    fun badVagueMessageSaysOnlyInvalid() {
        open("bad-vague-message")
        val id = "f06-bad-vague-message-email"
        send("bad-vague-message")
        waitFor("error shown") { withText("Invalid.") != null }
        assertEquals("Email, Invalid.", hint(id))
        assertEquals(View.ACCESSIBILITY_LIVE_REGION_POLITE, withText("Invalid.")!!.liveRegion)
    }

    @Test
    fun badNotAnnouncedIsALiveRegionOnAndroid() {
        // The defect is on iOS and the web. On Android the error text of
        // this unmerged TextField is a live region, so this pins down that
        // Android is not affected; it fails if that changes.
        open("bad-not-announced")
        val id = "f06-bad-not-announced-email"
        send("bad-not-announced")
        waitFor("error shown") { withText(EMAIL_ERROR) != null }
        assertEquals("Email, $EMAIL_ERROR", hint(id))
        assertEquals(View.ACCESSIBILITY_LIVE_REGION_POLITE, withText(EMAIL_ERROR)!!.liveRegion)
        assertFalse("focus stays off the field", node(id).isFocused)
    }

    @Test
    fun badMergedErrorPutsTheErrorInTheNameAndMakesTheFieldALiveRegion() {
        open("bad-merged-error")
        val id = "f06-bad-merged-error-email"
        send("bad-merged-error")
        // The error twice: merged into the label, then again as the hint.
        // The two arrive in separate updates, so wait for both.
        val merged = "Email\n$EMAIL_ERROR, $EMAIL_ERROR"
        waitFor("error merged into the label and the hint") { hint(id) == merged }
        assertEquals(merged, hint(id))
        assertEquals(View.ACCESSIBILITY_LIVE_REGION_POLITE, node(id).liveRegion)
        assertTrue("no separate error node", withText(EMAIL_ERROR) == null)
    }

    /**
     * L4. For each example: TalkBack focus on Send and a marker, then Send is
     * pressed with ACTION_CLICK and what TalkBack says is logged under a
     * second marker; then the keyboard is closed and focus is moved to each
     * field and error in turn. The walk forces accessibility focus, so it
     * shows what is spoken, not the order of a swipe. Skipped unless
     * TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        assumeTalkBack()
        for ((slug, stops) in walk) {
            openWithTalkBack(slug)
            Thread.sleep(8_000)
            Log.i(talkBackTag, "FOCUS f06-$slug-send")
            talkBackFocus("$slug send") { nodeInAnyWindow("f06-$slug-send") }
            Thread.sleep(3_000)
            Log.i(talkBackTag, "FOCUS f06-$slug-sent")
            send(slug)
            Thread.sleep(7_000)
            // Where TalkBack's focus is now, from the tree.
            val focused = automation.windows.firstNotNullOfOrNull {
                it.root?.findFocus(AccessibilityNodeInfo.FOCUS_ACCESSIBILITY)
            }
            Log.i(talkBackTag, "END $slug-sent")
            Log.i("F06", "TalkBack focus after send on $slug: ${focused?.viewIdResourceName} ${focused?.hintText}")
            if (slug in focusMoves) {
                assertEquals("$slug: TalkBack focus on the first field in error",
                    focusMoves[slug], focused?.viewIdResourceName)
            }
            hideKeyboard()
            // Park TalkBack on Send first: focus may already be on the first
            // field, and a node that has focus says nothing when focused
            // again; "keyboard hidden" is said here too, not at a stop.
            talkBackFocus("Send") { nodeInAnyWindow("f06-$slug-send") }
            Thread.sleep(6_000)
            for ((marker, find) in stops) {
                Log.i(talkBackTag, "FOCUS $marker")
                talkBackFocus(marker, find)
                Thread.sleep(5_000)
            }
            if (slug == "good-form") {
                // A field in error that has a value: type into Email, which
                // keeps its error, and read it again from elsewhere.
                Log.i(talkBackTag, "END $slug")
                type("f06-good-form-email", "abc")
                hideKeyboard()
                talkBackFocus("Send") { nodeInAnyWindow("f06-good-form-send") }
                Thread.sleep(4_000)
                assertEquals("Email, $EMAIL_ERROR", hint("f06-good-form-email"))
                Log.i(talkBackTag, "FOCUS f06-good-form-email-filled")
                talkBackFocus("Email, filled") { nodeInAnyWindow("f06-good-form-email") }
                Thread.sleep(5_000)
                // A form that goes through: open good-form again, send it
                // empty so that both errors show, fill both fields (the
                // email field is empty here, so typing is enough), and send
                // again. Only the form going through should be announced,
                // not the errors that were put right.
                Log.i(talkBackTag, "END $slug-filled")
                openWithTalkBack(slug)
                Thread.sleep(8_000)
                send(slug)
                waitFor("errors shown") { withText(NAME_ERROR) != null }
                Thread.sleep(4_000)
                type("f06-good-form-name", "Ana")
                type("f06-good-form-email", "ana@example.com")
                hideKeyboard()
                talkBackFocus("Send") { nodeInAnyWindow("f06-good-form-send") }
                Thread.sleep(6_000)
                Log.i(talkBackTag, "FOCUS f06-good-form-sent-ok")
                send(slug)
                Thread.sleep(7_000)
            }
            Log.i(talkBackTag, "END $slug")
        }
    }

    private val focusMoves = mapOf(
        "good-form" to "f06-good-form-name",
        "good-cupertino" to "f06-good-cupertino-name",
    )

    private fun errorNode(text: String): () -> AccessibilityNodeInfo =
        { withText(text) ?: throw AssertionError("no node \"$text\"") }

    private val walk: List<Pair<String, List<Pair<String, () -> AccessibilityNodeInfo>>>> = listOf(
        "good-form" to listOf(
            "f06-good-form-name" to { nodeInAnyWindow("f06-good-form-name") },
            "f06-good-form-name-error" to errorNode(NAME_ERROR),
            "f06-good-form-email" to { nodeInAnyWindow("f06-good-form-email") },
        ),
        "good-cupertino" to listOf(
            "f06-good-cupertino-name" to { nodeInAnyWindow("f06-good-cupertino-name") },
            "f06-good-cupertino-name-error" to errorNode(NAME_ERROR),
        ),
        "bad-color-only" to listOf(
            "f06-bad-color-only-email" to { nodeInAnyWindow("f06-bad-color-only-email") },
        ),
        "bad-vague-message" to listOf(
            "f06-bad-vague-message-email" to { nodeInAnyWindow("f06-bad-vague-message-email") },
        ),
        "bad-not-announced" to listOf(
            "f06-bad-not-announced-email" to { nodeInAnyWindow("f06-bad-not-announced-email") },
        ),
        "bad-merged-error" to listOf(
            "f06-bad-merged-error-email" to { nodeInAnyWindow("f06-bad-merged-error-email") },
        ),
    )
}
