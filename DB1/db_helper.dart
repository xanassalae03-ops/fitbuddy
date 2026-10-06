import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;

  // เปิดใช้งานและสร้างตาราง login เพียงอย่างเดียว
  static Future<Database> initDb() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // สร้างเฉพาะตาราง login
        await db.execute('''
          CREATE TABLE login (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  // สมัครสมาชิก
  static Future<int> register(String username, String password) async {
    final db = await initDb();
    return await db.insert('login', {
      'username': username,
      'password': password,
    });
  }

  // ตรวจสอบว่ามี Username นี้อยู่แล้วหรือยัง
  static Future<bool> checkUserExists(String username) async {
    final db = await initDb();
    final result = await db.query(
      'login',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  // ตรวจสอบการเข้าสู่ระบบ (Username & Password)
  static Future<bool> login(String username, String password) async {
    final db = await initDb();
    final result = await db.query(
      'login',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty;
  }
}