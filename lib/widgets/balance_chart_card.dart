import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class BalanceChartCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<double> chartData;
  final String balance; // ✅ biar saldo tetap keliatan

  const BalanceChartCard({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.chartData,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        width: double.infinity,
        height: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // ✅ Putih clean
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header saldo
            Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Color(0xFF0F7ABB), size: 22),
                const SizedBox(width: 8),
                Text(
                  "Total Saldo",
                  style: GoogleFonts.manrope(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            isLoading
                ? Container(
                    width: 120,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                : errorMessage != null
                    ? Text(
                        "Error",
                        style: GoogleFonts.manrope(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : Text(
                        balance,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF0F7ABB),
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                      ),
            const SizedBox(height: 16),

            // 🔹 Chart line saldo
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (chartData.length - 1).toDouble(),
                  minY: chartData.isEmpty
                      ? 0
                      : chartData.reduce((a, b) => a < b ? a : b),
                  maxY: chartData.isEmpty
                      ? 0
                      : chartData.reduce((a, b) => a > b ? a : b),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        chartData.length,
                        (i) => FlSpot(i.toDouble(), chartData[i]),
                      ),
                      isCurved: true,
                      color: const Color(0xFF0F7ABB),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F7ABB).withOpacity(0.3),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
