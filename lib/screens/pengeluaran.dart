import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Screens
import 'dashboard.dart';
import 'pemasukan.dart';
import 'keuangan.dart';
import 'category.dart';

// Widgets
import '../widgets/transaction_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/add_transaction_modal.dart';

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

  /// Ambil dompet
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

  /// Ambil kategori expense
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

  /// Ambil transaksi lalu filter expense
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
      final expenseOnly =
          all.where((t) => t['type'].toString().toLowerCase() == 'expense').toList();
      setState(() => _transactions = expenseOnly);
    }
  }

  /// Tambah pengeluaran
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
        _clearForm();
        Navigator.pop(context);
        await _fetchTransactions();
        await _fetchBalances(); // refresh saldo
      } else {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Gagal menambah pengeluaran")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Update pengeluaran
  Future<void> _updateTransaction(String id) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBalance == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih dompet dan kategori dulu!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final res = await http.put(
      Uri.parse('https://smartbookkeeper.id/api/transactions/$id'),
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

    if (res.statusCode == 200) {
      _clearForm();
      Navigator.pop(context);
      await _fetchTransactions();
      await _fetchBalances();
    }
  }

  /// Hapus pengeluaran
  Future<void> _deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final res = await http.delete(
      Uri.parse('https://smartbookkeeper.id/api/transactions/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      await _fetchTransactions();
      await _fetchBalances();
    }
  }

  /// Modal tambah
  void _showAddModal() {
    _clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTransactionModal(
        formKey: _formKey,
        amountController: _amountController,
        descriptionController: _descriptionController,
        selectedBalance: _selectedBalance,
        selectedCategory: _selectedCategory,
        selectedDate: _selectedDate,
        balances: _balances,
        categories: _categories,
        isLoading: _isLoading,
        onBalanceChanged: (val) => setState(() => _selectedBalance = val),
        onCategoryChanged: (val) => setState(() => _selectedCategory = val),
        onDateChanged: (val) => setState(() => _selectedDate = val),
        onSubmit: _submitTransaction,
        title: "Tambah Pengeluaran",
        submitLabel: "Simpan",
      ),
    );
  }

  /// Modal edit
  void _showEditModal(Map<String, dynamic> trx) {
    _amountController.text = trx['amount'].toString();
    _descriptionController.text = trx['description'] ?? '';
    _selectedBalance = trx['balance']?['id']?.toString();
    _selectedCategory = trx['category']?['id']?.toString();
    _selectedDate =
        DateTime.tryParse((trx['date'] ?? trx['created_at']).toString()) ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTransactionModal(
        formKey: _formKey,
        amountController: _amountController,
        descriptionController: _descriptionController,
        selectedBalance: _selectedBalance,
        selectedCategory: _selectedCategory,
        selectedDate: _selectedDate,
        balances: _balances,
        categories: _categories,
        isLoading: _isLoading,
        onBalanceChanged: (val) => setState(() => _selectedBalance = val),
        onCategoryChanged: (val) => setState(() => _selectedCategory = val),
        onDateChanged: (val) => setState(() => _selectedDate = val),
        onSubmit: () => _updateTransaction(trx['id'].toString()),
        title: "Edit Pengeluaran",
        submitLabel: "Update",
      ),
    );
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    _selectedBalance = null;
    _selectedCategory = null;
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pengeluaran",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          ),
        backgroundColor: const Color(0xFF0F7ABB),
      ),
      body: _transactions.isEmpty
          ? Center(
              child: Text(
                "Belum ada riwayat pengeluaran",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, i) {
                final trx = _transactions[i];
                return TransactionCard(
                  transaction: trx,
                  onEdit: () => _showEditModal(trx),
                  onDelete: () => _deleteTransaction(trx['id'].toString()),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F7ABB),
        onPressed: _showAddModal,
        child: const Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius : BorderRadius.circular(50),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,
        onTap: (i) {
          setState(() => currentIndex = i);
          final pages = [
            const Dashboard(),
            const Pemasukan(),
            const Pengeluaran(),
            const Keuangan(),
            const CategoryScreen(),
          ];
          if (i != 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => pages[i]),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
