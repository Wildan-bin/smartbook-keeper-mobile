import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Screens
import 'dashboard.dart';
import 'pemasukan.dart';
import 'pengeluaran.dart';
import 'category.dart';

// Widgets
import '../widgets/wallet_summary_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/top_bar.dart';

class Keuangan extends StatefulWidget {
  const Keuangan({super.key});

  @override
  State<Keuangan> createState() => _KeuanganState();
}

class _KeuanganState extends State<Keuangan> {
  int currentIndex = 3;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  List<Map<String, dynamic>> _balances = [];

  @override
  void initState() {
    super.initState();
    _fetchBalances();
  }

  /// Ambil semua dompet
  Future<void> _fetchBalances() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/balances'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _balances = List<Map<String, dynamic>>.from(
            responseData['data'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint("Error fetch balances: $e");
    }
    setState(() => _isLoading = false);
  }

  /// Tambah dompet baru
  Future<void> _createBalance() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final requestBody = {
        'name': _nameController.text.trim(),
        'currency': 'IDR',
      };
      debugPrint('Create Balance Request: $requestBody');

      final response = await http.post(
        Uri.parse('https://smartbookkeeper.id/api/balances'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        Navigator.pop(context);
        _nameController.clear();

        await _fetchBalances();

        _showSnackBar("✅ Dompet berhasil dibuat", Colors.green);
      } else {
        try {
          final data = json.decode(response.body);
          debugPrint('Error Data: $data');

          _showSnackBar(
            data['message'] ?? "Gagal buat dompet (${response.statusCode})",
            Colors.red,
          );
        } catch (e) {
          _showSnackBar(
            "Gagal buat dompet: ${response.statusCode}",
            Colors.red,
          );
        }
      }
    } catch (e) {
      debugPrint("Error create balance: $e");
      _showSnackBar("Kesalahan jaringan: $e", Colors.red);
    }
  }

  /// Update dompet
  Future<void> _updateBalance(int id) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('https://smartbookkeeper.id/api/balances/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'currency': 'IDR',
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        _nameController.clear();
        await _fetchBalances();
        _showSnackBar("✅ Dompet berhasil diupdate", Colors.green);
      } else {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? "Gagal update dompet", Colors.red);
      }
    } catch (e) {
      debugPrint("Error update balance: $e");
      _showSnackBar("Kesalahan jaringan", Colors.red);
    }
  }

  /// Hapus dompet dengan konfirmasi
  Future<void> _deleteBalance(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Dompet?"),
        content: const Text("Dompet yang dihapus tidak dapat dipulihkan."),
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

      final response = await http.delete(
        Uri.parse('https://smartbookkeeper.id/api/balances/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _balances.removeWhere((b) => b['id'] == id);
        });

        _showSnackBar("✅ Dompet berhasil dihapus", Colors.green);
      } else {
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? "Gagal hapus dompet", Colors.red);
        await _fetchBalances();
      }
    } catch (e) {
      debugPrint("Error delete balance: $e");
      _showSnackBar("Kesalahan jaringan", Colors.red);
    }
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

  /// Modal tambah dompet
  void _showCreateBalanceModal() {
    _nameController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Buat Dompet Baru",
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F7ABB),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Input Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Nama Dompet",
                      hintText: "Contoh: Cash, BCA, Dana",
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF0F7ABB),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F7ABB),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? "Masukkan nama dompet"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7ABB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF0F7ABB).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF0F7ABB),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Mata uang Rupiah (IDR) akan diatur otomatis",
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF0F7ABB),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _createBalance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7ABB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Buat Dompet",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Modal edit dompet
  void _showEditBalanceModal(Map<String, dynamic> balance) {
    _nameController.text = balance['name'] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit Dompet",
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F7ABB),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Input Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Nama Dompet",
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF0F7ABB),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F7ABB),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? "Masukkan nama dompet"
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _updateBalance(balance['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7ABB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Update Dompet",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double value) {
    return "Rp ${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
  }

  @override
  Widget build(BuildContext context) {
    final totalSaldo = _balances.fold<double>(
      0.0,
      (sum, b) =>
          sum +
          (double.tryParse(b['current_amount']?.toString() ?? '0') ?? 0.0),
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      // ✅ GANTI: NestedScrollView dengan AppBar TopBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: TopBar(
          title: "Keuangan",
          showBackButton: true,
          showMenuButton: true,
          onRefresh: _fetchBalances,
          onLogout: _logout,
          backgroundColor: Colors.grey[200]!,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _balances.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchBalances,
                  color: const Color(0xFF0F7ABB),
                  child: CustomScrollView(
                    slivers: [
                      // 🔹 Summary Card
                      SliverToBoxAdapter(
                        child: _buildSummaryCard(totalSaldo, _balances.length),
                      ),

                      // 🔹 Balances List
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final balance = _balances[index];
                            final saldo =
                                double.tryParse(
                                  balance['current_amount'].toString(),
                                ) ??
                                0.0;

                            return _buildBalanceCard(balance, saldo);
                          }, childCount: _balances.length),
                        ),
                      ),

                      // Bottom Spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBalanceModal,
        backgroundColor: const Color(0xFF0F7ABB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Dompet',
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
          if (i != 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => pages[i]),
            );
          }
        },
      ),
    );
  }

  /// Empty State Widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7ABB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: const Color(0xFF0F7ABB).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum Ada Dompet",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Buat dompet pertama untuk\nmengelola keuangan Anda",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateBalanceModal,
            icon: const Icon(Icons.add),
            label: Text(
              'Buat Dompet',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F7ABB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Summary Card Widget
  Widget _buildSummaryCard(double totalSaldo, int jumlahDompet) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F7ABB), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F7ABB).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                    'Total Saldo',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(totalSaldo),
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBadge(
                'Dompet Aktif',
                jumlahDompet.toString(),
                Icons.folder_special,
              ),
              _buildStatBadge(
                'Rata-rata',
                _formatCurrency(
                  jumlahDompet > 0 ? totalSaldo / jumlahDompet : 0,
                ),
                Icons.calculate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stat Badge Widget
  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Balance Card Widget
  Widget _buildBalanceCard(Map<String, dynamic> balance, double saldo) {
    final canDelete = saldo <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 246, 246, 247),
              const Color.fromARGB(255, 221, 221, 221),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F7ABB), Color(0xFF1E88E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance['name'] ?? "-",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mata Uang: ${balance['currency'] ?? "IDR"}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(saldo),
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF0F7ABB),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: saldo > 0
                              ? Colors.green[100]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          saldo > 0 ? 'Aktif' : 'Kosong',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: saldo > 0
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditBalanceModal(balance),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F7ABB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: canDelete
                        ? () => _deleteBalance(balance['id'])
                        : null,
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(
                      'Hapus',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: canDelete ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// TAMBAH: Method logout
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
}
