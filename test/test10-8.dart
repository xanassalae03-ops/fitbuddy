import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
 
class DBHelper {
  static Database? _db;
 
  // Initialize Database
  static Future<Database> initDb() async {
    if (_db != null) {
      return _db!;
    }
 
    final String dbPath = join(
      await getDatabasesPath(),
      'mydb.db',
    );
 
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
      },
    );
 
    return _db!;
  }
 
  // Insert User
  static Future<int> insertUser(String name) async {
    final db = await initDb();
 
    return await db.insert(
      'users',
      {
        'name': name,
      },
    );
  }
 
  // Get All Users
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await initDb();
 
    return await db.query(
      'users',
      orderBy: 'id DESC',
    );
  }
 
  // Update User
  static Future<int> updateUser(
    int id,
    String newName,
  ) async {
    final db = await initDb();
 
    return await db.update(
      'users',
      {
        'name': newName,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
 
  // Delete User
  static Future<int> deleteUser(int id) async {
    final db = await initDb();
 
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}