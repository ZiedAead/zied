import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/person_model.dart';
import '../../models/transaction_model.dart';
import '../../models/backup_data_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zied_debts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // تفعيل المفاتيح الأجنبية لحذف الحركات تلقائياً عند حذف الشخص
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول الأشخاص
    await db.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // جدول الحركات المالية
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');
  }

  // =========================================================================
  // عمليات الأشخاص (Persons CRUD & Balances)
  // =========================================================================

  Future<int> insertPerson(Person person) async {
    final db = await database;
    return await db.insert('persons', person.toMap());
  }

  Future<int> updatePerson(Person person) async {
    final db = await database;
    return await db.update(
      'persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> deletePerson(int id) async {
    final db = await database;
    return await db.delete(
      'persons',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// جلب جميع الأشخاص مع حساب الأرصدة التجميعية تلقائياً بالدينار والدولار
  Future<List<Person>> getAllPersonsWithBalances({String? searchQuery}) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause = 'WHERE p.name LIKE ? OR p.phone LIKE ?';
      whereArgs = ['%${searchQuery.trim()}%', '%${searchQuery.trim()}%'];
    }

    final query = '''
      SELECT 
        p.id,
        p.name,
        p.phone,
        p.notes,
        p.created_at,
        COUNT(t.id) AS transaction_count,
        COALESCE(SUM(CASE WHEN t.currency = 'IQD' THEN (CASE WHEN t.type = 'for_me' THEN t.amount ELSE -t.amount END) ELSE 0 END), 0) AS net_balance_iqd,
        COALESCE(SUM(CASE WHEN t.currency = 'USD' THEN (CASE WHEN t.type = 'for_me' THEN t.amount ELSE -t.amount END) ELSE 0 END), 0) AS net_balance_usd,
        COALESCE(SUM(CASE WHEN t.currency = 'IQD' AND t.type = 'for_me' THEN t.amount ELSE 0 END), 0) AS total_for_me_iqd,
        COALESCE(SUM(CASE WHEN t.currency = 'IQD' AND t.type = 'on_me' THEN t.amount ELSE 0 END), 0) AS total_on_me_iqd,
        COALESCE(SUM(CASE WHEN t.currency = 'USD' AND t.type = 'for_me' THEN t.amount ELSE 0 END), 0) AS total_for_me_usd,
        COALESCE(SUM(CASE WHEN t.currency = 'USD' AND t.type = 'on_me' THEN t.amount ELSE 0 END), 0) AS total_on_me_usd
      FROM persons p
      LEFT JOIN transactions t ON p.id = t.person_id
      $whereClause
      GROUP BY p.id
      ORDER BY p.id DESC
    ''';

    final result = await db.rawQuery(query, whereArgs);
    return result.map((row) => Person.fromMap(row)).toList();
  }

  Future<Person?> getPersonById(int id) async {
    final db = await database;
    final query = '''
      SELECT 
        p.id,
        p.name,
        p.phone,
        p.notes,
        p.created_at,
        COUNT(t.id) AS transaction_count,
        COALESCE(SUM(CASE WHEN t.currency = 'IQD' THEN (CASE WHEN t.type = 'for_me' THEN t.amount ELSE -t.amount END) ELSE 0 END), 0) AS net_balance_iqd,
        COALESCE(SUM(CASE WHEN t.currency = 'USD' THEN (CASE WHEN t.type = 'for_me' THEN t.amount ELSE -t.amount END) ELSE 0 END), 0) AS net_balance_usd,
        COALESCE(SUM(CASE WHEN t.currency = 'IQD' AND t.type = 'for_me' THEN t.amount ELSE 0 END), 0) AS total_for_me_iqd,
        COALESCE(SUM(CASE WHEN t.currency = 'IQD' AND t.type = 'on_me' THEN t.amount ELSE 0 END), 0) AS total_on_me_iqd,
        COALESCE(SUM(CASE WHEN t.currency = 'USD' AND t.type = 'for_me' THEN t.amount ELSE 0 END), 0) AS total_for_me_usd,
        COALESCE(SUM(CASE WHEN t.currency = 'USD' AND t.type = 'on_me' THEN t.amount ELSE 0 END), 0) AS total_on_me_usd
      FROM persons p
      LEFT JOIN transactions t ON p.id = t.person_id
      WHERE p.id = ?
      GROUP BY p.id
    ''';

    final result = await db.rawQuery(query, [id]);
    if (result.isNotEmpty) {
      return Person.fromMap(result.first);
    }
    return null;
  }

  // =========================================================================
  // عمليات الحركات المالية (Transactions CRUD)
  // =========================================================================

  Future<int> insertTransaction(DebtTransaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(DebtTransaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DebtTransaction>> getTransactionsForPerson(int personId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'date DESC, id DESC',
    );
    return result.map((row) => DebtTransaction.fromMap(row)).toList();
  }

  Future<List<DebtTransaction>> getAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return result.map((row) => DebtTransaction.fromMap(row)).toList();
  }

  // =========================================================================
  // الإجماليات الكلية للتطبيق (Global Dashboard Totals)
  // =========================================================================

  Future<Map<String, double>> getGlobalTotals() async {
    final db = await database;
    final query = '''
      SELECT 
        COALESCE(SUM(CASE WHEN currency = 'IQD' AND type = 'for_me' THEN amount ELSE 0 END), 0) AS total_for_me_iqd,
        COALESCE(SUM(CASE WHEN currency = 'IQD' AND type = 'on_me' THEN amount ELSE 0 END), 0) AS total_on_me_iqd,
        COALESCE(SUM(CASE WHEN currency = 'USD' AND type = 'for_me' THEN amount ELSE 0 END), 0) AS total_for_me_usd,
        COALESCE(SUM(CASE WHEN currency = 'USD' AND type = 'on_me' THEN amount ELSE 0 END), 0) AS total_on_me_usd
      FROM transactions
    ''';

    final result = await db.rawQuery(query);
    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'total_for_me_iqd': (row['total_for_me_iqd'] as num).toDouble(),
        'total_on_me_iqd': (row['total_on_me_iqd'] as num).toDouble(),
        'total_for_me_usd': (row['total_for_me_usd'] as num).toDouble(),
        'total_on_me_usd': (row['total_on_me_usd'] as num).toDouble(),
      };
    }

    return {
      'total_for_me_iqd': 0.0,
      'total_on_me_iqd': 0.0,
      'total_for_me_usd': 0.0,
      'total_on_me_usd': 0.0,
    };
  }

  // =========================================================================
  // النسخ الاحتياطي والاسترجاع (Backup & Restore Operations)
  // =========================================================================

  Future<BackupData> exportBackupData(double exchangeRate) async {
    final db = await database;
    final personsData = await db.query('persons');
    final transactionsData = await db.query('transactions');

    final persons = personsData.map((row) => Person.fromMap(row)).toList();
    final transactions = transactionsData.map((row) => DebtTransaction.fromMap(row)).toList();

    return BackupData(
      app: 'ZiedAeadDebts',
      version: '1.0.0',
      exportedAt: DateTime.now(),
      exchangeRate: exchangeRate,
      persons: persons,
      transactions: transactions,
    );
  }

  Future<void> restoreBackupData(BackupData backupData) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. مسح البيانات القديمة
      await txn.delete('transactions');
      await txn.delete('persons');

      // 2. خريطة مطابقة المعرفات في حال التغيير
      final Map<int, int> personIdMap = {};

      for (final person in backupData.persons) {
        final originalId = person.id;
        final newId = await txn.insert('persons', {
          'name': person.name,
          'phone': person.phone,
          'notes': person.notes,
          'created_at': person.createdAt.toIso8601String(),
        });
        if (originalId != null) {
          personIdMap[originalId] = newId;
        }
      }

      // 3. إعادة إدراج الحركات بالمعرفات الجديدة
      for (final tr in backupData.transactions) {
        final mappedPersonId = personIdMap[tr.personId] ?? tr.personId;
        await txn.insert('transactions', {
          'person_id': mappedPersonId,
          'type': tr.type,
          'amount': tr.amount,
          'currency': tr.currency,
          'date': tr.date.toIso8601String(),
          'notes': tr.notes,
        });
      }
    });
  }

  /// مسح كل البيانات وتصفير قاعدة البيانات
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('persons');
    });
  }

  /// زرع بيانات أولية تجريبية لمساعدة المستخدم على تجربة التطبيق فوراً
  Future<void> seedInitialData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM persons')) ?? 0;
    if (count > 0) return; // البيانات موجودة مسبقاً

    await db.transaction((txn) async {
      // شخص 1
      final p1 = await txn.insert('persons', {
        'name': 'أحمد علي حسن',
        'phone': '07701234567',
        'notes': 'صديق العمل - مكتب المنصور',
        'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      });
      await txn.insert('transactions', {
        'person_id': p1,
        'type': 'for_me',
        'amount': 250000.0,
        'currency': 'IQD',
        'date': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
        'notes': 'سلفة شراء حاسوب',
      });
      await txn.insert('transactions', {
        'person_id': p1,
        'type': 'for_me',
        'amount': 150.0,
        'currency': 'USD',
        'date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'notes': 'دفع اشتراك سيرفر',
      });

      // شخص 2
      final p2 = await txn.insert('persons', {
        'name': 'محمود الكرخي',
        'phone': '07809876543',
        'notes': 'مورد أجهزة كهربائية',
        'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      });
      await txn.insert('transactions', {
        'person_id': p2,
        'type': 'on_me',
        'amount': 500000.0,
        'currency': 'IQD',
        'date': DateTime.now().subtract(const Duration(days: 18)).toIso8601String(),
        'notes': 'متبقي فاتورة تجهيز شاشات',
      });
      await txn.insert('transactions', {
        'person_id': p2,
        'type': 'on_me',
        'amount': 200.0,
        'currency': 'USD',
        'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'notes': 'طلب بضاعة من دبي',
      });

      // شخص 3
      final p3 = await txn.insert('persons', {
        'name': 'عمر البغدادي',
        'phone': '07505554433',
        'notes': 'حساب متوازن',
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      });
      await txn.insert('transactions', {
        'person_id': p3,
        'type': 'for_me',
        'amount': 100000.0,
        'currency': 'IQD',
        'date': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
        'notes': 'دين سابق',
      });
      await txn.insert('transactions', {
        'person_id': p3,
        'type': 'on_me',
        'amount': 100000.0,
        'currency': 'IQD',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'notes': 'تسديد كامل المبلغ نقداً',
      });
    });
  }
}
