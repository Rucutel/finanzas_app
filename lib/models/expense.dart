class Expense {
  String? id;
  final String category;
  final String subcategory;
  final double amount;
  final String status; // Falta pagar / Pagado
  final DateTime date;
  final String? note;

  Expense({
    this.id,
    required this.category,
    required this.subcategory,
    required this.amount,
    required this.status,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'subcategory': subcategory,
      'amount': amount,
      'status': status,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'],
      subcategory: map['subcategory'],
      amount: (map['amount'] as num).toDouble(),
      status: map['status'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
