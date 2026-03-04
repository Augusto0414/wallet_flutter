import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../models/movement.dart';
import '../services/wallet_api_service.dart';

class WalletProvider with ChangeNotifier {
  final List<Movement> _movements = [];
  double _balance = 0.0;
  final _uuid = const Uuid();
  final WalletApiService _apiService;
  bool _isLoading = false;
  String? _errorMessage, _successMessage;

  WalletProvider({WalletApiService? apiService})
    : _apiService = apiService ?? WalletApiService();

  List<Movement> get movements => List.unmodifiable(_movements);
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get _currentUserId => dotenv.get('USER_ID', fallback: 'usr-001');
  String get _currentWalletId => dotenv.get('WALLET_ID', fallback: 'wal-001');

  double get totalIncome => _movements
      .where(
        (m) =>
            m.type == MovementType.DEPOSIT &&
            m.status == MovementStatus.COMPLETED,
      )
      .fold(0.0, (s, m) => s + m.amount);
  double get totalExpenses => _movements
      .where((m) => m.status == MovementStatus.COMPLETED)
      .fold(
        0.0,
        (s, m) => s + m.cost + (m.type == MovementType.DEBIT ? m.amount : 0.0),
      );

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchWalletBalance() async {
    try {
      final res = await _apiService.getWalletBalance(_currentWalletId);
      if (res['balance'] != null) {
        _balance = (res['balance'] as num).toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> fetchMovements() async {
    _setLoading(true);
    try {
      final list = await _apiService.getMovements(_currentWalletId);
      _movements
        ..clear()
        ..addAll(list.reversed);
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<Movement?> fetchMovement(String movementId) async {
    try {
      final movement = await _apiService.getMovement(movementId);
      final index = _movements.indexWhere((m) => m.id == movementId);
      if (index != -1) {
        _movements[index] = movement;
      } else {
        _movements.insert(0, movement);
      }
      notifyListeners();
      return movement;
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> createMovement({
    required MovementType type,
    required double amount,
    required double cost,
  }) async {
    _setLoading(true);
    final m = Movement(
      id: 'mov-${type.name.toLowerCase()}-${_uuid.v4().substring(0, 8)}',
      userId: _currentUserId,
      walletId: _currentWalletId,
      type: type,
      amount: amount,
      cost: cost,
      status: MovementStatus.CREATED,
    );
    try {
      final res = await _apiService.createMovement(m);
      _movements.insert(
        0,
        res.containsKey('movement') ? Movement.fromJson(res['movement']) : m,
      );
      _successMessage =
          '${type == MovementType.DEPOSIT ? 'Depósito' : 'Retiro'} creado';
      await fetchWalletBalance();
      return true;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> processWebhook({
    required String movementId,
    required MovementStatus status,
    String? reason,
  }) async {
    final idx = _movements.indexWhere((m) => m.id == movementId);
    if (idx == -1) return false;
    _setLoading(true);
    final m = _movements[idx];
    try {
      await _apiService.sendWebhook(
        eventId: 'evt-${_uuid.v4().substring(0, 8)}',
        movementId: movementId,
        type: m.type,
        amount: m.amount,
        cost: m.cost,
        status: status,
        processedAt: DateTime.now(),
        reason: reason,
      );
      _movements[idx] = m.copyWith(
        status: status,
        processedAt: DateTime.now(),
        reason: reason,
      );
      _successMessage = 'Procesado';
      await fetchWalletBalance();
      return true;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    _errorMessage = _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
