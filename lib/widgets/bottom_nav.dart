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
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF0F7ABB),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          )
        ],
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
