class DebtNote {
  final int? id;
  final String debtorName;
  final String? description;
  final double amount;
  final double paid;
  final String createdAt;
  final String? dueDate;
  final bool isSettled;

  DebtNote({
    this.id,
    required this.debtorName,
    this.description,
    required this.amount,
    required this.paid,
    required this.createdAt,
    this.dueDate,
    required this.isSettled,
  });

  factory DebtNote.fromMap(Map<String, dynamic> map) {
    return DebtNote(
      id: map['id'] as int?,
      debtorName: map['debtor_name'] as String? ?? '',
      description: map['description'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paid: (map['paid'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] as String? ?? '',
      dueDate: map['due_date'] as String?,
      isSettled: (map['is_settled'] as num?)?.toInt() == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'debtor_name': debtorName,
      'description': description,
      'amount': amount,
      'paid': paid,
      'created_at': createdAt,
      'due_date': dueDate,
      'is_settled': isSettled ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  double get remainingAmount => amount - paid;

  DebtNote copyWith({
    int? id,
    String? debtorName,
    String? description,
    double? amount,
    double? paid,
    String? createdAt,
    String? dueDate,
    bool? isSettled,
  }) {
    return DebtNote(
      id: id ?? this.id,
      debtorName: debtorName ?? this.debtorName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paid: paid ?? this.paid,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}
