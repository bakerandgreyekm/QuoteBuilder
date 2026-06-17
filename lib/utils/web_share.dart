import 'dart:js_interop';
import 'dart:typed_data';

@JS('window.open')
external void _windowOpen(JSString url, JSString target);

void openUrl(String url) => _windowOpen(url.toJS, '_blank'.toJS);

@JS('_qbShare')
external JSPromise _qbShareJs(
  JSUint8Array bytes,
  JSString filename,
  JSString mimeType,
  JSString title,
);

Future<void> shareQuoteFile({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
  required String title,
}) =>
    _qbShareJs(
      bytes.toJS,
      filename.toJS,
      mimeType.toJS,
      title.toJS,
    ).toDart;
