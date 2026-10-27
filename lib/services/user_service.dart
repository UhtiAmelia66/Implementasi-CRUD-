import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/user_model.dart';

/// Exception khusus dengan pesan yang siap ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UserService {
  static const _timeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': ApiConfig.apiKey,
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  /// Membungkus request dengan try-catch agar penanganan error seragam.
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on TimeoutException {
      throw ApiException('Permintaan terlalu lama (timeout). Coba lagi.');
    } on FormatException {
      throw ApiException('Format respons dari server tidak valid.');
    }
  }

  void _checkStatus(http.Response res, List<int> okCodes) {
    if (!okCodes.contains(res.statusCode)) {
      final hint = (res.statusCode == 401 || res.statusCode == 403)
          ? ' Periksa API key Anda.'
          : '';
      throw ApiException('Request gagal (status ${res.statusCode}).$hint');
    }
  }

  /// READ - GET /users?page=2
  Future<List<UserModel>> getUsers({int page = 2}) {
    return _guard(() async {
      final res = await http.get(_uri('/users?page=$page'), headers: _headers);
      _checkStatus(res, [200]);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>;
      return list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// CREATE - POST /users
  Future<UserModel> createUser({
    required String email,
    required String firstName,
    required String lastName,
    String avatar = '',
  }) {
    return _guard(() async {
      final res = await http.post(
        _uri('/users'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'avatar': avatar,
        }),
      );
      _checkStatus(res, [200, 201]);
      return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    });
  }

  /// UPDATE - PUT /users/{id}
  Future<UserModel> updateUser(UserModel user) {
    return _guard(() async {
      final res = await http.put(
        _uri('/users/${user.id}'),
        headers: _headers,
        body: jsonEncode(user.toJson()),
      );
      _checkStatus(res, [200]);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return UserModel.fromJson({...user.toJson(), ...body});
    });
  }

  /// DELETE - DELETE /users/{id}
  Future<void> deleteUser(int id) {
    return _guard(() async {
      final res = await http.delete(_uri('/users/$id'), headers: _headers);
      _checkStatus(res, [200, 204]);
    });
  }
}