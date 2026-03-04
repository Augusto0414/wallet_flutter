import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movement.dart';
import '../providers/wallet_provider.dart';

class MovementTile extends StatelessWidget {
  final Movement movement;

  const MovementTile({super.key, required this.movement});

  @override
  Widget build(BuildContext context) {
    final isDeposit = movement.type == MovementType.DEPOSIT;
    final color = _getStatusColor(movement.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDeposit ? Colors.green : Colors.redAccent).withOpacity(
              0.1,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isDeposit ? Colors.green : Colors.redAccent,
            size: 20,
          ),
        ),
        title: Text(
          isDeposit ? 'Deposit' : 'Debit',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          movement.id.length > 8 ? movement.id.substring(0, 8) : movement.id,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDeposit ? "+" : "-"}${movement.formattedAmount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDeposit ? Colors.green : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                movement.status.name,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow('Status', movement.status.name, color),
                _buildDetailRow(
                  'Amount',
                  movement.formattedAmount,
                  Colors.white,
                ),
                _buildDetailRow(
                  'Cost/Fee',
                  movement.formattedCost,
                  Colors.white70,
                ),
                _buildDetailRow('Date', movement.formattedDate, Colors.white70),
                if (movement.reason != null)
                  _buildDetailRow(
                    'Reason',
                    movement.reason!,
                    Colors.orangeAccent,
                  ),
                const SizedBox(height: 16),
                if (movement.status == MovementStatus.CREATED)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await context.read<WalletProvider>().processWebhook(
                            movementId: movement.id,
                            status: MovementStatus.COMPLETED,
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.2),
                          foregroundColor: Colors.green,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await context.read<WalletProvider>().processWebhook(
                            movementId: movement.id,
                            status: MovementStatus.FAILED,
                            reason: isDeposit
                                ? "DEPOSIT_REJECTED"
                                : "INSUFFICIENT_FUNDS",
                          );
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Fail'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MovementStatus status) {
    switch (status) {
      case MovementStatus.CREATED:
        return Colors.blueAccent;
      case MovementStatus.COMPLETED:
        return Colors.green;
      case MovementStatus.FAILED:
        return Colors.redAccent;
    }
  }
}
