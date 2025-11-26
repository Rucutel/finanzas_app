import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income.dart';
import '../models/expense.dart';

class FirestoreHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- INGRESOS ---
  static Future<void> addIncome(Income income) async {
    await _db.collection('incomes').add(income.toMap());
  }

  static Stream<List<Income>> streamIncomes() {
    return _db
        .collection('incomes')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              return Income.fromMap(data);
            }).toList());
  }

  static Future<void> deleteIncome(String id) async {
    await _db.collection('incomes').doc(id).delete();
  }

  static Future<List<Income>> getIncomesByMonthYear(int month, int year) async {
    final snapshot = await _db.collection('incomes').get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return Income.fromMap(data);
    }).where((i) => i.date.month == month && i.date.year == year).toList();
  }

  // --- GASTOS ---
  static Future<void> addExpense(Expense expense) async {
    await _db.collection('expenses').add(expense.toMap());
  }

  static Stream<List<Expense>> streamExpenses() {
    return _db
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              return Expense.fromMap(data);
            }).toList());
  }

  static Future<void> updateExpenseStatus(String id, String newStatus) async {
    await _db.collection('expenses').doc(id).update({'status': newStatus});
  }

  static Future<void> deleteExpense(String id) async {
    await _db.collection('expenses').doc(id).delete();
  }

  static Future<List<Expense>> getExpensesByMonthYear(int month, int year) async {
    final snapshot = await _db.collection('expenses').get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return Expense.fromMap(data);
    }).where((e) => e.date.month == month && e.date.year == year).toList();
  }
}
