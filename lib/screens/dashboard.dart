import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/screens/pemasukan.dart';
import 'package:flutter_application_1/screens/pengeluaran.dart';
import 'package:flutter_application_1/screens/keuangan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screens/category.dart';
import 'package:flutter_application_1/screens/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  bool _isLoadingBalance = true;
  String _userName = 'Admin';
  String _userBalance = 'Rp0';
  String? _errorMessage;

  List<FlSpot> _chartSpotsIncome = [];
  List<FlSpot> _chartSpotsExpense = [];
  List<String> _weekLabels = [];

  int currentIndex = 0;

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

      // 🔹 Profile
      final profileRes = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 🔹 Balances
      final balancesRes = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/balances'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 🔹 Charts
      final chartRes = await http.get(
        Uri.parse('https://smartbookkeeper.id/api/dashboard/charts'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (profileRes.statusCode == 200 &&
          balancesRes.statusCode == 200 &&
          chartRes.statusCode == 200) {
        final profileData = json.decode(profileRes.body);
        final balancesData = json.decode(balancesRes.body);
        final chartData = json.decode(chartRes.body);

        // 🔹 Nama user
        final userName = profileData['data']?['name'] ?? 'User';

        // 🔹 Hitung total saldo dari semua dompet
        num totalBalance = 0;
        if (balancesData['data'] is List) {
          for (var b in balancesData['data']) {
            totalBalance += num.tryParse(b['current_amount'].toString()) ?? 0;
          }
        }

        // 🔹 Format keuangan
        String formattedBalance = _formatCurrency(totalBalance);

        // 🔹 Parse data chart weekly
        List<dynamic> weeklyData = [];
        if (chartData['data'] != null &&
            chartData['data']['weekly_data'] is List) {
          weeklyData = chartData['data']['weekly_data'];
        }

        List<FlSpot> incomeSpots = [];
        List<FlSpot> expenseSpots = [];
        List<String> weekLabels = [];

        for (int i = 0; i < weeklyData.length; i++) {
          final w = weeklyData[i];
          weekLabels.add(w['week']);
          incomeSpots.add(FlSpot(i.toDouble() + 1,
              double.tryParse(w['income'].toString()) ?? 0));
          expenseSpots.add(FlSpot(i.toDouble() + 1,
              double.tryParse(w['expense'].toString()) ?? 0));
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
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoadingBalance = false;
      });
    }
  }

  /// 🔹 Format angka ke format ribuan
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

  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 37.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello,",
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                      fontSize: 20.0)),
              _isLoadingBalance
                  ? Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4)))
                  : Text(_userName,
                      style: GoogleFonts.manrope(
                          fontSize: 15.0,
                          color: Colors.black,
                          fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _isLoadingBalance ? null : _refreshData,
                icon: _isLoadingBalance
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh,
                        color: Color(0xFF0F7ABB), size: 28),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout,
                    color: Color(0xFF0F7ABB), size: 28),
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Container(
      width: double.infinity,
      height: 160, // ✅ Lebih ramping
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F7ABB), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Saldo Saat Ini",
            style: GoogleFonts.manrope(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(height: 10),
          _isLoadingBalance
              ? Container(
                  width: 140,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              : _errorMessage != null
                  ? Text(
                      "Error",
                      style: GoogleFonts.manrope(
                        color: Colors.red[100],
                        fontWeight: FontWeight.w600,
                        fontSize: 20.0,
                      ),
                    )
                  : Text(
                      _userBalance,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 28.0,
                        letterSpacing: -0.5,
                      ),
                    ),
        ],
      ),
    ),
  );
}

  SideTitles weeksBottomTitle() {
    return SideTitles(
      showTitles: true,
      interval: 1,
      getTitlesWidget: (value, meta) {
        int index = value.toInt() - 1;
        if (index >= 0 && index < _weekLabels.length) {
          return Transform.rotate(
            angle: -0.5, // miring biar tidak tabrakan
            child: Text(
              _weekLabels[index],
              style: GoogleFonts.manrope(fontSize: 10),
            ),
          );
        }
        return const Text('');
      },
    );
  }

Widget _buildFinancialGraphSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Grafik Keuangan",
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700, fontSize: 16.0)),
        const SizedBox(height: 10),

        // 🔹 Legend
        Row(
          children: [
            Row(children: [
              Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text("Income", style: GoogleFonts.manrope(fontSize: 13)),
            ]),
            const SizedBox(width: 20),
            Row(children: [
              Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text("Expense", style: GoogleFonts.manrope(fontSize: 13)),
            ]),
          ],
        ),
        const SizedBox(height: 16),

        // 🔹 Grafik Card
        Container(
          height: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 8,
                  offset: Offset(0, 4))
            ],
          ),
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.white,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 200000, // 🔹 ubah sesuai range nominal
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

                // 🔹 Label minggu miring
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt() - 1;
                      if (index >= 0 && index < _weekLabels.length) {
                        return Transform.rotate(
                          angle: -0.6, // ~45 derajat
                          child: Text(
                            _weekLabels[index],
                            style: GoogleFonts.manrope(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // 🔹 Label sumbu kiri
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: 200000, // 🔹 step angka
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "Rp ${_formatCurrency(value.toInt())}",
                        style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey[700]),
                      );
                    },
                  ),
                ),
              ),

              borderData: FlBorderData(show: false),

              lineBarsData: [
                // 🔹 Income line
                LineChartBarData(
                  spots: _chartSpotsIncome.isNotEmpty ? _chartSpotsIncome : [FlSpot(0, 0)],
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(radius: 3, color: Colors.green, strokeWidth: 0),
                  ),
                ),
                // 🔹 Expense line
                LineChartBarData(
                  spots: _chartSpotsExpense.isNotEmpty ? _chartSpotsExpense : [FlSpot(0, 0)],
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(radius: 3, color: Colors.red, strokeWidth: 0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
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

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
            color: Color.fromRGBO(0, 122, 187, 1.0),
            borderRadius:
                BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        child: NavigationBar(
          backgroundColor: const Color.fromRGBO(0, 122, 187, 1.0),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home, color: Colors.white), label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.add_circle, color: Colors.white),
                label: 'Pemasukan'),
            NavigationDestination(
                icon: Icon(Icons.remove_circle, color: Colors.white),
                label: 'Pengeluaran'),
            NavigationDestination(
                icon: Icon(Icons.note_rounded, color: Colors.white),
                label: 'Keuangan'),
            NavigationDestination(
                icon: Icon(Icons.category, color: Colors.white),
                label: 'Kategori'),
          ],
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) {
            setState(() => currentIndex = index);
            if (index != 0) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => pages[index]));
            }
          },
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          height: 60,
          indicatorColor: Colors.white.withOpacity(0.2),
          surfaceTintColor: Colors.white,
          elevation: 0,
          labelTextStyle:
              WidgetStateProperty.resolveWith((_) => const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout')),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 39),
                  _buildGreetingSection(),
                  const SizedBox(height: 20),
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildFinancialGraphSection(),
                ],
              ),
            ),
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _buildNavigationBar()),
      ]),
    );
  }
}
