import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/movement.dart';
import '../providers/wallet_provider.dart';

class CreateMovementScreen extends StatefulWidget {
  const CreateMovementScreen({super.key});
  @override
  State<CreateMovementScreen> createState() => _CreateMovementScreenState();
}

class _CreateMovementScreenState extends State<CreateMovementScreen> {
  MovementType _type = MovementType.DEPOSIT;
  final _amount = TextEditingController(), _desc = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _payMethod = 'Bank transfer';
  final _methods = ['Bank transfer', 'Credit card', 'Debit card', 'Cash'];

  @override
  void dispose() {
    _amount.dispose();
    _desc.dispose();
    super.dispose();
  }

  double _cost(double amt) => double.parse((amt * 0.01).toStringAsFixed(2));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amt = double.tryParse(_amount.text) ?? 0;
    if (amt <= 0) return;
    final w = context.read<WalletProvider>();
    if (await w.createMovement(type: _type, amount: amt, cost: _cost(amt))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_type.name} creado'),
          backgroundColor: Colors.green,
        ),
      );
      _amount.clear();
      _desc.clear();
      setState(() {
        _type = MovementType.DEPOSIT;
        _payMethod = 'Bank transfer';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(w.errorMessage ?? 'Error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<WalletProvider>().isLoading;
    final color = _type == MovementType.DEPOSIT
        ? Colors.green
        : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Nuevo Movimiento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Crea un nuevo depósito o retiro',
              style: TextStyle(fontSize: 13, color: Colors.white54),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _typeBtn(
                        'Depósito',
                        Icons.south_west,
                        MovementType.DEPOSIT,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _typeBtn(
                        'Retiro',
                        Icons.north_east,
                        MovementType.DEBIT,
                        Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Monto',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDeco('\$ ', color),
                validator: (v) =>
                    v == null || v.isEmpty || (double.tryParse(v) ?? 0) <= 0
                    ? 'Monto inválido'
                    : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Descripción',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _fieldDeco(null, color),
              ),
              const SizedBox(height: 24),
              _dropdown(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : () => setState(() => _type = MovementType.DEPOSIT),
                      style: _outBtnStyle(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: _elevBtnStyle(color),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Confirmar',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String lbl, IconData icon, MovementType t, Color c) {
    final sel = _type == t;
    return GestureDetector(
      onTap: () => setState(() => _type = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? c.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: sel ? Border.all(color: c.withOpacity(0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: sel ? c : Colors.white38),
            const SizedBox(width: 8),
            Text(
              lbl,
              style: TextStyle(
                color: sel ? c : Colors.white38,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String? pref, Color c) => InputDecoration(
    prefixText: pref,
    filled: true,
    fillColor: const Color(0xFF1E293B),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF334155)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    ),
  );

  Widget _dropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF334155)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _payMethod,
        isExpanded: true,
        dropdownColor: const Color(0xFF1E293B),
        style: const TextStyle(color: Colors.white),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
        items: _methods
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
            .toList(),
        onChanged: (v) => v != null ? setState(() => _payMethod = v) : null,
      ),
    ),
  );

  ButtonStyle _outBtnStyle() => OutlinedButton.styleFrom(
    foregroundColor: Colors.white70,
    side: const BorderSide(color: Color(0xFF334155)),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
  ButtonStyle _elevBtnStyle(Color c) => ElevatedButton.styleFrom(
    backgroundColor: c,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
