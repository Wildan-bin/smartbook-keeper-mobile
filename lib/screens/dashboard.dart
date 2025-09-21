import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 🔹 Screens
import 'pemasukan.dart';
import 'pengeluaran.dart';
import 'keuangan.dart';
import 'category.dart';
import 'login.dart';

// 🔹 Widgets
import '../widgets/greeting_section.dart';
import '../widgets/balance_chart_card.dart';
import '../widgets/financial_graph.dart';
import '../widgets/bottom_nav.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  bool _isLoadingBalance = true;
  String _userName = 'Admin';
  String _userBalance = "Rp0";
  String? _errorMessage;

  List<FlSpot> _chartSpotsIncome = [];
  List<FlSpot> _chartSpotsExpense = [];
  List<String> _weekLabels = [];

  int currentIndex = 0;

  // 🔹 State filter tanggal
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  /// 🔹 Helper format tanggal (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// 🔹 Buka Date Range Picker
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchDashboardData();
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoadingBalance = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        _logout();
        return;
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 🔹 Tambahkan query param filter tanggal
      String chartUrl = 'https://smartbookkeeper.id/api/dashboard/charts';
      String balanceUrl = 'https://smartbookkeeper.id/api/balances';
      if (_startDate != null && _endDate != null) {
        final start = _formatDate(_startDate!);
        final end = _formatDate(_endDate!);
        chartUrl += '?start_date=$start&end_date=$end';
        balanceUrl += '?start_date=$start&end_date=$end';
      }

      final profileRes = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/profile'),
        headers: headers,
      );
      final balanceRes = await http.get(Uri.parse(balanceUrl), headers: headers);
      final chartRes = await http.get(Uri.parse(chartUrl), headers: headers);

      if (profileRes.statusCode == 200 &&
          balanceRes.statusCode == 200 &&
          chartRes.statusCode == 200) {
        final profileData = json.decode(profileRes.body);
        final balanceData = json.decode(balanceRes.body);
        final chartData = json.decode(chartRes.body);

        final userName = profileData['data']?['name'] ?? 'User';

        // 🔹 Hitung total saldo (support filter kalau backend ada)
        num totalBalance = 0;
        if (balanceData['data'] is List) {
          for (var b in balanceData['data']) {
            totalBalance += num.tryParse(b['current_amount'].toString()) ?? 0;
          }
        }
        final formattedBalance = _formatCurrency(totalBalance);

        // 🔹 Data grafik
        List<dynamic> weeklyData = chartData['data']?['weekly_data'] ?? [];
        List<FlSpot> incomeSpots = [];
        List<FlSpot> expenseSpots = [];
        List<String> weekLabels = [];

        for (int i = 0; i < weeklyData.length; i++) {
          final w = weeklyData[i];
          weekLabels.add(w['week']);
          incomeSpots.add(FlSpot(
            i.toDouble(),
            double.tryParse(w['income'].toString()) ?? 0,
          ));
          expenseSpots.add(FlSpot(
            i.toDouble(),
            double.tryParse(w['expense'].toString()) ?? 0,
          ));
        }

        setState(() {
          _userName = userName;
          _userBalance = "Rp$formattedBalance";
          _chartSpotsIncome = incomeSpots;
          _chartSpotsExpense = expenseSpots;
          _weekLabels = weekLabels;
          _isLoadingBalance = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal load data';
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoadingBalance = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final num parsed = num.tryParse(amount.toString()) ?? 0;
    return parsed.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Future<void> _refreshData() async {
    await _fetchDashboardData();
  }

  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin mau keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0F7ABB),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GreetingSection(
                  userName: _userName,
                  isLoading: _isLoadingBalance,
                  onRefresh: _refreshData,
                  onLogout: _logout,
                ),
                const SizedBox(height: 24),

                // 🔹 Filter tanggal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grafik Saldo & Omzet",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range,
                            color: Color(0xFF0F7ABB)),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? "${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}"
                              : "Pilih Tanggal",
                          style: const TextStyle(color: Color(0xFF0F7ABB)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                BalanceChartCard(
                  isLoading: _isLoadingBalance,
                  errorMessage: _errorMessage,
                  chartData: _chartSpotsIncome.isNotEmpty
                      ? _chartSpotsIncome.map((e) => e.y).toList()
                      : [0, 0, 0],
                  balance: _userBalance,
                ),
                const SizedBox(height: 24),

                FinancialGraph(
                  incomeSpots: _chartSpotsIncome,
                  expenseSpots: _chartSpotsExpense,
                  weekLabels: _weekLabels,
                  formatCurrency: _formatCurrency,
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: BottomNav(
            currentIndex: currentIndex,
            onTap: (i) {
              if (i == currentIndex) return;
              setState(() => currentIndex = i);

              final pages = [
                const Dashboard(),
                const Pemasukan(),
                const Pengeluaran(),
                const Keuangan(),
                const CategoryScreen(),
              ];

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => pages[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}
