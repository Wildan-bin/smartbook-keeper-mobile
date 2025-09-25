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
  List<String> _labels = [];

  int currentIndex = 0;
  String _selectedMode = "daily"; // daily | weekly | monthly

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
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

      final profileRes = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/profile'),
        headers: headers,
      );
      final summaryRes = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/dashboard/summary?type=$_selectedMode'),
        headers: headers,
      );
      final chartRes = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/dashboard/charts?type=$_selectedMode'),
        headers: headers,
      );

      if (profileRes.statusCode == 200 &&
          summaryRes.statusCode == 200 &&
          chartRes.statusCode == 200) {
        final profileData = json.decode(profileRes.body);
        final summaryData = json.decode(summaryRes.body);
        final chartData = json.decode(chartRes.body);

        final userName = profileData['data']?['name'] ?? 'User';

        // Summary (total_balance real-time, income/expense by period)
        final totalBalance = summaryData['data']?['total_balance'] ?? 0;
        final formattedBalance = _formatCurrency(totalBalance);

        // Charts
        final List<dynamic> rawData = (chartData['data'] ?? []) as List<dynamic>;
        final List<FlSpot> incomeSpots = [];
        final List<FlSpot> expenseSpots = [];
        final List<String> labels = [];

        for (int i = 0; i < rawData.length; i++) {
          final Map<String, dynamic> w = Map<String, dynamic>.from(rawData[i] ?? {});
          labels.add(w['label']?.toString() ?? '');
          final incomeVal = (w['income'] ?? 0).toString();
          final expenseVal = (w['expense'] ?? 0).toString();
          incomeSpots.add(FlSpot(i.toDouble(), double.tryParse(incomeVal) ?? 0));
          expenseSpots.add(FlSpot(i.toDouble(), double.tryParse(expenseVal) ?? 0));
        }

        // Safety: kalau data kosong, isi nol agar chart flat dan tidak error
        final List<FlSpot> safeIncome = incomeSpots.isNotEmpty
            ? incomeSpots
            : List.generate(7, (i) => FlSpot(i.toDouble(), 0));
        final List<FlSpot> safeExpense = expenseSpots.isNotEmpty
            ? expenseSpots
            : List.generate(7, (i) => FlSpot(i.toDouble(), 0));
        final List<String> safeLabels = labels.isNotEmpty
            ? labels
            : List.generate(7, (i) => '');

        setState(() {
          _userName = userName;
          _userBalance = "Rp$formattedBalance";
          _chartSpotsIncome = safeIncome;
          _chartSpotsExpense = safeExpense;
          _labels = safeLabels;
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
    final num parsed = num.tryParse((amount ?? '0').toString()) ?? 0;
    return parsed.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<void> _refreshData() async => _fetchDashboardData();

  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin mau keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Logout')),
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

                // Mode pilih Daily / Weekly / Monthly
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Grafik Saldo & Omzet",
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _selectedMode,
                        items: const [
                          DropdownMenuItem(value: "daily", child: Text("Harian")),
                          DropdownMenuItem(value: "weekly", child: Text("Mingguan")),
                          DropdownMenuItem(value: "monthly", child: Text("Bulanan")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMode = val);
                            _fetchDashboardData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                BalanceChartCard(
                  isLoading: _isLoadingBalance,
                  errorMessage: _errorMessage,
                  chartData: _chartSpotsIncome.map((e) => e.y).toList().isNotEmpty
                      ? _chartSpotsIncome.map((e) => e.y).toList()
                      : [0, 0, 0],
                  balance: _userBalance,
                ),
                const SizedBox(height: 24),

                FinancialGraph(
                  incomeSpots: _chartSpotsIncome,
                  expenseSpots: _chartSpotsExpense,
                  weekLabels: _labels,
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => pages[i]));
            },
          ),
        ),
      ),
    );
  }
}