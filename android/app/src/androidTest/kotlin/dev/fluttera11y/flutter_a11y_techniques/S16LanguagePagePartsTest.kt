// L3 (tree) and L4 (TalkBack walk) for S16 Language of page and parts on
// Android. Spec: docs/specs/S16-language-page-parts.md.
//
// The language reaches Android as a LocaleSpan on a node's content
// description: the app's language over every node's whole text, and a
// marked part's language over its range (the engine's AccessibilityBridge,
// read; measured in docs/evidence/probes/s16/android-tree.txt). Each node
// is read with its spans, sorted by where they start. Texts are found by
// their names; the language menus' tiles by their test identifiers.
package dev.fluttera11y.flutter_a11y_techniques

import android.text.Spanned
import android.text.style.LocaleSpan
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

private const val LEAD = "The sign at the door reads:"
private const val PASSAGE = "Bienvenue à tous nos visiteurs."
private const val SENTENCE = "The guide said bon voyage as we left."
private val LANGUAGES = listOf(
    Triple("fr", "Français", "French"),
    Triple("es", "Español", "Spanish"),
    Triple("de", "Deutsch", "German"),
)

@RunWith(AndroidJUnit4::class)
class S16LanguagePagePartsTest : TechniqueTest("S16") {
    private fun open(slug: String) = openExample(slug, By.desc(s16Titles.getValue(slug)), settleMillis = 300)

    /** Every node of the active window, in tree order. */
    private fun tree(): List<AccessibilityNodeInfo> {
        val out = mutableListOf<AccessibilityNodeInfo>()
        fun walk(n: AccessibilityNodeInfo?) {
            if (n == null) return
            out.add(n)
            for (i in 0 until n.childCount) walk(n.getChild(i))
        }
        walk(automation.rootInActiveWindow)
        return out
    }

    /**
     * The LocaleSpans on [n]'s content description, as "tag[start-end]",
     * sorted by start, then end: "fr[15-25] en-US[0-37]" is written
     * "en-US[0-37] fr[15-25]". "(no spans)" where the description is plain
     * text, "" where there is none.
     */
    private fun locales(n: AccessibilityNodeInfo): String {
        val d = n.contentDescription ?: return ""
        if (d !is Spanned) return "(no spans)"
        return d.getSpans(0, d.length, LocaleSpan::class.java)
            .sortedWith(compareBy({ d.getSpanStart(it) }, { d.getSpanEnd(it) }, { it.locales.toLanguageTags() }))
            .joinToString(" ") { "${it.locales.toLanguageTags()}[${d.getSpanStart(it)}-${d.getSpanEnd(it)}]" }
    }

    /** The one node named [name], with its class and its languages: `View "…" en-US[0-27]`. */
    private fun line(n: AccessibilityNodeInfo) =
        "${n.type().substringAfterLast('.')} \"${n.name()}\" ${locales(n)}".trimEnd()

    /**
     * The example's named nodes, one line each, after the "Example" heading
     * and up to the "Chosen" line or the end. The examples are short enough
     * for CI's 320 by 640 screen, so the screen is scrolled to its end first.
     */
    private fun exampleNodes(): List<String> {
        scrollToEnd()
        val all = tree()
        val start = all.indexOfFirst { it.name() == "Example" }
        assertTrue("the Example heading", start >= 0)
        val lines = mutableListOf<String>()
        for (n in all.drop(start + 1)) {
            if (n.name().startsWith("Chosen: ")) break
            if (n.name().isEmpty()) continue
            lines.add(line(n))
        }
        return lines
    }

    /** The one node of the screen named [name]. */
    private fun only(name: String): AccessibilityNodeInfo {
        val found = tree().filter { it.name() == name }
        assertEquals("nodes named \"$name\"", 1, found.size)
        return found.single()
    }

    /** The language of the whole of [text]'s node: `tag[0-length]` and nothing else. */
    private fun whole(tag: String, text: String) = "$tag[0-${text.length}]"

    /** The "Chosen" line under the language menu of [slug]. */
    private fun chosen(slug: String): String = revealed("s16-$slug-chosen").name()

    /**
     * Waits up to 10 seconds for the Chosen line of [slug] to say
     * [expected]. A miss is caught and read again: revealed() throws on one,
     * and right after a launch the screen being replaced can still be up.
     */
    private fun waitForChosen(slug: String, expected: String) {
        val end = System.currentTimeMillis() + 10_000
        var last = "(no Chosen line)"
        while (System.currentTimeMillis() < end) {
            last = try {
                chosen(slug)
            } catch (e: AssertionError) {
                "(no Chosen line)"
            }
            if (last == expected) return
            Thread.sleep(200)
        }
        assertEquals(slug, expected, last)
    }

    /** Presses a key on the emulator's keyboard and gives Flutter time to act (as in I01). */
    private fun key(name: String) {
        device.executeShellCommand("input keyevent KEYCODE_$name")
        Thread.sleep(600)
    }

    /** Tab until [id] has keyboard focus; the first Tab can be used up leaving touch mode. */
    private fun tabTo(id: String) {
        for (i in 0 until 8) {
            key("TAB")
            if (revealed(id).isFocused) return
        }
        throw AssertionError("Tab did not reach $id")
    }

    @Test
    fun theAppsLanguageIsEnglishOnEveryNodeOfEveryExampleButOverride() {
        // 3.1.1: the app's language, en-US, over the whole of the screen's
        // title and of the Example heading.
        for (slug in s16Titles.keys - "bad-override") {
            open(slug)
            val title = s16Titles.getValue(slug)
            assertEquals(slug, whole("en-US", title), locales(only(title)))
            assertEquals(slug, whole("en-US", "Example"), locales(only("Example")))
        }
    }

    @Test
    fun goodPassageIsFrenchAndTheLineBeforeItEnglish() {
        open("good-passage")
        assertEquals(
            listOf("View \"$LEAD\" ${whole("en-US", LEAD)}", "View \"$PASSAGE\" ${whole("fr", PASSAGE)}"),
            exampleNodes(),
        )
    }

    @Test
    fun goodPhraseIsFrenchOverThePhraseAlone() {
        open("good-phrase")
        val start = SENTENCE.indexOf("bon voyage")
        assertEquals(
            listOf("View \"$SENTENCE\" ${whole("en-US", SENTENCE)} fr[$start-${start + "bon voyage".length}]"),
            exampleNodes(),
        )
    }

    @Test
    fun goodLanguageMenuHasEachTileAButtonInItsOwnLanguage() {
        open("good-language-menu")
        assertEquals(LANGUAGES.map { (code, name) -> "Button \"$name\" ${whole(code, name)}" }, exampleNodes())
        assertEquals(whole("en-US", "Chosen: none"), locales(only("Chosen: none")))
    }

    @Test
    fun badUnmarkedIsEnglish() {
        open("bad-unmarked")
        assertEquals(
            listOf("View \"$LEAD\" ${whole("en-US", LEAD)}", "View \"$PASSAGE\" ${whole("en-US", PASSAGE)}"),
            exampleNodes(),
        )
    }

    @Test
    fun badTitleInTileHasEachTileInEnglish() {
        // FL-361: the language set inside the tile is lost.
        open("bad-title-in-tile")
        assertEquals(LANGUAGES.map { (_, name) -> "Button \"$name\" ${whole("en-US", name)}" }, exampleNodes())
    }

    @Test
    fun badRegionTagIsFrenchFranceOnAndroid() {
        // The defect is the web's (FL-020): Android is given fr-FR.
        open("bad-region-tag")
        assertEquals(
            listOf("View \"$LEAD\" ${whole("en-US", LEAD)}", "View \"$PASSAGE\" ${whole("fr-FR", PASSAGE)}"),
            exampleNodes(),
        )
    }

    @Test
    fun badOverrideMakesEveryNodeOfTheScreenFrench() {
        // FL-360: the app's language is now French, so every node is.
        open("bad-override")
        val title = s16Titles.getValue("bad-override")
        assertEquals(whole("fr", title), locales(only(title)))
        assertEquals(whole("fr", "Example"), locales(only("Example")))
        assertEquals(
            listOf("View \"$LEAD\" ${whole("fr", LEAD)}", "View \"$PASSAGE\" ${whole("fr", PASSAGE)}"),
            exampleNodes(),
        )
    }

    /** Presses Back and waits for the technique's page, with no Example heading. */
    private fun backToTheTechnique() {
        device.pressBack()
        val end = System.currentTimeMillis() + 20_000
        while (System.currentTimeMillis() < end) {
            val nodes = tree()
            if (nodes.any { it.name() == "Good examples" } && nodes.none { it.name() == "Example" }) return
            Thread.sleep(250)
        }
        throw AssertionError("Back did not reach the technique's page")
    }

    @Test
    fun afterBackFromOverrideTheTechniquesPageIsFrenchAndFromPassageEnglish() {
        // FL-360: nothing sets the app's language back when the screen
        // closes. The witness that Back took effect is the technique's page
        // on the screen with no Example heading; good-passage is the
        // control, which shows that the test sees the language go back.
        for ((slug, tag) in listOf("bad-override" to "fr", "good-passage" to "en-US")) {
            open(slug)
            backToTheTechnique()
            assertEquals(slug, whole(tag, "Good examples"), locales(only("Good examples")))
        }
    }

    @Test
    fun eachTileChoosesItsLanguageByTheClickActionATapAndTabThenEnter() {
        // In bad-title-in-tile this is the positive control: the tiles work,
        // and only their language is lost.
        for (slug in listOf("good-language-menu", "bad-title-in-tile")) {
            for ((code, _, english) in LANGUAGES) {
                val id = "s16-$slug-$code"
                // The click action: what TalkBack's double tap performs.
                open(slug)
                waitForChosen(slug, "Chosen: none")
                assertTrue("$id click action", node(id).performAction(AccessibilityNodeInfo.ACTION_CLICK))
                waitForChosen(slug, "Chosen: $english")
                // A tap at its centre.
                open(slug)
                waitForChosen(slug, "Chosen: none")
                val r = android.graphics.Rect().also { node(id).getBoundsInScreen(it) }
                assertTrue("$id tap", device.click(r.centerX(), r.centerY()))
                waitForChosen(slug, "Chosen: $english")
                // Tab, then Enter, sent once.
                open(slug)
                waitForChosen(slug, "Chosen: none")
                tabTo(id)
                key("ENTER")
                waitForChosen(slug, "Chosen: $english")
            }
        }
    }

    /**
     * L4. TalkBack focus moved to each text of each example, in order, and
     * to each tile of the language menus; tool/talkback.py reads what
     * TalkBack says. Skips unless TalkBack is running.
     */
    @Test
    fun talkBackWalk() {
        val byName = { marker: String, name: String -> Stop(marker) { all().single { it.name() == name } } }
        val byId = { marker: String, id: String -> Stop(marker) { node(id) } }
        val passage = { slug: String ->
            slug to listOf(byName("s16-$slug-lead", LEAD), byName("s16-$slug-passage", PASSAGE))
        }
        val menu = { slug: String ->
            slug to LANGUAGES.map { (code) -> byId("s16-$slug-$code", "s16-$slug-$code") } +
                byId("s16-$slug-chosen", "s16-$slug-chosen")
        }
        val walk: List<Pair<String, List<Stop>>> = listOf(
            passage("good-passage"),
            "good-phrase" to listOf(byName("s16-good-phrase-sentence", SENTENCE)),
            menu("good-language-menu"),
            passage("bad-unmarked"),
            menu("bad-title-in-tile"),
            passage("bad-region-tag"),
            passage("bad-override"),
        )
        talkBackWalk(walk, open = { slug -> open(slug); scrollToEnd() }, dwellMillis = { 5_000 })
    }
}

/** Each example's title, as the app shows it in the app bar. */
private val s16Titles = mapOf(
    "good-passage" to "Passage in another language",
    "good-phrase" to "Phrase in another language",
    "good-language-menu" to "Language menu",
    "bad-unmarked" to "Passage not marked",
    "bad-title-in-tile" to "Language set inside each tile",
    "bad-region-tag" to "Language with a country",
    "bad-override" to "Localizations.override",
)
