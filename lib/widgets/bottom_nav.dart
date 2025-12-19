import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {"icon": Icons.home, "label": "Beranda"},
      {"icon": Icons.add_circle, "label": "Pemasukan"},
      {"icon": Icons.remove_circle, "label": "Pengeluaran"},
      {"icon": Icons.note_rounded, "label": "Keuangan"},
      {"icon": Icons.category, "label": "Kategori"},
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        color: Color(0xFF0F7ABB),
          gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 24, 124, 187), Color.fromARGB(255, 3, 89, 165)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isActive = currentIndex == index;
          return GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  items[index]["icon"] as IconData,
                  size: 24,
                  color: isActive ? Colors.white : Colors.white70,
                ),
                const SizedBox(height: 2),
                Text(
                  items[index]["label"] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
