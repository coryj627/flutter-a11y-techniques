// L3 (tree and keyboard) and L4 (TalkBack walk) for I04 Keyboard actions
// and shortcuts on Android.
// Spec: docs/specs/I04-keyboard-actions.md.
//
// Keys are sent with `input keyevent`, which the emulator's hardware
// keyboard delivers to Flutter (docs/evidence/probes/i01/README.md).
// Chords (Shift+Tab, Control+F) are four key events through
// Instrumentation.sendKeySync: the modifier down, the key down and up with
// the modifier's meta state, the modifier up; a key that only carries the
// meta state arrives at Flutter without the modifier
// (docs/evidence/probes/i02/README.md). Where focus is, is read from the
// one node that reports isFocused. Typing goes through
// Instrumentation.sendStringSync, as TechniqueTest.type does.
package dev.fluttera11y.flutter_a11y_techniques

import android.os.SystemClock
import android.view.InputDevice
import android.view.KeyCharacterMap
import android.view.KeyEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val BUTTON = "android.widget.Button"
private const val EDIT_TEXT = "android.widget.EditText"

private val GOOD = listOf("good-on-focus", "good-turn-off", "good-remap")
private val ALL = GOOD + listOf("bad-page-shortcut", "bad-no-arrow-keys")
// The strip answers the arrow keys, Home, and End in these.
private val STRIP_KEYS = GOOD + "bad-page-shortcut"
private val WITH_SETTING = listOf("good-turn-off", "good-remap")
private val PHOTOS = listOf("Trailhead", "Bridge", "Ridge", "Summit")
private val THUMBS = PHOTOS.map { it.lowercase() }

@RunWith(AndroidJUnit4::class)
class I04KeyboardActionsTest : TechniqueTest("I04") {
    override val countName: String get() = "notes saved"

    // Wait for the first thumbnail, near the top of every example: on CI's
    // 320 by 640 emulator the count can be out of view when the screen opens.
    private fun open(slug: String) = openExample(slug, By.res("i04-$slug-trailhead"))

    private fun part(slug: String, name: String): AccessibilityNodeInfo = revealed("i04-$slug-$name")

    /** "Bridge" for "Showing: Bridge, 2 of 4". */
    private fun showing(slug: String): String =
        part(slug, "showing").name().removePrefix("Showing: ").substringBefore(",")

    private fun favourites(slug: String): String = part(slug, "favourites").name()

    /** Waits up to 2 seconds for [read] to give [expected], then asserts it. */
    private fun waitFor(what: String, expected: String, read: () -> String) {
        val end = System.currentTimeMillis() + 2_000
        while (System.currentTimeMillis() < end && read() != expected) Thread.sleep(100)
        assertEquals(what, expected, read())
    }

    private fun expectShowing(slug: String, photo: String) = waitFor("$slug showing", photo) { showing(slug) }

    private fun expectFavourites(slug: String, text: String) =
        waitFor("$slug favourites", "Favourites: $text") { favourites(slug) }

    /** Waits a second and expects [read] still to give [expected]. */
    private fun expectStays(what: String, expected: String, read: () -> String) {
        Thread.sleep(1_000)
        assertEquals(what, expected, read())
    }

    /** The text in the note field; an empty field reports its hint as its text. */
    private fun note(slug: String): String = part(slug, "note").let {
        if (it.isShowingHintText) "" else it.text?.toString().orEmpty()
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act. */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    private fun chord(modifier: Int, meta: Int, code: Int) {
        val t = SystemClock.uptimeMillis()
        fun event(time: Long, action: Int, c: Int, m: Int) = KeyEvent(
            time, time, action, c, 0, m, KeyCharacterMap.VIRTUAL_KEYBOARD, 0, 0,
            InputDevice.SOURCE_KEYBOARD)
        inst.sendKeySync(event(t, KeyEvent.ACTION_DOWN, modifier, meta))
        inst.sendKeySync(event(t + 10, KeyEvent.ACTION_DOWN, code, meta))
        inst.sendKeySync(event(t + 20, KeyEvent.ACTION_UP, code, meta))
        inst.sendKeySync(event(t + 30, KeyEvent.ACTION_UP, modifier, 0))
        Thread.sleep(600)
    }

    private fun shiftTab() = chord(
        KeyEvent.KEYCODE_SHIFT_LEFT, KeyEvent.META_SHIFT_ON or KeyEvent.META_SHIFT_LEFT_ON, KeyEvent.KEYCODE_TAB)

    private fun controlF() = chord(
        KeyEvent.KEYCODE_CTRL_LEFT, KeyEvent.META_CTRL_ON or KeyEvent.META_CTRL_LEFT_ON, KeyEvent.KEYCODE_F)

    /**
     * The control with keyboard focus: "back", a part of the example by the
     * last part of its identifier, or "none". Fails if two nodes have it.
     */
    private fun stop(slug: String): String {
        val focused = all().filter { it.isFocused && (it.viewIdResourceName != null || it.name().isNotEmpty()) }
        if (focused.isEmpty()) return "none"
        assertEquals("nodes with focus: ${focused.map { it.viewIdResourceName ?: it.name() }}", 1, focused.size)
        val node = focused.single()
        if (node.name() == "Back") return "back"
        val id = node.viewIdResourceName.orEmpty()
        return if (id.startsWith("i04-$slug-")) id.removePrefix("i04-$slug-") else "other: $id ${node.name()}"
    }

    /**
     * Presses Tab until [name] has focus, at most [max] times. The first
     * Tab after the app opens can be lost (docs/evidence/probes/i01/README.md).
     */
    private fun tabTo(slug: String, name: String, max: Int = 9) {
        for (i in 0 until max) {
            key("TAB")
            if (stop(slug) == name) return
        }
        throw AssertionError("$slug: Tab did not reach $name; focus is on ${stop(slug)}")
    }

    /** Shows [photo] the way a screen reader would, with the click action. */
    private fun clickThumb(slug: String, photo: String) {
        assertTrue("$slug click $photo", part(slug, photo.lowercase()).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        expectShowing(slug, photo)
    }

    @Test
    fun everyPartHasItsNameAndClass() {
        for (slug in ALL) {
            open(slug)
            assertEquals(slug, "Showing: Trailhead, 1 of 4", part(slug, "showing").name())
            for ((i, photo) in PHOTOS.withIndex()) {
                val thumb = part(slug, THUMBS[i])
                assertEquals("$slug $photo", photo, thumb.name())
                assertEquals("$slug $photo", BUTTON, thumb.type())
                assertEquals("$slug $photo selected", i == 0, thumb.isSelected)
                assertFalse("$slug $photo", thumb.isFocused)
            }
            val favourite = part(slug, "favourite")
            assertEquals(slug, "Add to favourites", favourite.name())
            assertEquals(slug, BUTTON, favourite.type())
            val field = part(slug, "note")
            assertEquals(slug, EDIT_TEXT, field.type())
            assertEquals(slug, "Note", field.name().ifEmpty { field.hintText?.toString().orEmpty() })
            assertEquals(slug, "Favourites: none", favourites(slug))
            assertEquals(slug, 0, count(slug))
        }
    }

    @Test
    fun theClickActionShowsAnyPhoto() {
        for (slug in ALL) {
            open(slug)
            clickThumb(slug, "Ridge")
            assertTrue(slug, part(slug, "ridge").isSelected)
            clickThumb(slug, "Summit")
        }
    }

    @Test
    fun tabGoesBackTheShownThumbnailTheFavouriteButtonThenTheNote() {
        for (slug in ALL) {
            open(slug)
            tabTo(slug, "back", 3)
            val order = listOf("trailhead", "favourite") + (if (slug in WITH_SETTING) listOf("setting") else emptyList()) + "note"
            for (expected in order) {
                key("TAB")
                assertEquals(slug, expected, stop(slug))
            }
            // With another photo shown, its thumbnail is the strip's stop.
            clickThumb(slug, "Ridge")
            tabTo(slug, "favourite")
            shiftTab()
            assertEquals(slug, "ridge", stop(slug))
        }
    }

    @Test
    fun theStripsKeysShowAPhotoAndMoveFocusToItsThumbnail() {
        for (slug in STRIP_KEYS) {
            open(slug)
            tabTo(slug, "trailhead")
            for ((name, photo) in listOf(
                "DPAD_RIGHT" to "Bridge", "DPAD_RIGHT" to "Ridge", "DPAD_LEFT" to "Bridge",
                "MOVE_END" to "Summit", "DPAD_RIGHT" to "Summit", "MOVE_HOME" to "Trailhead",
                "DPAD_LEFT" to "Trailhead",
            )) {
                key(name)
                expectShowing(slug, photo)
                waitFor("$slug focus after $name", photo.lowercase()) { stop(slug) }
            }
        }
    }

    /**
     * bad-no-arrow-keys, one key per launch: the key does not move along the
     * strip. The controls, in the same launch: F acts on the strip, and
     * Down moves focus out of it, so keys and arrows do arrive.
     */
    private fun badNoArrowKeysIgnores(name: String) {
        val slug = "bad-no-arrow-keys"
        open(slug)
        clickThumb(slug, "Bridge")
        tabTo(slug, "bridge")
        key(name)
        expectStays("$slug showing after $name", "Bridge") { showing(slug) }
        val after = stop(slug)
        assertFalse("$name moved to $after", after in listOf("trailhead", "ridge", "summit"))
        if (after != "bridge") tabTo(slug, "bridge")
        key("F")
        expectFavourites(slug, "Bridge")
        key("DPAD_DOWN")
        val below = stop(slug)
        assertTrue("Down did not leave the strip: $below", below in listOf("favourite", "note"))
    }

    @Test fun badNoArrowKeysRightDoesNotMove() = badNoArrowKeysIgnores("DPAD_RIGHT")
    @Test fun badNoArrowKeysLeftDoesNotMove() = badNoArrowKeysIgnores("DPAD_LEFT")
    @Test fun badNoArrowKeysEndDoesNotMove() = badNoArrowKeysIgnores("MOVE_END")
    @Test fun badNoArrowKeysHomeDoesNotMove() = badNoArrowKeysIgnores("MOVE_HOME")

    @Test
    fun badNoArrowKeysTabNeverReachesTheOtherThumbnails() {
        val slug = "bad-no-arrow-keys"
        open(slug)
        val seen = mutableListOf<String>()
        for (i in 0 until 7) { key("TAB"); seen += stop(slug) }
        for (i in 0 until 6) { shiftTab(); seen += stop(slug) }
        assertTrue("seen: $seen", seen.containsAll(listOf("back", "trailhead", "favourite", "note")))
        for (other in listOf("bridge", "ridge", "summit")) assertFalse("seen: $seen", other in seen)
    }

    @Test
    fun enterInTheNoteSavesItAndTakesFocusFromIt() {
        for (slug in ALL) {
            open(slug)
            tabTo(slug, "note")
            inst.sendStringSync("Muddy")
            waitFor("$slug note", "Muddy") { note(slug) }
            key("ENTER")
            waitForCount(slug, 1)
            waitFor("$slug note after Enter", "") { note(slug) }
            // FL-461: the field gives focus up to no control. The tree
            // still reported isFocused on the field after Enter (first
            // run), so what is asserted is what the keys do: a letter
            // typed now goes nowhere, though the field took "Muddy" a
            // moment ago, and the next Tab goes to Back.
            inst.sendStringSync("x")
            expectStays("$slug note after a letter", "") { note(slug) }
            key("TAB")
            assertEquals("$slug: the next Tab starts from the top", "back", stop(slug))
        }
    }

    @Test
    fun goodOnFocusFActsInTheStripOnly() {
        val slug = "good-on-focus"
        open(slug)
        tabTo(slug, "trailhead")
        key("F")
        expectFavourites(slug, "Trailhead")
        tabTo(slug, "favourite")
        key("F")
        expectStays("$slug favourites after F on the button", "Favourites: Trailhead") { favourites(slug) }
        tabTo(slug, "note")
        inst.sendStringSync("Leafy")
        waitFor("$slug note", "Leafy") { note(slug) }
        assertEquals("Favourites: Trailhead", favourites(slug))
    }

    @Test
    fun aPageWideFActsWhereverFocusIsAndTypesInTheNote() {
        for (slug in listOf("good-turn-off", "good-remap")) {
            open(slug)
            tabTo(slug, "trailhead")
            key("F")
            expectFavourites(slug, "Trailhead")
            key("DPAD_RIGHT")
            tabTo(slug, "favourite")
            key("F")
            expectFavourites(slug, "Trailhead, Bridge")
            tabTo(slug, "setting")
            key("F")
            expectFavourites(slug, "Trailhead")
            tabTo(slug, "note")
            inst.sendStringSync("Leafy")
            waitFor("$slug note", "Leafy") { note(slug) }
            assertEquals(slug, "Favourites: Trailhead", favourites(slug))
        }
    }

    @Test
    fun goodTurnOffTheSwitchTurnsFOff() {
        val slug = "good-turn-off"
        open(slug)
        assertTrue(part(slug, "setting").isChecked)
        tabTo(slug, "setting")
        key("SPACE")
        waitFor("switch", "false") { part(slug, "setting").isChecked.toString() }
        key("F")
        expectStays("favourites after F on the switch", "Favourites: none") { favourites(slug) }
        shiftTab()
        shiftTab()
        assertEquals("trailhead", stop(slug))
        key("F")
        expectStays("favourites after F on the strip", "Favourites: none") { favourites(slug) }
        // The keys arrive: the strip's own keys still act.
        key("DPAD_RIGHT")
        expectShowing(slug, "Bridge")
        // The control: on again, the same key acts.
        tabTo(slug, "setting")
        key("SPACE")
        key("F")
        expectFavourites(slug, "Bridge")
    }

    @Test
    fun goodRemapTheSwitchMovesFToControlF() {
        val slug = "good-remap"
        open(slug)
        tabTo(slug, "setting")
        controlF()
        expectStays("favourites after Control+F while the key is F", "Favourites: none") { favourites(slug) }
        key("SPACE")
        waitFor("switch", "true") { part(slug, "setting").isChecked.toString() }
        key("F")
        expectStays("favourites after F", "Favourites: none") { favourites(slug) }
        controlF()
        expectFavourites(slug, "Trailhead")
    }

    @Test
    fun badPageShortcutFActsWhereverFocusIs() {
        val slug = "bad-page-shortcut"
        open(slug)
        tabTo(slug, "trailhead")
        key("F")
        expectFavourites(slug, "Trailhead")
        tabTo(slug, "favourite")
        key("F")
        expectFavourites(slug, "none")
        assertFalse("a setting", anyWindowHas { it.viewIdResourceName == "i04-$slug-setting" })
    }

    /**
     * What happens to an f typed in the note of bad-page-shortcut on
     * Android: the input method has the letter keys first while a field is
     * being edited, so the shortcut never sees them, and the letter is typed
     * (docs/evidence/probes/i04/README.md). The web and iOS lose the letter
     * (web and iOS tests).
     */
    @Test
    fun badPageShortcutOnAndroidTheNoteStillGetsItsF() {
        val slug = "bad-page-shortcut"
        open(slug)
        tabTo(slug, "note")
        inst.sendStringSync("Leafy")
        waitFor("$slug note", "Leafy") { note(slug) }
        expectStays("$slug favourites", "Favourites: none") { favourites(slug) }
        // The control, in the same launch: F away from the field acts.
        shiftTab()
        assertNotEquals("note", stop(slug))
        key("F")
        expectFavourites(slug, "Trailhead")
    }

    /**
     * L4. Moves TalkBack focus to each part and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless
     * TalkBack is running. The keys are not heard: TalkBack reads the
     * strip the same way with or without them.
     */
    @Test
    fun talkBackWalk() {
        val walk: List<Pair<String, List<Stop>>> = ALL.map { slug ->
            val parts = THUMBS + "favourite" + (if (slug in WITH_SETTING) listOf("setting") else emptyList()) + "note"
            slug to parts.map { p -> Stop("i04-$slug-$p") { revealed("i04-$slug-$p") } }
        }
        talkBackWalk(walk, open = ::open, dwellMillis = { 3_000 })
    }
}
