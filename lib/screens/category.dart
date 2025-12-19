import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Screens
import 'dashboard.dart';
import 'pemasukan.dart';
import 'pengeluaran.dart';
import 'keuangan.dart';

// Widgets
import '../widgets/bottom_nav.dart';
import '../widgets/top_bar.dart'; // ✅ Import widget

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int currentIndex = 4; // ✅ Index Category
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedType = "income";
  String? _selectedIcon = "🍔";
  String? _selectedColor = "#007ABB";

  // Icons untuk kategori
  final List<String> _availableIcons = [
    "🍔",
    "🛒",
    "🚗",
    "🏠",
    "💊",
    "📚",
    "✈️",
    "🎮",
    "💰",
    "💸",
    "💳",
    "🏦",
    "📱",
    "💻",
    "👕",
    "🍕",
    "☕",
    "🎬",
    "🏋️",
    "🎵",
  ];

  // Warna untuk kategori
  final List<Map<String, String>> _availableColors = [
    {"name": "Biru", "value": "#007ABB"},
    {"name": "Merah", "value": "#DC3545"},
    {"name": "Hijau", "value": "#28A745"},
    {"name": "Orange", "value": "#FD7E14"},
    {"name": "Ungu", "value": "#6F42C1"},
    {"name": "Pink", "value": "#E83E8C"},
    {"name": "Cyan", "value": "#17A2B8"},
    {"name": "Kuning", "value": "#FFC107"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      final res = await http.get(
        Uri.parse("https://smartbookkeeper.id/api/categories"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data["data"] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      final res = await http.post(
        Uri.parse("https://smartbookkeeper.id/api/categories"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({
          "name": _nameController.text.trim(),
          "type": _selectedType,
          "icon": _selectedIcon,
          "color": _selectedColor,
        }),
      );

      if (res.statusCode == 201) {
        Navigator.pop(context);
        _nameController.clear();
        _fetchCategories();
        _showSnackBar("✅ Kategori berhasil ditambahkan", Colors.green);
      } else {
        final data = json.decode(res.body);
        _showSnackBar(data["message"] ?? "Gagal menambah kategori", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Kesalahan jaringan", Colors.red);
    }
  }

  Future<void> _updateCategory(int id) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      final res = await http.put(
        Uri.parse("https://smartbookkeeper.id/api/categories/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({
          "name": _nameController.text.trim(),
          "type": _selectedType,
          "icon": _selectedIcon,
          "color": _selectedColor,
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        _nameController.clear();
        _fetchCategories();
        _showSnackBar("✅ Kategori berhasil diupdate", Colors.green);
      } else {
        final data = json.decode(res.body);
        _showSnackBar(data["message"] ?? "Gagal update kategori", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Kesalahan jaringan", Colors.red);
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      final res = await http.delete(
        Uri.parse("https://smartbookkeeper.id/api/categories/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        _fetchCategories();
        _showSnackBar("✅ Kategori berhasil dihapus", Colors.green);
      } else {
        final data = json.decode(res.body);
        _showSnackBar(data["message"] ?? "Gagal hapus kategori", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Kesalahan jaringan", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showCreateCategoryModal() {
    _nameController.clear();
    _selectedType = "income";
    _selectedIcon = "🍔";
    _selectedColor = "#007ABB";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCategoryModal(
        title: "Tambah Kategori",
        onSubmit: _createCategory,
      ),
    );
  }

  void _showEditCategoryModal(Map<String, dynamic> category) {
    _nameController.text = category["name"];
    _selectedType = category["type"];
    _selectedIcon = category["icon"] ?? "🍔";
    _selectedColor = category["color"] ?? "#007ABB";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCategoryModal(
        title: "Edit Kategori",
        onSubmit: () => _updateCategory(category["id"]),
      ),
    );
  }

  Widget _buildCategoryModal({
    required String title,
    required VoidCallback onSubmit,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F7ABB),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey[700],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nama Kategori
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Nama Kategori",
                    hintText: "Contoh: Makan, Transport, dll",
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Color(0xFF0F7ABB),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F7ABB),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? "Masukkan nama kategori"
                      : null,
                ),
                const SizedBox(height: 20),

                // Tipe Kategori
                Text(
                  "Tipe Kategori",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = "income"),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedType == "income"
                                  ? const Color(0xFF0F7ABB).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              border: _selectedType == "income"
                                  ? Border(
                                      right: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: _selectedType == "income"
                                      ? const Color(0xFF0F7ABB)
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Pemasukan",
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedType == "income"
                                        ? const Color(0xFF0F7ABB)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedType = "expense"),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedType == "expense"
                                  ? const Color(0xFF0F7ABB).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_down,
                                  color: _selectedType == "expense"
                                      ? const Color(0xFF0F7ABB)
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Pengeluaran",
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedType == "expense"
                                        ? const Color(0xFF0F7ABB)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pilih Icon
                Text(
                  "Pilih Icon",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = _availableIcons[index];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedIcon == icon
                                  ? const Color(0xFF0F7ABB)
                                  : Colors.grey[300]!,
                              width: _selectedIcon == icon ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: _selectedIcon == icon
                                ? const Color(0xFF0F7ABB).withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Pilih Warna
                Text(
                  "Pilih Warna",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableColors.length,
                    itemBuilder: (context, index) {
                      final color = _availableColors[index];
                      final colorValue = Color(
                        int.parse(color["value"]!.replaceAll('#', '0xFF')),
                      );

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColor = color["value"]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedColor == color["value"]
                                  ? Colors.black
                                  : Colors.grey[300]!,
                              width: _selectedColor == color["value"] ? 3 : 1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            backgroundColor: colorValue,
                            radius: 18,
                            child: _selectedColor == color["value"]
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(
                          int.parse(_selectedColor!.replaceAll('#', '0xFF')),
                        ).withOpacity(0.2),
                        radius: 20,
                        child: Text(
                          _selectedIcon ?? "❓",
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? "Nama Kategori"
                                : _nameController.text,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Tipe: ${_selectedType == "income" ? "Pemasukan" : "Pengeluaran"}",
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7ABB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      title == "Tambah Kategori"
                          ? "Buat Kategori"
                          : "Update Kategori",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeCount = _categories.where((c) => c["type"] == "income").length;
    final expenseCount = _categories.where((c) => c["type"] == "expense").length;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      // ✅ GANTI: NestedScrollView dengan AppBar TopBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: TopBar(
          title: "Kategori",
          showBackButton: true,
          showMenuButton: true,
          onRefresh: _fetchCategories,
          onLogout: _logout,
          backgroundColor: Colors.grey[200]!,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchCategories,
                  color: const Color(0xFF0F7ABB),
                  child: CustomScrollView(
                    slivers: [
                      // Summary Card
                      SliverToBoxAdapter(
                        child: _buildSummaryCard(incomeCount, expenseCount),
                      ),

                      // Kategori List
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final category = _categories[index];
                            return _buildCategoryCard(category);
                          }, childCount: _categories.length),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCategoryModal,
        backgroundColor: const Color(0xFF0F7ABB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Kategori',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,
        onTap: (i) {
          setState(() => currentIndex = i);
          final pages = [
            const Dashboard(),
            const Pemasukan(),
            const Pengeluaran(),
            const Keuangan(),
            const CategoryScreen(),
          ];
          if (i != 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => pages[i]),
            );
          }
        },
      ),
    );
  }

  // ✅ TAMBAH: Method logout
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F7ABB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_outlined,
              size: 64,
              color: const Color(0xFF0F7ABB).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum Ada Kategori",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Buat kategori pertama untuk\nmengorganisir transaksi Anda",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateCategoryModal,
            icon: const Icon(Icons.add),
            label: Text(
              'Buat Kategori',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F7ABB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int incomeCount, int expenseCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F7ABB), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F7ABB).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Kategori',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${incomeCount + expenseCount}',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBadge(
                'Pemasukan',
                incomeCount.toString(),
                Icons.trending_up,
              ),
              _buildStatBadge(
                'Pengeluaran',
                expenseCount.toString(),
                Icons.trending_down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final colorValue = Color(
      int.parse((category["color"] ?? "#007ABB").replaceAll('#', '0xFF')),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 246, 246, 247),
              const Color.fromARGB(255, 221, 221, 221),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorValue.withOpacity(0.2),
                radius: 28,
                child: Text(
                  category["icon"] ?? "❓",
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category["name"] ?? "-",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: category["type"] == "income"
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category["type"] == "income"
                                ? "Pemasukan"
                                : "Pengeluaran",
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: category["type"] == "income"
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorValue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditCategoryModal(category);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(category);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          color: Color(0xFF0F7ABB),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Hapus',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Kategori?"),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category["name"]}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category["id"]);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
