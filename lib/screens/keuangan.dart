import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard.dart';
import 'package:flutter_application_1/screens/pemasukan.dart';
import 'package:flutter_application_1/screens/pengeluaran.dart';
import 'package:flutter_application_1/screens/category.dart'; // ✅ Tambahan
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class Keuangan extends StatefulWidget {
  const Keuangan({super.key});

  @override
  State<Keuangan> createState() => KeuanganState();
}

class KeuanganState extends State<Keuangan> {
  int currentIndex = 3;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isCreatingBalance = false;
  List<Map<String, dynamic>> _balances = [];

  @override
  void initState() {
    super.initState();
    _fetchBalances();
  }

  /// 🔹 Ambil daftar dompet dari API
  Future<void> _fetchBalances() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showSnackBar('Silakan login terlebih dahulu', Colors.red);
        return;
      }

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
          _balances = (responseData['data'] as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _showSnackBar('Sesi telah berakhir, silakan login kembali', Colors.red);
        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal memuat data dompet', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Kesalahan jaringan: ${e.toString()}', Colors.red);
    }
  }

  /// 🔹 Tambah dompet baru
  Future<void> _createBalance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreatingBalance = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showSnackBar('Silakan login terlebih dahulu', Colors.red);
        return;
      }

      final response = await http.post(
        Uri.parse('https://smartbookkeeper.id/api/balances'),
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

      setState(() => _isCreatingBalance = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _nameController.clear();
        Navigator.of(context).pop();
        _showSnackBar('Dompet berhasil dibuat!', Colors.green);
        _fetchBalances();
      } else {
        final responseData = json.decode(response.body);
        _showSnackBar(
            responseData['message'] ?? 'Gagal membuat dompet', Colors.red);
      }
    } catch (e) {
      setState(() => _isCreatingBalance = false);
      _showSnackBar('Kesalahan jaringan: Periksa koneksi internet', Colors.red);
    }
  }

  /// 🔹 SnackBar Helper
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 🔹 Modal buat dompet (FIX overflow)
  void _showCreateBalanceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              controller: controller,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buat Dompet Baru',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F7ABB),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Input Nama Dompet
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isCreatingBalance,
                      decoration: InputDecoration(
                        labelText: 'Nama Dompet',
                        hintText: 'Contoh: Cash, BCA, Dana',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF0F7ABB),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F7ABB),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan nama dompet';
                        }
                        if (value.length > 255) {
                          return 'Nama terlalu panjang (maksimal 255 karakter)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Info Currency
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F7ABB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF0F7ABB).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF0F7ABB), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mata uang Rupiah (IDR) akan diatur otomatis',
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
                    const SizedBox(height: 30),

                    // Tombol Buat
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isCreatingBalance ? null : _createBalance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7ABB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCreatingBalance
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Buat Dompet',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Format angka ke Rupiah
  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final intAmount = (amount is double)
        ? amount.toInt()
        : int.tryParse(amount.toString().split(".").first) ?? 0;
    return intAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Dompet Keuangan',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color.fromRGBO(0, 122, 187, 1.0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchBalances,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBalances,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _balances.isEmpty
                ? _buildEmptyState()
                : _buildBalancesList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBalanceModal,
        backgroundColor: const Color(0xFF0F7ABB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  /// 🔹 Tampilan kalau belum ada dompet
  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Dompet',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Buat dompet pertama untuk\nmengelola keuangan Anda',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateBalanceModal,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Buat Dompet Pertama',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F7ABB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔹 List dompet + summary card
  Widget _buildBalancesList() {
    final totalSaldo = _balances.fold<double>(
      0.0,
      (sum, balance) =>
          sum + (double.tryParse(balance['current_amount']?.toString() ?? '0') ?? 0.0),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Container(
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
                  style: GoogleFonts.manrope(
                      color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Rp ${_formatCurrency(totalSaldo.toInt())}',
                  style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${_balances.length} Dompet Aktif',
                  style: GoogleFonts.manrope(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Daftar Dompet
        ..._balances.map((balance) {
          final currentAmount =
              double.tryParse(balance['current_amount']?.toString() ?? '0') ??
                  0.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0F7ABB).withOpacity(0.1),
                child: const Icon(Icons.account_balance_wallet,
                    color: Color(0xFF0F7ABB)),
              ),
              title: Text(balance['name'] ?? 'Dompet'),
              subtitle: Text('Mata Uang: ${balance['currency'] ?? 'IDR'}'),
              trailing: Text(
                'Rp ${_formatCurrency(currentAmount.toInt())}',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700, color: Color(0xFF0F7ABB)),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 🔹 Bottom Navigation
  Widget _buildNavigationBar() {
    final List<Widget> pages = [
      const Dashboard(),
      const Pemasukan(),
      const Pengeluaran(),
      const Keuangan(),
      const CategoryScreen(), // ✅ Tambahan kategori
    ];

    return NavigationBar(
      backgroundColor: const Color.fromRGBO(0, 122, 187, 1.0),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home, color: Colors.white),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle, color: Colors.white),
          label: 'Pemasukan',
        ),
        NavigationDestination(
          icon: Icon(Icons.remove_circle, color: Colors.white),
          label: 'Pengeluaran',
        ),
        NavigationDestination(
          icon: Icon(Icons.note_rounded, color: Colors.white),
          label: 'Keuangan',
        ),
        NavigationDestination(
          icon: Icon(Icons.category, color: Colors.white),
          label: 'Kategori',
        ),
      ],
      selectedIndex: currentIndex,
      onDestinationSelected: (int index) {
        setState(() => currentIndex = index);

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Pemasukan()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Pengeluaran()),
            );
            break;
          case 3:
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CategoryScreen()),
            );
            break;
        }
      },
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      height: 60,
      indicatorColor: Colors.white.withOpacity(0.2),
      surfaceTintColor: Colors.white,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return const TextStyle(color: Colors.white);
      }),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
