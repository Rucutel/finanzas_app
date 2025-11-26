class Income {
  String? id;
  final double amount;
  final String description;
  final DateTime date;

  Income({
    this.id,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'],
      date: DateTime.parse(map['date']),
    );
  }
}
