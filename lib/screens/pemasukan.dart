// pemasukan.dart
// ✅ Pemasukan screen fix update & delete transaksi
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Screens
import 'dashboard.dart';
import 'pengeluaran.dart';
import 'keuangan.dart';
import 'category.dart';

// Widgets
import '../widgets/bottom_nav.dart';
import '../widgets/transaction_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_form.dart';

class Pemasukan extends StatefulWidget {
  const Pemasukan({super.key});

  @override
  State<Pemasukan> createState() => _PemasukanState();
}

class _PemasukanState extends State<Pemasukan> {
  int currentIndex = 1;

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

  /// Ambil data dompet
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

  /// Ambil kategori income
  Future<void> _fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final res = await http.get(
      Uri.parse('https://smartbookkeeper.id/api/categories?type=income'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _categories = List<Map<String, dynamic>>.from(data['data'] ?? []);
      });
    }
  }

  /// Ambil transaksi income
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
      final incomeOnly = all.where((t) => t['type'] == 'income').toList();

      setState(() => _transactions = incomeOnly);
    }
  }

  /// Tambah pemasukan
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
          'type': 'income',
          'amount': _amountController.text.trim(),
          'description': _descriptionController.text.trim(),
          'date': _selectedDate.toIso8601String(),
        }),
      );

      setState(() => _isLoading = false);

      if (res.statusCode == 201) {
        _resetForm();
        Navigator.pop(context);
        await _fetchTransactions();
        await _fetchBalances(); // refresh saldo
      } else {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Gagal menambah pemasukan")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Update pemasukan
  Future<void> _updateTransaction(String id) async {
    if (!_formKey.currentState!.validate()) return;

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
        'type': 'income',
        'amount': _amountController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': _selectedDate.toIso8601String(),
      }),
    );

    setState(() => _isLoading = false);

    if (res.statusCode == 200) {
      _resetForm();
      Navigator.pop(context);
      await _fetchTransactions();
      await _fetchBalances();
    }
  }

  /// Hapus pemasukan
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

  void _resetForm() {
    _amountController.clear();
    _descriptionController.clear();
    _selectedBalance = null;
    _selectedCategory = null;
    _selectedDate = DateTime.now();
  }

  void _showAddModal() {
    _resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionForm(
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
        onDateChanged: (date) => setState(() => _selectedDate = date),
        onSubmit: _submitTransaction,
        isEdit: false,
      ),
    );
  }

  void _showEditModal(Map<String, dynamic> trx) {
    _amountController.text = trx['amount'].toString();
    _descriptionController.text = trx['description'] ?? '';
    _selectedBalance = trx['balance_id'].toString();
    _selectedCategory = trx['category_id'].toString();
    _selectedDate = DateTime.parse(trx['date']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionForm(
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
        onDateChanged: (date) => setState(() => _selectedDate = date),
        onSubmit: () => _updateTransaction(trx['id'].toString()),
        isEdit: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pemasukan"),
        backgroundColor: const Color(0xFF0F7ABB),
      ),
      body: _transactions.isEmpty
          ? const EmptyState(message: "Belum ada pemasukan")
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (c, i) {
                final trx = _transactions[i];
                return TransactionCard(
                  transaction: trx,
                  onEdit: () => _showEditModal(trx),
                  onDelete: () => _deleteTransaction(trx['id'].toString()),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: const Color(0xFF0F7ABB),
        child: const Icon(Icons.add, color: Colors.white),
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
          if (i != 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => pages[i]),
            );
          }
        },
      ),
    );
  }
}
