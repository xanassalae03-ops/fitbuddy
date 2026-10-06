import 'package:flutter/material.dart'; 
import 'db_helper.dart'; 
 
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
 
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
 
  @override 
  _ShopPageState createState() => _ShopPageState(); 
} 
 
class _ShopPageState extends State<ShopPage> { 
  final TextEditingController _catController = 
TextEditingController(); 
  final TextEditingController _prodController = 
TextEditingController(); 
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
    if (_prodController.text.isNotEmpty && _selectedCategoryId != 
null) { 
      await DBHelper.insertProduct(_prodController.text, 
_selectedCategoryId!); 
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
            Text("Products with Category", style: TextStyle(fontSize: 
18, fontWeight: FontWeight.bold)), 

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