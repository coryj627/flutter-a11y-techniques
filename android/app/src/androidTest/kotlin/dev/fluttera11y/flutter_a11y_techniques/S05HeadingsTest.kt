// L3 (tree) and L4 (TalkBack walk) for S05 Headings on Android.
// Spec: docs/specs/S05-headings.md.
//
// Elements are found by their text: headings have no controls to identify,
// and their text is what the tests are about.
package dev.fluttera11y.flutter_a11y_techniques

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class S05HeadingsTest : TechniqueTest("S05") {
    // Waits for this example's own title.
    private fun open(slug: String) = openExample(slug, By.desc(titles.getValue(slug)))

    private val titles = mapOf(
        "good-levels" to "Headings with levels",
        "good-cupertino" to "Cupertino section heading",
        "bad-visual-only" to "Heading by appearance only",
        "bad-fake-label" to "The word \"heading\" in the name",
        "bad-skipped-level" to "Skipped heading level",
        "bad-header-only" to "Heading with no level",
        "bad-emphasis-heading" to "Heading used for emphasis",
        "bad-cupertino-section-header" to "Cupertino section header that is not a heading",
    )

    private fun assertHeading(text: String) = assertTrue("\"$text\" should be a heading", named(text).isHeading)

    private fun assertNotHeading(text: String) =
        assertFalse("\"$text\" should not be a heading", named(text).isHeading)

    @Test
    fun goodLevelsAreHeadingsAndBodyTextIsNot() {
        open("good-levels")
        listOf("Profile", "Contact details", "Email preferences", "Security").forEach(::assertHeading)
        assertNotHeading("Choose which messages you receive.")
        // The screen title and the shell's section heading are headings too.
        assertHeading("Headings with levels")
        assertHeading("Example")
    }

    @Test
    fun goodCupertinoSectionHeaderIsAHeading() {
        open("good-cupertino")
        assertHeading("Notifications")
        assertNotHeading("Order updates")
    }

    // VAL-3: each bad example is asserted to have its named defect.

    @Test
    fun badVisualOnlyIsNotAHeading() {
        open("bad-visual-only")
        assertNotHeading("Profile")
    }

    @Test
    fun badFakeLabelIsNotAHeading() {
        open("bad-fake-label")
        assertNotHeading("Profile, heading")
    }

    @Test
    fun badSkippedLevelExposesNoLevelsOnAndroid() {
        // Android has one heading level: both are headings and the skipped
        // level cannot be seen here. It is asserted in the widget and web tests.
        open("bad-skipped-level")
        assertHeading("Profile")
        assertHeading("Contact details")
    }

    @Test
    fun badHeaderOnlyIsNotAHeadingOnAndroid() {
        // Flutter limitation FL-005: Android takes the heading property from
        // headingLevel only. If "Profile" becomes a heading after an upgrade,
        // the limitation is fixed.
        open("bad-header-only")
        assertNotHeading("Profile")
    }

    @Test
    fun badEmphasisHeadingMarksASentenceAsAHeading() {
        open("bad-emphasis-heading")
        assertHeading("Please check your address before you pay.")
    }

    @Test
    fun badCupertinoSectionHeaderIsNotAHeading() {
        // Flutter limitation: CupertinoListSection does not expose its header.
        open("bad-cupertino-section-header")
        assertNotHeading("Notifications")
    }

    /**
     * L4. Moves TalkBack focus to each listed element and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running.
     */
    @Test
    fun talkBackWalk() {
        // slug -> (key suffix, text of the element)
        val walk = listOf(
            "good-levels" to listOf(
                "profile" to "Profile", "contact-details" to "Contact details",
                "email-preferences" to "Email preferences", "security" to "Security",
                "body" to "Choose which messages you receive."),
            "good-cupertino" to listOf("notifications" to "Notifications"),
            "bad-visual-only" to listOf("profile" to "Profile"),
            "bad-fake-label" to listOf("profile" to "Profile, heading"),
            "bad-skipped-level" to listOf("profile" to "Profile", "contact-details" to "Contact details"),
            "bad-header-only" to listOf("profile" to "Profile"),
            "bad-emphasis-heading" to listOf("notice" to "Please check your address before you pay."),
            "bad-cupertino-section-header" to listOf("notifications" to "Notifications"),
        )
        talkBackWalk(
            walk.map { (slug, elements) ->
                slug to elements.map { (key, text) -> Stop("s05-$slug-$key") { named(text) } }
            },
            open = ::open,
            dwellMillis = { 4_500 })
    }
}
