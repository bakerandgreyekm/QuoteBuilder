import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

@JS('SpeechRecognition')
extension type _SpeechRecognition._(JSObject _) implements JSObject {
  external factory _SpeechRecognition();
  external set lang(String v);
  external set continuous(bool v);
  external set interimResults(bool v);
  external set onresult(JSFunction? v);
  external set onerror(JSFunction? v);
  external set onend(JSFunction? v);
  external void start();
  external void stop();
}

bool get speechRecognitionSupported =>
    kIsWeb && globalContext.has('SpeechRecognition');

class SpeechRecognitionHelper {
  _SpeechRecognition? _rec;

  void start(
    String langCode,
    void Function(String) onTranscript,
    void Function() onEnd,
  ) {
    if (!speechRecognitionSupported) {
      onEnd();
      return;
    }
    _rec = _SpeechRecognition();
    _rec!.lang = langCode;
    _rec!.continuous = false;
    _rec!.interimResults = false;

    _rec!.onresult = ((JSAny? event) {
      if (event == null) return;
      try {
        final ev = event as JSObject;
        final results = ev.getProperty<JSObject>('results'.toJS);
        final first = results.getProperty<JSObject>(0.toJS);
        final alt = first.getProperty<JSObject>(0.toJS);
        final transcript =
            alt.getProperty<JSString>('transcript'.toJS).toDart;
        if (transcript.isNotEmpty) onTranscript(transcript);
      } catch (_) {}
    }).toJS;

    _rec!.onerror = ((JSAny? _) => onEnd()).toJS;
    _rec!.onend = ((JSAny? _) => onEnd()).toJS;

    _rec!.start();
  }

  void stop() => _rec?.stop();
}
