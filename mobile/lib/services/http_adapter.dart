/// Platforma gore HTTP gonderici secer.
///
/// Mobil ve masaustunde `dart:io` kullanilir. Web'de tarayici ayni kaynak
/// olmayan `web_dialer.py` adresine istek atmayi (CORS) engelledigi icin
/// web surumu desteklenmez; uygulama ornek verilere duser.
library;

export 'http_adapter_io.dart'
    if (dart.library.js_interop) 'http_adapter_web.dart';
