import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movement.dart';
import '../providers/wallet_provider.dart';
import '../widgets/movement_tile.dart';

class MovementsScreen extends StatelessWidget {
  const MovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movements = context.watch<WalletProvider>().movements;
    final isLoading = context.watch<WalletProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Movimientos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: movements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay movimientos aún',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea un depósito o retiro para comenzar',
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // Could refresh movements from server in the future
                await context.read<WalletProvider>().fetchWalletBalance();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: movements.length + 1, // +1 for summary header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSummaryHeader(context, movements);
                  }
                  return MovementTile(movement: movements[index - 1]);
                },
              ),
            ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, List<Movement> movements) {
    final created = movements
        .where((m) => m.status == MovementStatus.CREATED)
        .length;
    final completed = movements
        .where((m) => m.status == MovementStatus.COMPLETED)
        .length;
    final failed = movements
        .where((m) => m.status == MovementStatus.FAILED)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip('Pendientes', created, Colors.blueAccent),
          _buildStatChip('Completados', completed, Colors.green),
          _buildStatChip('Fallidos', failed, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
