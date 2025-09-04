import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard.dart';
import 'package:flutter_application_1/screens/pemasukan.dart';
import 'package:flutter_application_1/screens/keuangan.dart';

class Pengeluaran extends StatefulWidget {
  const Pengeluaran({super.key});

  @override
  State<Pengeluaran> createState() => PengeluaranState();
}

class PengeluaranState extends State<Pengeluaran> {
  int currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        backgroundColor: const Color.fromRGBO(0, 122, 187, 1.0),
      ),
      body: const Center(child: Text('Ini halaman Pengeluaran')),
      bottomNavigationBar: NavigationBar(
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
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Keuangan()),
              );
              break;
            case 4:
              // Already on Keuangan page
              break;
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
    );
  }
}
