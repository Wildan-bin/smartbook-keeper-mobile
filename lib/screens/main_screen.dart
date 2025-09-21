import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'pemasukan.dart';
import 'pengeluaran.dart';
import 'keuangan.dart';
import 'category.dart';
import '../widgets/bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final _pages = const [
    Dashboard(),
    Pemasukan(),
    Pengeluaran(),
    Keuangan(),
    CategoryScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // biar pindah cuma lewat nav
        children: _pages,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
