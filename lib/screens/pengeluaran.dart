import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dashboard.dart';
import 'pemasukan.dart';
import 'keuangan.dart';
import 'category.dart';

class Pengeluaran extends StatefulWidget {
  const Pengeluaran({super.key});

  @override
  State<Pengeluaran> createState() => _PengeluaranState();
}

class _PengeluaranState extends State<Pengeluaran> {
  int currentIndex = 2;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedBalance;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _balances = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _transactions = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBalances();
    _fetchCategories();
    _fetchTransactions();
  }

  Future<void> _fetchBalances() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final res = await http.get(
      Uri.parse('https://smartbookkeeper.id/api/balances'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _balances = List<Map<String, dynamic>>.from(data['data'] ?? []);
      });
    }
  }

  Future<void> _fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final res = await http.get(
      Uri.parse('https://smartbookkeeper.id/api/categories?type=expense'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _categories = List<Map<String, dynamic>>.from(data['data'] ?? []);
      });
    }
  }

  Future<void> _fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final res = await http.get(
      Uri.parse('https://smartbookkeeper.id/api/transactions'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final all = List<Map<String, dynamic>>.from(data['data']['data'] ?? []);

      final expenseOnly = all
          .where((t) => t['type'].toString().toLowerCase() == 'expense')
          .toList();

      setState(() {
        _transactions = expenseOnly;
      });
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBalance == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih dompet dan kategori dulu!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final res = await http.post(
        Uri.parse('https://smartbookkeeper.id/api/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: json.encode({
          'balance_id': _selectedBalance,
          'category_id': _selectedCategory,
          'type': 'expense',
          'amount': _amountController.text.trim(),
          'description': _descriptionController.text.trim(),
          'date': _selectedDate.toIso8601String(),
        }),
      );

      setState(() => _isLoading = false);

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pengeluaran berhasil ditambahkan!")),
        );
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedBalance = null;
          _selectedCategory = null;
          _selectedDate = DateTime.now();
        });
        Navigator.pop(context);
        await _fetchTransactions();
      } else {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Gagal menambah pengeluaran")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text("Tambah Pengeluaran",
                    style: GoogleFonts.manrope(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Jumlah",
                    prefixIcon: Icon(Icons.money, color: Color(0xFF0F7ABB)),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Masukkan jumlah" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Deskripsi",
                    prefixIcon: Icon(Icons.note, color: Color(0xFF0F7ABB)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedBalance,
                  isExpanded: true,
                  hint: const Text("Pilih Dompet"),
                  items: _balances
                      .map((b) => DropdownMenuItem(
                            value: b['id'].toString(),
                            child: Text(b['name']),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedBalance = val),
                  validator: (val) =>
                      val == null ? "Pilih dompet terlebih dahulu" : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  hint: const Text("Pilih Kategori"),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c['id'].toString(),
                            child: Text(c['name']),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  validator: (val) =>
                      val == null ? "Pilih kategori terlebih dahulu" : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "Tanggal: ${_selectedDate.toLocal()}".split(' ')[0],
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.calendar_today,
                      color: Color(0xFF0F7ABB)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7ABB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _isLoading ? "Menyimpan..." : "Simpan",
                      style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationBar() {
    final List<Widget> pages = [
      const Dashboard(),
      const Pemasukan(),
      const Pengeluaran(),
      const Keuangan(),
      const CategoryScreen(),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0, 122, 187, 1.0),
        borderRadius:
            BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
      ),
      child: NavigationBar(
        backgroundColor: const Color.fromRGBO(0, 122, 187, 1.0),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home, color: Colors.white), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.add_circle, color: Colors.white), label: 'Pemasukan'),
          NavigationDestination(icon: Icon(Icons.remove_circle, color: Colors.white), label: 'Pengeluaran'),
          NavigationDestination(icon: Icon(Icons.note_rounded, color: Colors.white), label: 'Keuangan'),
          NavigationDestination(icon: Icon(Icons.category, color: Colors.white), label: 'Kategori'),
        ],
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
          if (index != 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => pages[index]));
          }
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 60,
        indicatorColor: Colors.white.withOpacity(0.2),
        surfaceTintColor: Colors.white,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
            (_) => const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pengeluaran",
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: const Color(0xFF0F7ABB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _transactions.isEmpty
            ? Center(
                child: Text(
                  "Belum ada riwayat pengeluaran",
                  style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final t = _transactions[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        child: const Icon(Icons.arrow_upward, color: Colors.red),
                      ),
                      title: Text("Rp ${t['amount']}",
                          style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      subtitle: Text(
                        "${t['description'] ?? '-'}\n"
                        "Kategori: ${t['category']?['name'] ?? '-'} | Dompet: ${t['balance']?['name'] ?? '-'}\n"
                        "${(t['date'] ?? t['created_at'] ?? '').toString().substring(0, 10)}",
                        style: GoogleFonts.manrope(fontSize: 13),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F7ABB),
        onPressed: _showAddModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }
}
