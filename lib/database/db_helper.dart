import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/income.dart';
import '../models/expense.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'finanzas.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE incomes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            date TEXT NOT NULL
          )
        """);

        await db.execute("""
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            subcategory TEXT NOT NULL,
            amount REAL NOT NULL,
            status TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT
          )
        """);
      },
    );
  }

  // --- INGRESOS ---
  Future<int> insertIncome(Income income) async {
    final db = await database;
    return db.insert('incomes', income.toMap());
  }

  Future<List<Income>> getAllIncomes() async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query('incomes');
    return res.map<Income>((e) => Income.fromMap(e)).toList();
  }

  Future<List<Income>> getIncomesByMonthYear(int month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'incomes',
      where: "strftime('%m', date) = ? AND strftime('%Y', date) = ?",
      whereArgs: [month.toString().padLeft(2, '0'), year.toString()],
    );
    return res.map<Income>((e) => Income.fromMap(e)).toList();
  }

  // --- GASTOS ---
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final newExpense = expense.toMap();
    newExpense['status'] = 'Falta pagar'; // asegurar status inicial
    return db.insert('expenses', newExpense);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query('expenses');
    return res.map<Expense>((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getExpensesByMonthYear(int month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'expenses',
      where: "strftime('%m', date) = ? AND strftime('%Y', date) = ?",
      whereArgs: [month.toString().padLeft(2, '0'), year.toString()],
    );
    return res.map<Expense>((e) => Expense.fromMap(e)).toList();
  }

  Future<int> updateExpenseStatus(int id, String newStatus) async {
    final db = await database;
    return db.update(
      'expenses',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
