import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dashboard.dart';
import 'pengeluaran.dart';
import 'keuangan.dart';
import 'category.dart';

import '../widgets/bottom_nav.dart';
import '../widgets/transaction_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_form.dart';
import '../widgets/top_bar.dart'; // ✅ Import TopBar

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

    try {
      final res = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/balances'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _balances = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetch balances: $e');
    }
  }

  /// Ambil kategori income
  Future<void> _fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/categories?type=income'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetch categories: $e');
    }
  }

  /// Ambil transaksi income
  Future<void> _fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        List<Map<String, dynamic>> all = [];

        if (data['data'] is Map && data['data']['data'] is List) {
          all = List<Map<String, dynamic>>.from(data['data']['data']);
        } else if (data['data'] is List) {
          all = List<Map<String, dynamic>>.from(data['data']);
        } else if (data['transactions'] is List) {
          all = List<Map<String, dynamic>>.from(data['transactions']);
        }

        debugPrint('Total transaksi ditemukan: ${all.length}');

        final incomeOnly = all.where((t) {
          final type = t['type']?.toString().toLowerCase() ?? '';
          return type == 'income';
        }).toList();

        debugPrint('Income transaksi: ${incomeOnly.length}');

        setState(() => _transactions = incomeOnly);
      }
    } catch (e) {
      debugPrint('Error fetch transactions: $e');
    }
  }

  /// Tambah pemasukan
  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBalance == null || _selectedCategory == null) {
      _showSnackBar("Pilih dompet dan kategori terlebih dahulu!", Colors.red);
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
          'Accept': 'application/json',
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
        _showSnackBar("Pemasukan berhasil ditambahkan!", Colors.green);
        await _fetchTransactions();
        await _fetchBalances();
      } else {
        final data = json.decode(res.body);
        _showSnackBar(
          data['message'] ?? "Gagal menambah pemasukan",
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Kesalahan jaringan", Colors.red);
    }
  }

  /// Update pemasukan
  Future<void> _updateTransaction(String id) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final res = await http.put(
        Uri.parse('https://smartbookkeeper.id/api/transactions/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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
        _showSnackBar("Pemasukan berhasil diperbarui!", Colors.green);
        await _fetchTransactions();
        await _fetchBalances();
      } else {
        final data = json.decode(res.body);
        _showSnackBar(
          data['message'] ?? "Gagal memperbarui pemasukan",
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Kesalahan jaringan", Colors.red);
    }
  }

  /// Hapus pemasukan dengan konfirmasi
  Future<void> _deleteTransaction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Pemasukan?"),
        content: const Text("Transaksi yang dihapus tidak dapat dipulihkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final res = await http.delete(
        Uri.parse('https://smartbookkeeper.id/api/transactions/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        _showSnackBar("Pemasukan berhasil dihapus!", Colors.green);
        await _fetchTransactions();
        await _fetchBalances();
      } else {
        _showSnackBar("Gagal menghapus pemasukan", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Kesalahan jaringan", Colors.red);
    }
  }

  void _resetForm() {
    _amountController.clear();
    _descriptionController.clear();
    _selectedBalance = null;
    _selectedCategory = null;
    _selectedDate = DateTime.now();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAddModal() {
    _resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
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

  String _formatCurrency(dynamic value) {
    if (value == null) return "Rp 0";
    final amount = int.tryParse(value.toString()) ?? 0;
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
  }

  double _getTotalIncome() {
    debugPrint('=== DEBUG _getTotalIncome ===');
    debugPrint('Total transactions: ${_transactions.length}');

    double total = 0;

    for (var i = 0; i < _transactions.length; i++) {
      final trx = _transactions[i];
      final amountRaw = trx['amount'];

      debugPrint('Transaksi $i:');
      debugPrint('  - ID: ${trx['id']}');
      debugPrint('  - Description: ${trx['description']}');
      debugPrint('  - Amount Raw: $amountRaw (Type: ${amountRaw.runtimeType})');

      double amount = 0;
      try {
        amount = double.parse(amountRaw?.toString() ?? '0');
      } catch (e) {
        debugPrint('  - Error parsing: $e');
        amount = 0;
      }

      debugPrint('  - Amount Parsed: $amount');
      total += amount;
    }

    debugPrint('Final Total: $total');
    return total;
  }

  int _getTransactionCount() {
    return _transactions.length;
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = _getTotalIncome();
    final transactionCount = _getTransactionCount();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(238, 238, 238, 1),
      // ✅ GANTI: PreferredSize AppBar dengan TopBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: TopBar(
          title: "Pemasukan",
          showBackButton: true,
          showMenuButton: true,
          onRefresh: () {
            _fetchTransactions();
            _fetchBalances();
          },
          onLogout: _logout,
          backgroundColor: const Color.fromRGBO(238, 238, 238, 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchTransactions();
            await _fetchBalances();
          },
          color: const Color(0xFF0F7ABB),
          child: CustomScrollView(
            slivers: [
              // 🔹 Header Summary Card
              SliverToBoxAdapter(
                child: _buildSummaryCard(totalIncome, transactionCount),
              ),

              // 🔹 Transaction List
              _transactions.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(message: "Belum ada data pemasukan"),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final trx = _transactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TransactionCard(
                              transaction: trx,
                              onEdit: () => _showEditModal(trx),
                              onDelete: () =>
                                  _deleteTransaction(trx['id'].toString()),
                            ),
                          );
                        }, childCount: _transactions.length),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModal,
        backgroundColor: const Color(0xFF0F7ABB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Pemasukan',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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

  Widget _buildSummaryCard(double totalIncome, int count) {
    return Container(
      margin: const EdgeInsets.all(16),
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pemasukan',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(totalIncome.toInt()),
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Transaksi', count.toString(), Icons.receipt_long),
              _buildStatItem(
                'Rata-rata',
                _formatCurrency(count > 0 ? totalIncome ~/ count : 0),
                Icons.calculate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
