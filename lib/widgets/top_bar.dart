import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screens/login.dart';
import 'package:flutter_application_1/screens/dashboard.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final bool showBackButton;
  final bool showMenuButton;

  const TopBar({
    super.key,
    required this.title,
    this.onRefresh,
    this.onLogout,
    this.onBack,
    this.backgroundColor = const Color.fromRGBO(238, 238, 238, 1),
    this.showBackButton = true,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      surfaceTintColor: Color.fromRGBO(238, 238, 238, 1),
      toolbarHeight: 100.0,
      leading: null,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Back Button
            if (showBackButton)
              Container(
                // padding: const EdgeInsets.all(1),
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(255, 130, 129, 129),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black87,
                    size: 16,
                  ),
                  onPressed:
                      onBack ??
                      () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Dashboard()),
                        );
                      },
                  tooltip: 'Kembali ke Dashboard',
                  padding: EdgeInsets.zero,
                ),
              )
            else
              const SizedBox(width: 40),

            // ✅ Title (Center)
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 24,
                  ),
                ),
              ),
            ),

            // ✅ Menu Button
            if (showMenuButton)
              Container(
                // padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(255, 130, 129, 129),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                width: 45,
                height: 45,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'refresh') {
                      onRefresh?.call();
                    } else if (value == 'logout') {
                      // ✅ UBAH: Panggil fungsi logout baru
                      _handleLogout(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: Color(0xFF0F7ABB),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Refresh',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.black87,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                ),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  /// ✅ UBAH: Logout function sama seperti Dashboard
  Future<void> _handleLogout(BuildContext context) async {
    // ✅ Tampilkan dialog konfirmasi terlebih dahulu
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin mau keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // ✅ Jika user confirm logout
    if (shouldLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error logout: $e');
      }
    }
  }
}
