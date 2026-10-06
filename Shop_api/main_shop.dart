import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShopPage(),
    );
  }
}

/// ===================== DB HELPER (PHP + MySQL ผ่าน HTTP) =====================
class DBHelper {
  // เปลี่ยน path ให้ตรงกับตำแหน่งที่อัพโหลด api.php บนเซิร์ฟเวอร์จริง
  static const String baseUrl =
      "https://std.mcs.psu.ac.th/6620310242/html/shop/api_shop.php";

  /// Insert Category
  static Future<int> insertCategory(String name) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {"action": "create_category", "name": name},
    );
    final data = json.decode(res.body);
    return data['status'] == 'success' ? int.parse(data['id'].toString()) : -1;
  }

  /// Insert Product linked to a Category
  static Future<int> insertProduct(String name, int categoryId) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "action": "create_product",
        "name": name,
        "category_id": categoryId.toString(),
      },
    );
    final data = json.decode(res.body);
    return data['status'] == 'success' ? int.parse(data['id'].toString()) : -1;
  }

  /// Get all Categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await http.get(Uri.parse("$baseUrl?action=read_categories"));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data
          .map<Map<String, dynamic>>((row) => {
                "id": int.parse(row['id'].toString()),
                "name": row['name'],
              })
          .toList();
    }
    return [];
  }

  /// Get Products with Category Name (JOIN)
  static Future<List<Map<String, dynamic>>> getProductsWithCategory() async {
    final res = await http.get(Uri.parse("$baseUrl?action=read_products"));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data
          .map<Map<String, dynamic>>((row) => {
                "id": int.parse(row['id'].toString()),
                "name": row['name'],
                "category_name": row['category_name'],
              })
          .toList();
    }
    return [];
  }

  /// Delete a Product by id
  static Future<int> deleteProduct(int id) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {"action": "delete_product", "id": id.toString()},
    );
    final data = json.decode(res.body);
    return data['status'] == 'success' ? 1 : 0;
  }
}

/// ===================== UI (เหมือนเดิมทุกอย่าง) =====================
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final TextEditingController _catController = TextEditingController();
  final TextEditingController _prodController = TextEditingController();
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  /// Load all categories
  Future<void> _loadCategories() async {
    final data = await DBHelper.getCategories();
    setState(() {
      _categories = data;
    });
  }

  /// Load all products with category names
  Future<void> _loadProducts() async {
    final data = await DBHelper.getProductsWithCategory();
    setState(() {
      _products = data;
    });
  }

  /// Add new category
  Future<void> _addCategory() async {
    if (_catController.text.isNotEmpty) {
      await DBHelper.insertCategory(_catController.text);
      _catController.clear();
      _loadCategories();
    }
  }

  /// Add new product linked to a category
  Future<void> _addProduct() async {
    if (_prodController.text.isNotEmpty && _selectedCategoryId != null) {
      await DBHelper.insertProduct(_prodController.text, _selectedCategoryId!);
      _prodController.clear();
      _loadProducts();
    }
  }

  /// Delete a product then refresh the list
  Future<void> _deleteProduct(int id) async {
    await DBHelper.deleteProduct(id);
    _loadProducts();
  }

  /// Group the flat product list into { categoryName: [products] }
  /// Starts from _categories so categories with zero products still show up.
  Map<String, List<Map<String, dynamic>>> _groupByCategory() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    // Seed every known category first (even if it has no products yet)
    for (final category in _categories) {
      grouped[category['name']] = [];
    }

    // Then fill in products under their matching category
    for (final product in _products) {
      final String catName = product['category_name'] ?? 'ไม่มีหมวดหมู่';
      grouped.putIfAbsent(catName, () => []);
      grouped[catName]!.add(product);
    }
    return grouped;
  }

@override
Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(title: Text("Shop Example (Category & Product)")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add Category
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _catController,
                decoration: InputDecoration(
                  labelText: 'New Category',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addCategory,
                  ),
                ),
              ),
            ),

            // Add Product (requires category selection)
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  DropdownButton<int>(
                    value: _selectedCategoryId,
                    hint: Text("Select Category"),
                    items: _categories
                        .map((cat) => DropdownMenuItem<int>(
                              value: cat['id'],
                              child: Text(cat['name']),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                  TextField(
                    controller: _prodController,
                    decoration: InputDecoration(
                      labelText: 'New Product',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _addProduct,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(),
            Text("Products with Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            // Show Products grouped by category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _groupByCategory().entries.map((entry) {
                  final String categoryName = entry.key;
                  final List<Map<String, dynamic>> productsInCategory = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      if (productsInCategory.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Text(
                            "ยังไม่มีสินค้า",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...productsInCategory.asMap().entries.map((p) {
                          final int number = p.key + 1;
                          final Map<String, dynamic> product = p.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text("$number. ${product['name']}"),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteProduct(product['id']),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}