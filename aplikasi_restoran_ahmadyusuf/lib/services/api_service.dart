import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Error dari server / jaringan dengan pesan yang siap ditampilkan ke pengguna.
class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Pembungkus HTTP: menambahkan header + token, mengubah JSON, dan
/// menerjemahkan error Laravel (401/403/422/...) menjadi [ApiException].
class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String baseUrl;

  /// Token Sanctum; diisi AuthController setelah login.
  String? token;

  /// Dipanggil saat server menjawab 401 padahal kita punya token (sesi habis).
  void Function()? onUnauthorized;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _kirim(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _kirim(() =>
      _client.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, [Object? body]) => _kirim(() =>
      _client.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, [Object? body]) => _kirim(() =>
      _client.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _kirim(() => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _kirim(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException(
          'Tidak bisa terhubung ke server. Periksa koneksi internet lalu coba lagi.');
    }

    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    if (res.statusCode == 401 && token != null) onUnauthorized?.call();
    throw ApiException(_pesanError(body, res.statusCode), res.statusCode);
  }

  /// Ambil pesan paling berguna dari jawaban error Laravel.
  String _pesanError(dynamic body, int status) {
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
        return '$first';
      }
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (status >= 500) return 'Server sedang bermasalah (kode $status).';
    return 'Terjadi kesalahan (kode $status).';
  }
}
