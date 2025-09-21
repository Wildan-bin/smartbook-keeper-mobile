import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome =
        (transaction['type']?.toString().toLowerCase() ?? 'income') == 'income';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8), // 🔹 rapat, full lebar
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isIncome
              ? [const Color(0xFF0F7ABB), const Color(0xFF42A5F5)]
              : [const Color(0xFFD32F2F), const Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Icon modern
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // 🔹 Detail transaksi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'] ?? 'Tanpa deskripsi',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "Kategori: ${transaction['category']?['name'] ?? '-'}\n"
                  "Dompet: ${transaction['balance']?['name'] ?? '-'}",
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 🔹 Nominal & tanggal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (isIncome ? "+ " : "- ") + "Rp ${transaction['amount']}",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (transaction['date'] ?? transaction['created_at'] ?? '')
                    .toString()
                    .substring(0, 10),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
