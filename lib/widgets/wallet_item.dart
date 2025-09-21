import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletItem extends StatelessWidget {
  final Map<String, dynamic> balance;

  const WalletItem({super.key, required this.balance});

  String _formatCurrency(dynamic amount) {
    final current = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return current.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F7ABB).withOpacity(0.1),
          child: const Icon(Icons.account_balance_wallet,
              color: Color(0xFF0F7ABB)),
        ),
        title: Text(balance['name'] ?? 'Dompet'),
        subtitle: Text('Mata Uang: ${balance['currency'] ?? 'IDR'}'),
        trailing: Text(
          'Rp ${_formatCurrency(balance['current_amount'])}',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700, color: const Color(0xFF0F7ABB)),
        ),
      ),
    );
  }
}
