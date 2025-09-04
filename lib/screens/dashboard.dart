import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart for financial graph
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_application_1/screens/pemasukan.dart';
import 'package:flutter_application_1/screens/pengeluaran.dart';
import 'package:flutter_application_1/screens/keuangan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screens/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  // Add these state variables
  bool _isLoadingBalance = true;
  String _userName = 'Admin';
  String _userBalance = 'Rp0';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserBalance();
  }

  // Add this method to fetch user balance
  Future<void> _fetchUserBalance() async {
    setState(() {
      _isLoadingBalance = true;
      _errorMessage = null;
    });

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        // No token found, redirect to login
        _logout();
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/total-balance'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          _userName = responseData['name'] ?? 'Admin';
          _userBalance = 'Rp${responseData['balance'] ?? '0'}';
          _isLoadingBalance = false;
        });
      } else if (response.statusCode == 401) {
        // Token expired or invalid, logout user
        _logout();
      } else {
        setState(() {
          _errorMessage = 'Failed to load balance data';
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

  // Add refresh method
  Future<void> _refreshData() async {
    await _fetchUserBalance();
  }

  // * Widget untuk hello admin
  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 37.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello,",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                  fontSize: 20.0,
                ),
              ),
              _isLoadingBalance
                  ? Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Text(
                      _userName,
                      style: GoogleFonts.manrope(
                        fontSize: 24.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ],
          ),
          Row(
            children: [
              // Refresh button
              IconButton(
                onPressed: _isLoadingBalance ? null : _refreshData,
                icon: _isLoadingBalance
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Color(0xFF0F7ABB),
                        size: 28,
                      ),
                tooltip: 'Refresh',
              ),
              // Logout button
              IconButton(
                onPressed: _logout,
                icon: const Icon(
                  Icons.logout,
                  color: Color(0xFF0F7ABB),
                  size: 28,
                ),
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // * widget untuk informasi sisa saldo
  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        width: 365.0,
        height: 270.0,
        decoration: BoxDecoration(
          color: const Color(0xFF007ABB),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 22),
              child: Text(
                "Saldo Saat Ini",
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  fontSize: 12.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 1),
              child: _isLoadingBalance
                  ? Container(
                      width: 200,
                      height: 36,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : _errorMessage != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Error loading balance",
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.manrope(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w300,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _userBalance,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 36.0,
                            letterSpacing: -0.2,
                          ),
                        ),
            ),
            // Show retry button if there's an error
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 8),
                child: ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            // Existing navigation buttons
            if (_errorMessage == null) ...[
              Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 0),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Pemasukan(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle),
                          iconSize: 40,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      Text(
                        "Catat Pemasukan",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 0),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Pengeluaran(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.remove_circle),
                          iconSize: 40,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      Text(
                        "Catat Pengeluaran",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // * fungsi untuk menampilkan judul bulan di bawah grafik keuangan
  SideTitles monthsOfyearBottomTitle() {
    return SideTitles(
      showTitles: true,
      interval: 1,
      getTitlesWidget: (value, meta) {
        String text = '';
        switch (value.toInt()) {
          case 1:
            text = 'Jan';
            break;
          case 2:
            text = 'Feb';
            break;
          case 3:
            text = 'Mar';
            break;
          case 4:
            text = 'Apr';
            break;
          case 5:
            text = 'Mei';
            break;
          case 6:
            text = 'Jun';
            break;
          case 7:
            text = 'Jul';
            break;
          case 8:
            text = 'Agu';
            break;
          case 9:
            text = 'Sep';
            break;
          case 10:
            text = 'Okt';
            break;
          case 11:
            text = 'Nov';
            break;
          case 12:
            text = 'Des';
            break;
        }
        return Text(
          text,
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  // * widget untuk grafik keuangan
  Widget _buildFinancialGraphSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96.0 + 40,
            height: 30,
            child: Text(
              "Grafik Keuangan",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w900,
                color: const Color.fromRGBO(0, 0, 0, 1.0),
                fontSize: 16.0,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Container(
            width: 365.0,
            height: 240.0,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 240, 239, 239),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 10,
                top: 32,
                right: 42,
                bottom: 16,
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text('Bulan'),
                      sideTitles: monthsOfyearBottomTitle(),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Juta - Rp'),
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: false),

                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(1, 1),
                        FlSpot(3, 2),
                        FlSpot(5, 5),
                        FlSpot(7, 5),
                      ],
                      isCurved: true,
                      barWidth: 3,
                      color: (Colors.blue),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // * widget untuk navigasi bar
  int currentIndex = 0;

  Widget _buildNavigationBar() {
    // List of pages to display
    final List<Widget> pages = [
      const Dashboard(), // Beranda
      const Pemasukan(), // Pemasukan page
      const Pengeluaran(), // Pengeluaran page
      const Keuangan(), // Keuangan page
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0, 122, 187, 1.0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        child: NavigationBar(
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
          ],
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              currentIndex = index;
            });

            // Navigate to the selected page
            if (index != 0) {
              // Don't navigate if we're already on Dashboard
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => pages[index]),
              );
            }
          },
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          height: 60,
          indicatorColor: Colors.white.withOpacity(0.2),
          surfaceTintColor: Colors.white,
          elevation: 0,
          // Add these properties to change label color
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return const TextStyle(color: Colors.white);
          }),
        ),
      ),
    );
  }

  // Add this logout method to your DashboardState class
  Future<void> _logout() async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Remove token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      // Navigate back to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // Updated build method with pull-to-refresh
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scrollable content with pull-to-refresh
          RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 180,
                ), // Padding for navigation bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 39),
                    _buildGreetingSection(),
                    const SizedBox(height: 20),
                    _buildBalanceCard(),
                    const SizedBox(height: 20),
                    // _buildTotalRevenueSection(),
                    const SizedBox(height: 20),
                    _buildFinancialGraphSection(),
                  ],
                ),
              ),
            ),
          ),

          // Fixed navigation bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildNavigationBar(),
          ),
        ],
      ),
    );
  }

  // Rest of your existing methods remain the same...
}
