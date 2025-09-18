import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/dashboard.dart';
import 'package:flutter_application_1/screens/pemasukan.dart';
import 'package:flutter_application_1/screens/pengeluaran.dart';
import 'package:flutter_application_1/screens/keuangan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int currentIndex = 4; // ✅ Index 4 untuk Category
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

  /// 🔹 Ambil kategori dari API
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

  /// 🔹 Tambah kategori
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

  /// 🔹 Modal tambah kategori
  void _showCreateCategoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  "Tambah Kategori",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),

                // Nama kategori
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Kategori",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Masukkan nama kategori" : null,
                ),
                const SizedBox(height: 16),

                // Tipe kategori
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: "income", child: Text("Income")),
                    DropdownMenuItem(value: "expense", child: Text("Expense")),
                  ],
                  onChanged: (val) => setState(() => _selectedType = val),
                  decoration: const InputDecoration(
                    labelText: "Tipe",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Pilih Icon
                DropdownButtonFormField<String>(
                  value: _selectedIcon,
                  items: ["🍔", "📚", "💼", "🚗", "🏠", "🎉"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 20))))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedIcon = val),
                  decoration: const InputDecoration(
                    labelText: "Icon",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Pilih Warna
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  items: ["#007ABB", "#FF9800", "#4CAF50", "#F44336"]
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  color: Color(int.parse(e.replaceAll('#', '0xFF'))),
                                ),
                                const SizedBox(width: 8),
                                Text(e),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedColor = val),
                  decoration: const InputDecoration(
                    labelText: "Warna",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _createCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F7ABB),
                  ),
                  child: const Text(
                    "Simpan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Bottom Navigation (sama seperti Dashboard)
  Widget _buildNavigationBar() {
    final List<Widget> pages = [
      const Dashboard(),
      const Pemasukan(),
      const Pengeluaran(),
      const Keuangan(),
      const CategoryScreen(),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0, 122, 187, 1.0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: NavigationBar(
        backgroundColor: const Color.fromRGBO(0, 122, 187, 1.0),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home, color: Colors.white), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.add_circle, color: Colors.white), label: 'Pemasukan'),
          NavigationDestination(icon: Icon(Icons.remove_circle, color: Colors.white), label: 'Pengeluaran'),
          NavigationDestination(icon: Icon(Icons.note_rounded, color: Colors.white), label: 'Keuangan'),
          NavigationDestination(icon: Icon(Icons.category, color: Colors.white), label: 'Kategori'),
        ],
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => pages[index]),
          );
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 60,
        indicatorColor: Colors.white.withOpacity(0.2),
        surfaceTintColor: Colors.white,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
            (_) => const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    'Kategori',
    style: TextStyle(color: Colors.white),
  ),
  backgroundColor: const Color.fromRGBO(0, 122, 187, 1.0),
  iconTheme: const IconThemeData(color: Colors.white), // ✅ bikin back arrow putih
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
              ? const Center(child: Text("Belum ada kategori"))
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) {
                    final c = _categories[i];
                    return ListTile(
                      leading: Text(c["icon"] ?? "❓", style: const TextStyle(fontSize: 24)),
                      title: Text(c["name"] ?? "-"),
                      subtitle: Text("Type: ${c["type"]}"),
                      trailing: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(int.parse((c["color"] ?? "#CCCCCC").replaceAll('#', '0xFF'))),
                          shape: BoxShape.circle,
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
      bottomNavigationBar: _buildNavigationBar(),
    );
  }
}
