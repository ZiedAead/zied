class DebtTransaction {
  final int? id;
  final int personId;
  final String type; // 'for_me' (دين لي / مستحق) or 'on_me' (دين علي / مطلوب)
  final double amount;
  final String currency; // 'IQD' or 'USD'
  final DateTime date;
  final String? notes;

  const DebtTransaction({
    this.id,
    required this.personId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    this.notes,
  });

  bool get isForMe => type == 'for_me';
  bool get isOnMe => type == 'on_me';
  bool get isIqd => currency.toUpperCase() == 'IQD';
  bool get isUsd => currency.toUpperCase() == 'USD';

  DebtTransaction copyWith({
    int? id,
    int? personId,
    String? type,
    double? amount,
    String? currency,
    DateTime? date,
    String? notes,
  }) {
    return DebtTransaction(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'person_id': personId,
      'type': type,
      'amount': amount,
      'currency': currency.toUpperCase(),
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory DebtTransaction.fromMap(Map<String, dynamic> map) {
    return DebtTransaction(
      id: map['id'] as int?,
      personId: map['person_id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: (map['currency'] as String?)?.toUpperCase() ?? 'IQD',
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
