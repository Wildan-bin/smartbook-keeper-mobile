import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  /// ✅ Format currency tanpa desimal
  String _formatCurrency(dynamic value) {
    if (value == null) return "0";

    // Convert ke double terlebih dahulu
    final amount = double.tryParse(value.toString()) ?? 0.0;

    // Convert ke integer untuk menghilangkan desimal
    final intAmount = amount.toInt();

    // Format dengan pemisah ribuan
    return intAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome =
        (transaction['type']?.toString().toLowerCase() ?? 'income') == 'income';

    final createdDate = (transaction['date'] ?? transaction['created_at'] ?? '')
        .toString()
        .substring(0, 10);

    // ✅ OUTER CONTAINER: Wrapper dengan created at
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Created At di luar card
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
            padding: const EdgeInsets.only(right:8.0, bottom: 2.0),
            child: Text(
              createdDate,
              style: GoogleFonts.manrope(
                fontSize: 16,
                // letterSpacing: -0.5,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ),

          // ✅ INNER CARD: Card sebenarnya
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 246, 246, 247),
                  const Color.fromARGB(255, 240, 240, 240),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
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
                // 🔹 Icon
                Container(
                  width: 30,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F7ABB), Color(0xFF1E88E5)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 🔹 Detail transaksi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Nominal Transaksi
                      Text(
                        (isIncome ? "+ " : "- ") +
                            "Rp ${_formatCurrency(transaction['amount'])}",
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          letterSpacing: -0.5,
                          fontWeight: FontWeight.w800,
                          color: const Color.fromARGB(255, 52, 51, 51),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ✅ Nama Kategori
                      Text(
                        "${transaction['category']?['name'] ?? '-'}",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(200, 0, 0, 0),
                        ),
                        overflow: TextOverflow.fade,
                      ),
                      const SizedBox(height: 4),

                      // ✅ Deskripsi & Dompet
                      Text(
                        "${transaction['description'] ?? 'Tanpa deskripsi'} "
                        "• ${transaction['balance']?['name'] ?? '-'}",
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          letterSpacing: 0,
                          color: Colors.black45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 🔹 Menu Aksi (PopupMenuButton)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit,
                              color: Color(0xFF0F7ABB), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Hapus',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
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

  /// Dialog konfirmasi hapus
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Hapus Transaksi?"),
        content: const Text(
          "Apakah kamu yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Batal",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: Text(
              "Hapus",
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
