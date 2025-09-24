import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final String? selectedBalance;
  final String? selectedCategory;
  final DateTime selectedDate;
  final List<Map<String, dynamic>> balances;
  final List<Map<String, dynamic>> categories;
  final bool isLoading;

  final void Function(String?) onBalanceChanged;
  final void Function(String?) onCategoryChanged;
  final void Function(DateTime) onDateChanged;
  final VoidCallback onSubmit;

  /// 🔹 Tambahan properti untuk bedain Add vs Edit
  final bool isEdit;

  const TransactionForm({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.descriptionController,
    required this.selectedBalance,
    required this.selectedCategory,
    required this.selectedDate,
    required this.balances,
    required this.categories,
    required this.isLoading,
    required this.onBalanceChanged,
    required this.onCategoryChanged,
    required this.onDateChanged,
    required this.onSubmit,
    this.isEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              isEdit ? "Edit Transaksi" : "Tambah Transaksi",
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Jumlah
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Jumlah",
                prefixIcon: Icon(Icons.money, color: Color(0xFF0F7ABB)),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? "Masukkan jumlah" : null,
            ),
            const SizedBox(height: 12),

            // 🔹 Deskripsi
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                prefixIcon: Icon(Icons.note, color: Color(0xFF0F7ABB)),
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Dropdown Dompet
            DropdownButtonFormField<String>(
              value: selectedBalance,
              isExpanded: true,
              hint: const Text("Pilih Dompet"),
              items: balances
                  .map((b) => DropdownMenuItem(
                        value: b['id'].toString(),
                        child: Text(b['name']),
                      ))
                  .toList(),
              onChanged: onBalanceChanged,
              validator: (val) =>
                  val == null ? "Pilih dompet terlebih dahulu" : null,
            ),
            const SizedBox(height: 12),

            // 🔹 Dropdown Kategori
            DropdownButtonFormField<String>(
              value: selectedCategory,
              isExpanded: true,
              hint: const Text("Pilih Kategori"),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(c['name']),
                      ))
                  .toList(),
              onChanged: onCategoryChanged,
              validator: (val) =>
                  val == null ? "Pilih kategori terlebih dahulu" : null,
            ),
            const SizedBox(height: 12),

            // 🔹 Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Tanggal: ${selectedDate.toLocal()}".split(' ')[0],
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              trailing:
                  const Icon(Icons.calendar_today, color: Color(0xFF0F7ABB)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) onDateChanged(picked);
              },
            ),
            const SizedBox(height: 16),

            // 🔹 Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F7ABB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  isLoading
                      ? (isEdit ? "Menyimpan..." : "Menyimpan...")
                      : (isEdit ? "Update" : "Simpan"),
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
