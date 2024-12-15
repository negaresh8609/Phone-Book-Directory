import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'contacts.db');
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        last_name TEXT,
        school TEXT,
        phone_number TEXT
      )
    ''');
  }

  Future<void> insertContact(Map<String, dynamic> contact) async {
    final db = await database;
    await db.insert('contacts', contact);
  }

  Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    final db = await database;
    return await db.query('contacts',
        where: 'name LIKE ? OR last_name LIKE ? OR school LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%']);
  }
}
