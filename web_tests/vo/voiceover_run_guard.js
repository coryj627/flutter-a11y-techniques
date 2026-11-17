// A VoiceOver run takes over the Mac: it turns VoiceOver on, speaks aloud,
// and drives the keyboard and mouse. It must only ever start from
// `python3 tool/voiceover_web.py <ID>`, which sets this variable. Every spec
// in this folder imports vo_helpers.js, which imports this file first, so
// without the variable no spec here loads, whatever command or config is
// used. web_tests/check_spec_selection.js checks that this stays true.
if (process.env.FLUTTER_A11Y_VOICEOVER_RUN !== '1') {
  throw new Error(
    'Refusing to load a VoiceOver spec: it would take over this Mac. ' +
    'Run python3 tool/voiceover_web.py <ID> instead.');
}
