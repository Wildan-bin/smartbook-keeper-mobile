import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialGraph extends StatelessWidget {
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final List<String> weekLabels;
  final String Function(dynamic) formatCurrency;

  const FinancialGraph({
    super.key,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.weekLabels,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Judul + Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart,
                    color: Color(0xFF0F7ABB),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Grafik Keuangan",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.0,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegend(Colors.green, "Income"),
                  const SizedBox(width: 12),
                  _buildLegend(Colors.red, "Expense"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🔹 Bar Chart
          SizedBox(
            height: screenHeight * 0.35,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 200000,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int i = value.toInt();
                          
                          // ✅ Hanya tampilkan label jika ada data
                          final hasIncome = i < incomeSpots.length && incomeSpots[i].y > 0;
                          final hasExpense = i < expenseSpots.length && expenseSpots[i].y > 0;
                          
                          if (i >= 0 && i < weekLabels.length && (hasIncome || hasExpense)) {
                            return Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                weekLabels[i],
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  color: Colors.grey[700],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: 500000,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text("");
                          String text;
                          if (value >= 1000000) {
                            text = "Rp ${(value / 1000000).toStringAsFixed(1)}M";
                          } else if (value >= 1000) {
                            text = "Rp ${(value / 1000).toStringAsFixed(0)}K";
                          } else {
                            text = "Rp ${value.toInt()}";
                          }
                          return Text(
                            text,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(weekLabels.length, (i) {
                    final incomeY = i < incomeSpots.length
                        ? incomeSpots[i].y
                        : 0.0;
                    final expenseY = i < expenseSpots.length
                        ? expenseSpots[i].y
                        : 0.0;

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: incomeY,
                          color: Colors.green,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: expenseY,
                          color: Colors.red,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      barsSpace: 6,
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 11, color: Colors.black87),
        ),
      ],
    ),
  );
}
