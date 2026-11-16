// L3 (tree) and L4 (TalkBack walk) for S03 Decorative images on Android.
// Spec: docs/specs/S03-decorative-images.md.
//
// Images have no controls to identify, so nodes are found by their
// description, or by their class when they have none.
package dev.fluttera11y.flutter_a11y_techniques

import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val IMAGE = "android.widget.ImageView"

/** Stands for "the one image node on the screen" in the TalkBack walk. */
private const val UNNAMED_IMAGE = "\u0000image"

private const val DELIVERY = "Delivery takes 2 to 4 days."

@RunWith(AndroidJUnit4::class)
class S03DecorativeImagesTest : TechniqueTest("S03") {
    private val titles = mapOf(
        "good-image-excluded" to "Decorative image excluded",
        "good-icon-no-label" to "Icons that repeat the text beside them",
        "good-background-image" to "Decoration painted as a background",
        "good-exclude-semantics" to "Avatar hidden with ExcludeSemantics",
        "good-merged-row" to "Decorative picture excluded from a merged row",
        "bad-not-excluded" to "Decorative image left in the tree",
        "bad-empty-label" to "Empty label used to hide an image",
        "bad-redundant-label" to "Decorative icons that repeat the text",
        "bad-merged-image" to "Decorative picture merged into a row",
    )

    // Waits for this example's own title, then for the photo, which is
    // decoded after the first frame.
    private fun open(slug: String) =
        openExample(slug, By.desc(titles.getValue(slug)), settleMillis = 500)

    private fun names(): List<String> = all().map { it.name() }

    /**
     * The names of the example's own nodes: those below the "Example"
     * heading on the screen, top to bottom.
     */
    private fun example(): List<String> {
        val bounds = android.graphics.Rect()
        named("Example").getBoundsInScreen(bounds)
        val top = bounds.bottom
        return all().filter { it.name().isNotEmpty() }
            .map { n -> android.graphics.Rect().also { n.getBoundsInScreen(it) } to n.name() }
            .filter { it.first.top >= top }
            .sortedBy { it.first.top }
            .map { it.second }
    }

    private fun images(): List<AccessibilityNodeInfo> = all().filter { it.className?.toString() == IMAGE }

    @Test
    fun goodImageExcludedExposesOnlyTheText() {
        open("good-image-excluded")
        assertEquals(0, images().size)
        assertEquals(listOf("Welcome back, Ana.", "You have 2 new messages."), example())
    }

    @Test
    fun goodIconNoLabelExposesOnlyTheWords() {
        open("good-icon-no-label")
        assertEquals(0, images().size)
        assertEquals(listOf("Shipping", "Returns", DELIVERY), example())
    }

    @Test
    fun goodBackgroundImageExposesOnlyTheText() {
        open("good-background-image")
        assertEquals(0, images().size)
        assertEquals(listOf("Welcome back, Ana.", "You have 2 new messages."), example())
    }

    @Test
    fun goodExcludeSemanticsExposesOnlyTheName() {
        open("good-exclude-semantics")
        assertEquals(listOf("Ana Kovac"), example())
    }

    @Test
    fun goodMergedRowIsNotAnImage() {
        open("good-merged-row")
        assertEquals(0, images().size)
        assertEquals(listOf("Trail guide\n12 routes"), example())
    }

    // VAL-3: each bad example is asserted to have its named defect.

    private fun assertBannerIsAnUnnamedImage(slug: String) {
        open(slug)
        val image = images().single()
        assertEquals("", image.name())
        assertTrue(image.text.isNullOrEmpty())
        // Seen on Android 17: the node is not focusable. Whether TalkBack's
        // swipe stops on it could not be automated (see the spec).
        assertEquals(false, image.isFocusable)
        assertEquals(listOf("Welcome back, Ana.", "You have 2 new messages."), example())
    }

    @Test
    fun badNotExcludedIsAnUnnamedImage() = assertBannerIsAnUnnamedImage("bad-not-excluded")

    @Test
    fun badEmptyLabelIsAnUnnamedImage() = assertBannerIsAnUnnamedImage("bad-empty-label")

    @Test
    fun badRedundantLabelExposesEveryWordTwice() {
        open("bad-redundant-label")
        // Each icon and its word share a line, so their order is not fixed
        // by position; the names are compared as a sorted list.
        assertEquals(listOf(DELIVERY, "Returns", "Returns", "Shipping", "Shipping"),
            example().sorted())
    }

    @Test
    fun badMergedImageRowIsAnImage() {
        open("bad-merged-image")
        assertEquals(listOf("Trail guide\n12 routes"), images().map { it.name() })
    }

    /**
     * L4. Moves TalkBack focus to each listed element and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running. Focus is moved by action, so the walk shows what is read
     * on an element, not which elements a swipe stops on.
     */
    @Test
    fun talkBackWalk() {
        val banner = listOf("first" to "Welcome back, Ana.", "second" to "You have 2 new messages.")
        // slug -> (key suffix, description of the element)
        val walk = listOf(
            "good-image-excluded" to banner,
            "good-icon-no-label" to listOf("shipping" to "Shipping", "returns" to "Returns"),
            "good-background-image" to banner,
            "good-exclude-semantics" to listOf("name" to "Ana Kovac"),
            "good-merged-row" to listOf("row" to "Trail guide\n12 routes"),
            // The banner has no name, so it is found by its class (UNNAMED_IMAGE).
            "bad-not-excluded" to listOf("banner" to UNNAMED_IMAGE),
            "bad-empty-label" to listOf("banner" to UNNAMED_IMAGE),
            // Two nodes are named "Shipping": the icon, then the word.
            "bad-redundant-label" to listOf("icon" to "Shipping#0", "word" to "Shipping#1"),
            "bad-merged-image" to listOf("row" to "Trail guide\n12 routes"),
        )
        talkBackWalk(
            walk.map { (slug, elements) ->
                slug to elements.map { (key, text) ->
                    Stop("s03-$slug-$key") {
                        when {
                            text == UNNAMED_IMAGE -> images().single()
                            text.contains('#') -> {
                                val (name, index) = text.split('#')
                                val found = all().filter { it.name() == name }
                                assertEquals("nodes named \"$name\"", 2, found.size)
                                found[index.toInt()]
                            }
                            else -> named(text)
                        }
                    }
                }
            },
            open = ::open,
            dwellMillis = { 8_000 })
    }
}
