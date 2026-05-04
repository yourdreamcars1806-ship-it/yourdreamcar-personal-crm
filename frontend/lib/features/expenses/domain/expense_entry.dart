class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.createdAt,
    this.carId,
    this.carLabel,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime createdAt;
  final String? carId;
  final String? carLabel;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'carId': carId,
      'carLabel': carLabel,
    };
  }

  static ExpenseEntry fromMap(Map<String, dynamic> map) {
    return ExpenseEntry(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      carId: map['carId'] as String?,
      carLabel: map['carLabel'] as String?,
    );
  }

  /// From GET/POST `/api/expenses` JSON (`id` + ISO `createdAt`).
  factory ExpenseEntry.fromApiJson(Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    DateTime created;
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }
    return ExpenseEntry(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      createdAt: created,
      carId: map['carId']?.toString(),
      carLabel: map['carLabel']?.toString(),
    );
  }
}
