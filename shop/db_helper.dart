import 'package:sqflite/sqflite.dart'; 
import 'package:path/path.dart'; 

class DBHelper { 
static Database? _db;
/// Initialize database (create/open) 
  static Future<Database> initDb() async { 
    if (_db != null) return _db!; 
    String path = join(await getDatabasesPath(), 'shop.db'); 
 
    _db = await openDatabase( 
      path, 
      version: 1, 
      onCreate: (db, version) async { 
        // Create Categories table 
        await db.execute(''' 
          CREATE TABLE categories( 
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            name TEXT 
          ) 
        '''); 
 
        // Create Products table with foreign key to categories 
        await db.execute(''' 
          CREATE TABLE products( 
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            name TEXT, 
            category_id INTEGER, 
            FOREIGN KEY (category_id) REFERENCES categories(id) ON 
DELETE CASCADE 
          ) 
        '''); 
      }, 
    ); 
    return _db!; 
  } 
 
  /// Insert Category 
  static Future<int> insertCategory(String name) async { 
    final db = await initDb(); 
    return await db.insert('categories', {'name': name});
     } 
 
  /// Insert Product linked to a Category 
  static Future<int> insertProduct(String name, int categoryId) async 
{ 
    final db = await initDb(); 
    return await db.insert('products', {'name': name, 'category_id': 
categoryId}); 
  } 
 
  /// Get all Categories 
  static Future<List<Map<String, dynamic>>> getCategories() async { 
    final db = await initDb(); 
    return await db.query('categories'); 
  } 
 
  /// Get Products with Category Name (JOIN) 
  static Future<List<Map<String, dynamic>>> getProductsWithCategory() 
async { 
    final db = await initDb(); 
    return await db.rawQuery(''' 
      SELECT products.id, products.name, categories.name AS 
category_name 
      FROM products 
      INNER JOIN categories ON products.category_id = categories.id 
    '''); 
  }

  /// Delete a Product by id
  static Future<int> deleteProduct(int id) async {
    final db = await initDb();
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  } 
}