import 'dart:convert';
import 'dart:io';

/// Mobil ve masaustu icin HTTP gonderici.
class HttpAdapter {
  HttpAdapter({this.timeout = const Duration(seconds: 8)});

  final Duration timeout;
  final HttpClient _client = HttpClient();

  Future<String> send(
    Uri uri, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final request = method == 'GET'
        ? await _client.getUrl(uri).timeout(timeout)
        : await _client.postUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(timeout);
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return text;
  }

  void close() => _client.close(force: true);
}
