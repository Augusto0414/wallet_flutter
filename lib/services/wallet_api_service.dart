import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/movement.dart';

class WalletApiService {
  static String get _baseUrl =>
      dotenv.get('API_URL', fallback: 'http://127.0.0.1:3000');

  final http.Client _client;

  WalletApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> createMovement(Movement movement) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/wallet-movements'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(movement.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> sendWebhook({
    required String eventId,
    required String movementId,
    required MovementType type,
    required double amount,
    required double cost,
    required MovementStatus status,
    DateTime? processedAt,
    String? reason,
  }) async {
    final body = {
      'eventId': eventId,
      'movementId': movementId,
      'type': type.name,
      'amount': amount,
      'cost': cost,
      'status': status.name,
      'processedAt': (processedAt ?? DateTime.now()).toIso8601String(),
      'reason': reason,
    };

    final response = await _client.post(
      Uri.parse('$_baseUrl/wallet-movements/webhook'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Movement> getMovement(String movementId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/wallet-movements/$movementId'),
    );

    if (response.statusCode == 200) {
      return Movement.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> getWalletBalance(String walletId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/wallet-balances/$walletId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<List<Movement>> getMovements(String walletId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/wallet-movements/wallet/$walletId'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = (decoded['value'] ?? decoded['data'] ?? []) as List;
      } else {
        list = [];
      }
      return list.map((m) => Movement.fromJson(m)).toList();
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> getCompanyBalance() async {
    final response = await _client.get(Uri.parse('$_baseUrl/company-balance'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
