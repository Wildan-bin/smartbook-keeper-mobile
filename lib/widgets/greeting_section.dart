import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GreetingSection extends StatelessWidget {
  final String userName;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const GreetingSection({
    super.key,
    required this.userName,
    required this.isLoading,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12), // ✅ kasih margin atas
      height: 70, // ✅ fix tipis & elegan
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0F7ABB), // ✅ full biru tanpa rounded
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔹 Greeting + Avatar
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              isLoading
                  ? Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Hello 👋",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          userName,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ],
          ),

          // 🔹 Action buttons
          Row(
            children: [
              _buildIconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh,
                        color: Colors.white, size: 18),
                onTap: isLoading ? null : onRefresh,
              ),
              const SizedBox(width: 6),
              _buildIconButton(
                icon: const Icon(Icons.logout,
                    color: Colors.white, size: 18),
                onTap: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required Widget icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: icon),
      ),
    );
  }
}
