// What every technique's L3 and L4 test class on Android shares: opening an
// example, finding nodes, and moving TalkBack focus. A technique's class
// extends TechniqueTest with its id, for example C01ButtonTest.
package dev.fluttera11y.flutter_a11y_techniques

import android.app.UiAutomation
import android.content.Intent
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.BySelector
import androidx.test.uiautomator.Configurator
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue

private const val BUTTON = "android.widget.Button"

/** The node's content description, which TalkBack reads as its name; "" if it has none. */
internal fun AccessibilityNodeInfo.name(): String = contentDescription?.toString().orEmpty()

/** The node's class name, such as android.widget.Button; "" if it has none. */
internal fun AccessibilityNodeInfo.type(): String = className?.toString().orEmpty()

internal fun AccessibilityNodeInfo.hasClickAction(): Boolean =
    actionList.any { it.id == AccessibilityNodeInfo.ACTION_CLICK }

/** The base of a technique's test class. [technique] is its id, as in the app's routes: "C01". */
abstract class TechniqueTest(private val technique: String) {
    protected val inst = InstrumentationRegistry.getInstrumentation()

    // Without this flag a connected test switches TalkBack off.
    protected val automation: UiAutomation = run {
        Configurator.getInstance().setUiAutomationFlags(
            UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        inst.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
    }
    protected val device: UiDevice = UiDevice.getInstance(inst)

    /** The tag of the TalkBack walk's log markers, which tool/talkback.py reads: "C01TB". */
    protected val talkBackTag = "${technique}TB"

    private fun launch(slug: String) {
        val intent = Intent(inst.targetContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            .putExtra("route", "/t/$technique/$slug")
        inst.targetContext.startActivity(intent)
    }

    /**
     * Starts the app on the example [slug] and waits up to 20 seconds for a
     * node that [waitFor] matches. Wait for something only this example has,
     * such as its own title or its count: a text every example screen has
     * would also match the previous screen while the new one loads. Then
     * waits for the app to be idle, unless [idle] is false, and for
     * [settleMillis] more.
     */
    protected fun openExample(slug: String, waitFor: BySelector, idle: Boolean = true, settleMillis: Long = 0) {
        launch(slug)
        assertTrue("example $slug did not open", waitScrollingDown(waitFor, 20_000))
        if (idle) device.waitForIdle()
        if (settleMillis > 0) Thread.sleep(settleMillis)
    }

    /**
     * Waits up to [timeoutMillis] for a node that [selector] finds. A node
     * scrolled out of view is not in the tree, and what an example is waited
     * for by is often its count, its last element: a custom solution's note
     * above the example (docs/custom-solutions.md) takes about half of CI's
     * 320 by 640 screen and leaves the count below the view. So once the
     * screen is up and the node is not there, the screen is scrolled down a
     * step at a time, as a person scrolls to it. Where the node is in view
     * from the start, as on a large screen, nothing is scrolled.
     */
    private fun waitScrollingDown(selector: BySelector, timeoutMillis: Long): Boolean {
        val end = System.currentTimeMillis() + timeoutMillis
        while (System.currentTimeMillis() < end) {
            if (device.wait(Until.hasObject(selector), 1_000)) return true
            val view = first(automation.rootInActiveWindow) { it.isScrollable }
            if (view != null && view.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) {
                device.waitForIdle()
            }
        }
        return device.hasObject(selector)
    }

    /**
     * Starts the app on the example [slug] and waits up to 20 seconds for a
     * node, in any window, that [match] accepts; then for the app to be idle.
     * With TalkBack running a system dialog can be the active window while
     * the app is on screen behind it.
     */
    protected fun openExampleInAnyWindow(slug: String, match: (AccessibilityNodeInfo) -> Boolean) {
        launch(slug)
        val end = System.currentTimeMillis() + 20_000
        while (!anyWindowHas(match)) {
            assertTrue("example $slug did not open", System.currentTimeMillis() < end)
            Thread.sleep(250)
        }
        device.waitForIdle()
    }

    private fun collect(root: AccessibilityNodeInfo?, out: MutableList<AccessibilityNodeInfo>) {
        if (root == null) return
        out.add(root)
        for (i in 0 until root.childCount) collect(root.getChild(i), out)
    }

    /** Every node of the active window, depth first. */
    protected fun all(): List<AccessibilityNodeInfo> =
        mutableListOf<AccessibilityNodeInfo>().also { collect(automation.rootInActiveWindow, it) }

    /** The first node, depth first from [root], that [match] accepts. */
    private fun first(root: AccessibilityNodeInfo?, match: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo? {
        if (root == null) return null
        if (match(root)) return root
        for (i in 0 until root.childCount) first(root.getChild(i), match)?.let { return it }
        return null
    }

    /**
     * The first node of the active window with the test identifier [id].
     * If it is not in the tree, the screen is scrolled to it, as [revealed]
     * does: a node out of view is not in the tree, and below a custom
     * solution's note (docs/custom-solutions.md) on CI's 320 by 640 emulator,
     * more so with the soft keyboard up, much of an example is out of view.
     * A node that is there is returned at once, with nothing scrolled.
     */
    protected fun node(id: String): AccessibilityNodeInfo = revealed(id)

    /** The first node of the active window whose name is [name]. */
    protected fun named(name: String): AccessibilityNodeInfo =
        first(automation.rootInActiveWindow) { it.name() == name }
            ?: throw AssertionError("no node named \"$name\"")

    /** The nodes of the example with the button class: every one but Back. */
    protected fun buttons(): List<AccessibilityNodeInfo> =
        all().filter { it.type() == BUTTON && it.name() != "Back" }

    /**
     * The node of the active window with the test identifier [id], scrolling
     * the screen to it if it is not in the tree: forward first, then back.
     * A node scrolled out of view is not in the tree, and on CI's 320 by 640
     * emulator an example can be taller than the screen, more so with the
     * soft keyboard up. Scrolling moves no keyboard focus. Nothing is
     * scrolled when the node is already there.
     */
    protected fun revealed(id: String): AccessibilityNodeInfo {
        fun find() = first(automation.rootInActiveWindow) { it.viewIdResourceName == id }
        find()?.let { return it }
        for (action in listOf(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD, AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD)) {
            for (i in 0 until 8) {
                val view = first(automation.rootInActiveWindow) { it.isScrollable } ?: break
                if (!view.performAction(action)) break
                Thread.sleep(500)
                find()?.let { return it }
            }
        }
        throw AssertionError("no node with id $id, even after scrolling")
    }

    /**
     * Scrolls the screen to its end, as a person scrolls down to an example
     * whose lines above it (its title, what it is, and for a custom solution
     * its note, docs/custom-solutions.md) push it below the view: on CI's
     * 320 by 640 emulator the note alone can take half the screen. Moves no
     * keyboard focus; does nothing on a screen that does not scroll. Waits
     * for the screen to settle, so bounds read afterwards are current.
     */
    protected fun scrollToEnd() {
        for (i in 0 until 8) {
            val view = first(automation.rootInActiveWindow) { it.isScrollable } ?: break
            if (!view.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) break
            Thread.sleep(500)
        }
        device.waitForIdle()
    }

    /**
     * The number at the end of the example's count, "Activations: 2" or
     * "Changes: 2". The count is the last thing in an example, so it is the
     * node most often out of view: it is scrolled to if it has to be.
     */
    protected fun count(slug: String): Int =
        revealed("${technique.lowercase()}-$slug-count").name().substringAfter(": ").toInt()

    /** What a failure message of [waitForCount] calls the count. */
    protected open val countName: String get() = "activation count"

    /** Waits up to 5 seconds for the count of [slug] to be [expected]. */
    protected fun waitForCount(slug: String, expected: Int) {
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && count(slug) != expected) Thread.sleep(100)
        assertEquals("$countName for $slug", expected, count(slug))
    }

    /** The text in a field; an empty EditText reports its hint as its text. */
    protected fun value(id: String): String = node(id).let {
        if (it.isShowingHintText) "" else it.text?.toString().orEmpty()
    }

    /** Types into the field the way a person does: focus it, then key by key. */
    protected fun type(id: String, text: String) {
        assertTrue("$id click", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        Thread.sleep(1_000)
        inst.sendStringSync(text)
        val end = System.currentTimeMillis() + 5_000
        while (System.currentTimeMillis() < end && value(id) != text) Thread.sleep(100)
        assertEquals("$id value", text, value(id))
        // Give the rest of the field's semantics time to follow the value.
        Thread.sleep(1_500)
    }

    // With TalkBack running, a system dialog or TalkBack's own overlay can be
    // the active window for a moment, so the active window alone is not a
    // reliable place to look. These look in every window.

    /** Whether a node in any window, the active one first, is accepted by [match]. */
    protected fun anyWindowHas(match: (AccessibilityNodeInfo) -> Boolean): Boolean =
        first(automation.rootInActiveWindow, match) != null ||
            automation.windows.any { first(it.root, match) != null }

    /**
     * Finds a node by test identifier, looking in every window and waiting a
     * few seconds.
     */
    protected fun nodeInAnyWindow(id: String): AccessibilityNodeInfo {
        val end = System.currentTimeMillis() + 8_000
        while (true) {
            first(automation.rootInActiveWindow) { it.viewIdResourceName == id }?.let { return it }
            for (window in automation.windows) {
                first(window.root) { it.viewIdResourceName == id }?.let { return it }
            }
            if (System.currentTimeMillis() > end) {
                throw AssertionError("no node with id $id; on screen: ${describeScreen()}")
            }
            Thread.sleep(250)
        }
    }

    /** Identifiers and texts in every window, for a failure message. */
    private fun describeScreen(): String {
        val seen = mutableListOf<String>()
        fun walk(n: AccessibilityNodeInfo?) {
            if (n == null) return
            val label = n.viewIdResourceName ?: n.contentDescription?.toString()
            if (!label.isNullOrEmpty()) seen.add(label.take(40))
            for (i in 0 until n.childCount) walk(n.getChild(i))
        }
        automation.windows.forEach { seen.add("[window ${it.title}]"); walk(it.root) }
        return seen.joinToString(" | ")
    }

    /** Skips the test unless TalkBack is running. */
    protected fun assumeTalkBack() {
        val services = Settings.Secure.getString(
            inst.targetContext.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES).orEmpty()
        assumeTrue("TalkBack is not enabled", services.contains("talkback", ignoreCase = true))
    }

    /**
     * Moves TalkBack focus to the node [find] returns and fails the test if
     * it cannot. A node that already has accessibility focus refuses the
     * action, so focus is cleared and the action tried once more. Without
     * this check a failed focus would pass silently and the transcript would
     * credit the wrong speech to the element.
     */
    protected fun talkBackFocus(what: String, find: () -> AccessibilityNodeInfo) {
        if (find().performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)) return
        find().performAction(AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS)
        Thread.sleep(500)
        assertTrue("TalkBack focus on $what",
            find().performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS))
    }

    /**
     * One stop of a TalkBack walk: [before] runs first, then [marker] is
     * logged and TalkBack focus moves to the node [find] returns.
     */
    protected class Stop(val marker: String, val before: () -> Unit = {}, val find: () -> AccessibilityNodeInfo)

    /**
     * L4. Skips unless TalkBack is running. For each (slug, stops) of [walk]:
     * opens the example with [open], lets TalkBack finish announcing the new
     * screen, and for each stop runs its `before`, logs "FOCUS marker",
     * moves TalkBack focus, and waits [dwellMillis] for the speech; then logs
     * "END slug". tool/talkback.py reads the speech between the markers from
     * logcat.
     */
    protected fun talkBackWalk(
        walk: List<Pair<String, List<Stop>>>,
        open: (String) -> Unit,
        dwellMillis: (slug: String) -> Long,
    ) {
        assumeTalkBack()
        for ((slug, stops) in walk) {
            open(slug)
            // Let TalkBack finish announcing the new screen first.
            Thread.sleep(8_000)
            for (stop in stops) {
                stop.before()
                Log.i(talkBackTag, "FOCUS ${stop.marker}")
                talkBackFocus(stop.marker, stop.find)
                Thread.sleep(dwellMillis(slug))
            }
            Log.i(talkBackTag, "END $slug")
        }
    }
}
