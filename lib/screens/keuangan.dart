import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard.dart';
import 'package:flutter_application_1/screens/pemasukan.dart';
import 'package:flutter_application_1/screens/pengeluaran.dart';
import 'package:flutter_application_1/screens/category.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Widgets
import '../widgets/wallet_summary_card.dart';
import '../widgets/wallet_item.dart';
import '../widgets/bottom_nav.dart';

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
          _balances = (responseData['data'] as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateBalanceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // ✅ bisa ditutup dengan klik luar
      enableDrag: true, // ✅ bisa swipe ke bawah buat nutup
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => GestureDetector(
          // ✅ ini biar pas klik luar area form juga nutup
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: GestureDetector(
            onTap: () {}, // supaya isi form tetap bisa di-tap
            child: Container(
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
                        Text(
                          "Buat Dompet Baru",
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F7ABB),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
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
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? "Masukkan nama dompet"
                              : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: implement API create balance
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F7ABB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
      appBar: AppBar(
        title: Text(
          "Dompet Keuangan",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F7ABB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _balances.isEmpty
          ? Center(
              child: Text(
                "Belum ada dompet",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                WalletSummaryCard(
                  totalSaldo: totalSaldo,
                  jumlahDompet: _balances.length,
                ),
                const SizedBox(height: 16),
                ..._balances.map((b) => WalletItem(balance: b)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F7ABB),
        onPressed: _showCreateBalanceModal,
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
