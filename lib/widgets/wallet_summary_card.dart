import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletSummaryCard extends StatelessWidget {
  final double totalSaldo;
  final int jumlahDompet;

  const WalletSummaryCard({
    super.key,
    required this.totalSaldo,
    required this.jumlahDompet,
  });

  String _formatCurrency(num amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F7ABB), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F7ABB).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Saldo',
              style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Rp ${_formatCurrency(totalSaldo)}',
              style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('$jumlahDompet Dompet Aktif',
              style: GoogleFonts.manrope(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
