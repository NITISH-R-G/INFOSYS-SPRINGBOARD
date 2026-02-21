import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'car_contract_app.db');
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE contracts ADD COLUMN file_path TEXT');
      } catch (e) {
        // Ignore if column already exists during unstable development testing
        print('Error upgrading db: $e');
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        name TEXT,
        role TEXT, -- 'client' or 'dealer'
        created_at TEXT
      )
    ''');

    // Dealers Table (Extra profile info)
    await db.execute('''
      CREATE TABLE dealers(
        id TEXT PRIMARY KEY,
        user_id TEXT,
        dealership_name TEXT,
        location TEXT,
        license_number TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    // Contracts Table
    await db.execute('''
      CREATE TABLE contracts(
        id TEXT PRIMARY KEY,
        user_id TEXT, -- Client who owns this contract
        dealer_id TEXT, -- Dealer who created/is negotiating this (optional initially)
        title TEXT,
        file_path TEXT,
        status TEXT, -- 'draft', 'review', 'negotiation', 'signed'
        raw_text TEXT,
        structured_json TEXT, -- JSON blob of extracted fields
        fairness_score INTEGER,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    // Contract Versions/History
    await db.execute('''
      CREATE TABLE contract_versions(
        id TEXT PRIMARY KEY,
        contract_id TEXT,
        version_number INTEGER,
        changes_json TEXT, -- Diff or full snapshot
        created_at TEXT,
        created_by TEXT, -- user_id of who made the change
        FOREIGN KEY(contract_id) REFERENCES contracts(id)
      )
    ''');

    // Negotiation Messages
    await db.execute('''
      CREATE TABLE negotiation_messages(
        id TEXT PRIMARY KEY,
        contract_id TEXT,
        sender_id TEXT,
        content TEXT,
        is_ai_generated INTEGER, -- 1 for AI suggestions, 0 for user messages
        timestamp TEXT,
        FOREIGN KEY(contract_id) REFERENCES contracts(id)
      )
    ''');

    // Vehicles (For VIN lookups)
    await db.execute('''
      CREATE TABLE vehicles(
        vin TEXT PRIMARY KEY,
        make TEXT,
        model TEXT,
        year INTEGER,
        details_json TEXT
      )
    ''');
  }

  // Debug helper to clear DB
  Future<void> clearDatabase() async {
    String path = join(await getDatabasesPath(), 'car_contract_app.db');
    await deleteDatabase(path);
    _database = null;
  }
}
