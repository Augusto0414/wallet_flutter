import 'package:intl/intl.dart';

enum MovementType { DEPOSIT, DEBIT }

enum MovementStatus { CREATED, COMPLETED, FAILED }

class Movement {
  final String id;
  final String userId;
  final String walletId;
  final MovementType type;
  final double amount;
  final double cost;
  final MovementStatus status;
  final DateTime? processedAt;
  final String? reason;

  Movement({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.cost,
    required this.status,
    this.processedAt,
    this.reason,
  });

  Movement copyWith({
    MovementStatus? status,
    DateTime? processedAt,
    String? reason,
  }) {
    return Movement(
      id: id,
      userId: userId,
      walletId: walletId,
      type: type,
      amount: amount,
      cost: cost,
      status: status ?? this.status,
      processedAt: processedAt ?? this.processedAt,
      reason: reason ?? this.reason,
    );
  }

  String get formattedAmount =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);

  String get formattedCost =>
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(cost);

  String get formattedDate => processedAt != null
      ? DateFormat('MMM dd, yyyy HH:mm').format(processedAt!)
      : 'Pending';

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      type: MovementType.values.firstWhere(
        (e) => e.name == json['type']?.toString(),
        orElse: () => MovementType.DEPOSIT,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      status: MovementStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => MovementStatus.CREATED,
      ),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'].toString())
          : null,
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'type': type.name,
      'amount': amount,
      'cost': cost,
      'status': status.name,
    };
    if (processedAt != null) {
      json['processedAt'] = processedAt!.toIso8601String();
    }
    if (reason != null) {
      json['reason'] = reason;
    }
    return json;
  }
}
