// L3 (tree) and L4 (TalkBack walk) for S03 Decorative images on Android.
// Spec: docs/specs/S03-decorative-images.md.
//
// Images have no controls to identify, so nodes are found by their
// description, or by their class when they have none.
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
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val IMAGE = "android.widget.ImageView"

/** Stands for "the one image node on the screen" in the TalkBack walk. */
private const val UNNAMED_IMAGE = "\u0000image"

private const val DELIVERY = "Delivery takes 2 to 4 days."

@RunWith(AndroidJUnit4::class)
class S03DecorativeImagesTest {
    private val inst = InstrumentationRegistry.getInstrumentation()

    // Without this flag a connected test switches TalkBack off.
    private val automation: UiAutomation = run {
        Configurator.getInstance().setUiAutomationFlags(
            UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        inst.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
    }
    private val device: UiDevice = UiDevice.getInstance(inst)

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

    private fun open(slug: String) {
        val intent = Intent(inst.targetContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            .putExtra("route", "/t/S03/$slug")
        inst.targetContext.startActivity(intent)
        // Wait for this example's own title. A text every example screen has
        // would also match the previous screen while the new one loads.
        assertTrue("example $slug did not open",
            device.wait(Until.hasObject(By.desc(titles.getValue(slug))), 20_000))
        device.waitForIdle()
        // The photo is decoded after the first frame.
        Thread.sleep(500)
    }

    private fun collect(root: AccessibilityNodeInfo?, out: MutableList<AccessibilityNodeInfo>) {
        if (root == null) return
        out.add(root)
        for (i in 0 until root.childCount) collect(root.getChild(i), out)
    }

    private fun all(): List<AccessibilityNodeInfo> =
        mutableListOf<AccessibilityNodeInfo>().also { collect(automation.rootInActiveWindow, it) }

    private fun AccessibilityNodeInfo.name(): String = contentDescription?.toString().orEmpty()

    private fun names(): List<String> = all().map { it.name() }

    private fun node(text: String): AccessibilityNodeInfo =
        all().firstOrNull { it.name() == text } ?: throw AssertionError("no node named \"$text\"")

    /**
     * The names of the example's own nodes: those below the "Example"
     * heading on the screen, top to bottom.
     */
    private fun example(): List<String> {
        val bounds = android.graphics.Rect()
        node("Example").getBoundsInScreen(bounds)
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

    /**
     * L4. Moves TalkBack focus to each listed element and logs markers;
     * tool/talkback.py reads the speech from logcat. Skipped unless TalkBack
     * is running. Focus is moved by action, so the walk shows what is read
     * on an element, not which elements a swipe stops on.
     */
    @Test
    fun talkBackWalk() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
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
        for ((slug, elements) in walk) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for ((key, text) in elements) {
                Log.i("S03TB", "FOCUS s03-$slug-$key")
                talkBackFocus("s03-$slug-$key") {
                    when {
                        text == UNNAMED_IMAGE -> images().single()
                        text.contains('#') -> {
                            val (name, index) = text.split('#')
                            val found = all().filter { it.name() == name }
                            assertEquals("nodes named \"$name\"", 2, found.size)
                            found[index.toInt()]
                        }
                        else -> node(text)
                    }
                }
                Thread.sleep(8_000)
            }
            Log.i("S03TB", "END $slug")
        }
    }
}
