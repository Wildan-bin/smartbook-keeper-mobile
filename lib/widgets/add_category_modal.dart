import 'package:flutter/material.dart';

class AddCategoryModal extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final String? selectedType;
  final String? selectedIcon;
  final String? selectedColor;
  final bool isLoading;

  final Function(String?) onTypeChanged;
  final Function(String?) onIconChanged;
  final Function(String?) onColorChanged;
  final VoidCallback onSubmit;

  const AddCategoryModal({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.selectedType,
    required this.selectedIcon,
    required this.selectedColor,
    required this.isLoading,
    required this.onTypeChanged,
    required this.onIconChanged,
    required this.onColorChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              "Tambah Kategori",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            // Nama kategori
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nama Kategori",
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? "Masukkan nama kategori" : null,
            ),
            const SizedBox(height: 16),

            // Tipe kategori
            DropdownButtonFormField<String>(
              value: selectedType,
              items: const [
                DropdownMenuItem(value: "income", child: Text("Income")),
                DropdownMenuItem(value: "expense", child: Text("Expense")),
              ],
              onChanged: onTypeChanged,
              decoration: const InputDecoration(
                labelText: "Tipe",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Pilih Icon
            DropdownButtonFormField<String>(
              value: selectedIcon,
              items: ["🍔", "📚", "💼", "🚗", "🏠", "🎉"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ))
                  .toList(),
              onChanged: onIconChanged,
              decoration: const InputDecoration(
                labelText: "Icon",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Pilih Warna
            DropdownButtonFormField<String>(
              value: selectedColor,
              items: ["#007ABB", "#FF9800", "#4CAF50", "#F44336"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              color: Color(int.parse(e.replaceAll('#', '0xFF'))),
                            ),
                            const SizedBox(width: 8),
                            Text(e),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: onColorChanged,
              decoration: const InputDecoration(
                labelText: "Warna",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F7ABB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text(
                        "Simpan",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
