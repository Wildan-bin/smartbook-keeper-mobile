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
import '../widgets/add_category_modal.dart';
import '../widgets/bottom_nav.dart';

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
        headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
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
          "Accept": "application/json"
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
        _selectedType = "income";
        _selectedIcon = "🍔";
        _selectedColor = "#007ABB";
        _fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Kategori berhasil ditambahkan")),
        );
      } else {
        final data = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Gagal menambah kategori")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showCreateCategoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return AddCategoryModal(
          formKey: _formKey,
          nameController: _nameController,
          selectedType: _selectedType,
          selectedIcon: _selectedIcon,
          selectedColor: _selectedColor,
          isLoading: _isLoading,
          onTypeChanged: (val) => setState(() => _selectedType = val),
          onIconChanged: (val) => setState(() => _selectedIcon = val),
          onColorChanged: (val) => setState(() => _selectedColor = val),
          onSubmit: _createCategory,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(0, 122, 187, 1.0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _fetchCategories,
            icon: const Icon(Icons.refresh, color: Colors.white),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Text(
                    "Belum ada kategori",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) {
                    final c = _categories[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(int.parse((c["color"] ?? "#CCCCCC").replaceAll('#', '0xFF'))).withOpacity(0.2),
                          child: Text(
                            c["icon"] ?? "❓",
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(
                          c["name"] ?? "-",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          "Tipe: ${c["type"]}",
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(int.parse((c["color"] ?? "#CCCCCC").replaceAll('#', '0xFF'))),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F7ABB),
        onPressed: _showCreateCategoryModal,
        child: const Icon(Icons.add, color: Colors.white),
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
}