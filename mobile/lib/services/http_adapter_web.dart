/// Web surumu: tarayicidan yerel sunucuya dogrudan istek atilamaz (CORS).
/// Bu nedenle istekler desteklenmez ve uygulama ornek verilerle calisir.
class HttpAdapter {
  HttpAdapter({this.timeout = const Duration(seconds: 8)});

  final Duration timeout;

  Future<String> send(
    Uri uri, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    throw UnsupportedError(
      'Web surumunde sunucu baglantisi kullanilamaz. '
      'Gercek verileri gormek icin uygulamayi telefonda calistirin.',
    );
  }

  void close() {}
}
