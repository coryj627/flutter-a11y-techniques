// L3 (tree) and L4 (TalkBack walk) for S02 Informative images on Android.
// Spec: docs/specs/S02-informative-images.md.
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
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val IMAGE = "android.widget.ImageView"

/** Stands for "the one image node on the screen" in the TalkBack walk. */
private const val UNNAMED_IMAGE = "\u0000image"

@RunWith(AndroidJUnit4::class)
class S02InformativeImagesTest {
    private val inst = InstrumentationRegistry.getInstrumentation()

    // Without this flag a connected test switches TalkBack off.
    private val automation: UiAutomation = run {
        Configurator.getInstance().setUiAutomationFlags(
            UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        inst.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
    }
    private val device: UiDevice = UiDevice.getInstance(inst)

    private val titles = mapOf(
        "good-image-label" to "Photo with a text alternative",
        "good-icon-label" to "Status icons with text alternatives",
        "good-group-description" to "Icon and text with one description",
        "good-chart" to "Chart with a short alternative and its data in text",
        "bad-no-label" to "Photo with no text alternative",
        "bad-icon-no-label" to "Status icons with no text alternatives",
        "bad-role-in-label" to "Role repeated in the text alternative",
        "bad-filename-label" to "File name as the text alternative",
    )

    private fun open(slug: String) {
        val intent = Intent(inst.targetContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            .putExtra("route", "/t/S02/$slug")
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

    private fun images(): List<AccessibilityNodeInfo> = all().filter { it.className?.toString() == IMAGE }

    @Test
    fun goodImageLabelIsANamedImage() {
        open("good-image-label")
        assertEquals(listOf("Sunrise over green hills"), images().map { it.name() })
        assertNotEquals(IMAGE, node("Taken from the east ridge trail.").className?.toString())
    }

    @Test
    fun goodIconLabelReadsStatusAndOrderAsOneNode() {
        open("good-icon-label")
        val names = names()
        assertTrue(names.contains("Delivered\nOrder 1042"))
        assertTrue(names.contains("Delayed\nOrder 1043"))
        // The status is not a second node, and the icon is not an unnamed image.
        assertTrue(names.none { it == "Delivered" || it == "Order 1042" })
        assertEquals(0, images().size)
    }

    @Test
    fun goodGroupDescriptionIsOneNode() {
        open("good-group-description")
        val names = names()
        assertEquals(1, names.count { it == "Sunrise at 6:35 am" })
        assertEquals(1, names.count { it.contains("6:35 am") })
    }

    @Test
    fun goodChartIsANamedImageWithItsDataInText() {
        open("good-chart")
        assertEquals(listOf("Bar chart: orders rose every quarter of 2025"), images().map { it.name() })
        assertNotEquals(IMAGE,
            node("Orders in 2025: Q1 20, Q2 35, Q3 50, Q4 80.").className?.toString())
    }

    // VAL-3: each bad example is asserted to have its named defect.

    @Test
    fun badNoLabelHasNoTextAlternative() {
        open("bad-no-label")
        // The photo is an image node with no description and no text, and
        // nothing else on the screen says what it shows.
        val image = images().single()
        assertEquals("", image.name())
        assertTrue(image.text.isNullOrEmpty())
        assertTrue(names().none { it.contains("sunrise", ignoreCase = true) })
    }

    @Test
    fun badIconNoLabelRowsAreOrderNumbersOnly() {
        open("bad-icon-no-label")
        val names = names()
        assertTrue(names.contains("Order 1042"))
        assertTrue(names.contains("Order 1043"))
        assertTrue(names.none { it.contains("Delivered") || it.contains("Delayed") })
    }

    @Test
    fun badRoleInLabelStartsWithRole() {
        open("bad-role-in-label")
        val image = images().single()
        assertTrue(image.name().startsWith("Image", ignoreCase = true))
    }

    @Test
    fun badFilenameLabelIsAFileName() {
        open("bad-filename-label")
        assertEquals("IMG_2041.png", images().single().name())
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
     * is running.
     */
    @Test
    fun talkBackWalk() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
        // slug -> (key suffix, description of the element)
        val walk = listOf(
            "good-image-label" to listOf("photo" to "Sunrise over green hills"),
            "good-icon-label" to listOf(
                "delivered" to "Delivered\nOrder 1042", "delayed" to "Delayed\nOrder 1043"),
            "good-group-description" to listOf("sunrise" to "Sunrise at 6:35 am"),
            "good-chart" to listOf(
                "chart" to "Bar chart: orders rose every quarter of 2025",
                "data" to "Orders in 2025: Q1 20, Q2 35, Q3 50, Q4 80."),
            // The photo has no name, so it is found by its class (UNNAMED_IMAGE).
            "bad-no-label" to listOf(
                "photo" to UNNAMED_IMAGE, "caption" to "Taken from the east ridge trail."),
            "bad-icon-no-label" to listOf("first" to "Order 1042", "second" to "Order 1043"),
            "bad-role-in-label" to listOf("photo" to "Image of a sunrise over green hills"),
            "bad-filename-label" to listOf("photo" to "IMG_2041.png"),
        )
        for ((slug, elements) in walk) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for ((key, text) in elements) {
                Log.i("S02TB", "FOCUS s02-$slug-$key")
                talkBackFocus("s02-$slug-$key") {
                    if (text == UNNAMED_IMAGE) images().single() else node(text)
                }
                Thread.sleep(8_000)
            }
            Log.i("S02TB", "END $slug")
        }
    }
}
