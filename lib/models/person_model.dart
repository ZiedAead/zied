class Person {
  final int? id;
  final String name;
  final String? phone;
  final String? notes;
  final DateTime createdAt;

  // الرصيد الصافي والإجماليات بالعملتين (محسوبة ديناميكياً من الحركات)
  final double netBalanceIqd;
  final double netBalanceUsd;
  final double totalForMeIqd;
  final double totalOnMeIqd;
  final double totalForMeUsd;
  final double totalOnMeUsd;
  final int transactionCount;

  const Person({
    this.id,
    required this.name,
    this.phone,
    this.notes,
    required this.createdAt,
    this.netBalanceIqd = 0.0,
    this.netBalanceUsd = 0.0,
    this.totalForMeIqd = 0.0,
    this.totalOnMeIqd = 0.0,
    this.totalForMeUsd = 0.0,
    this.totalOnMeUsd = 0.0,
    this.transactionCount = 0,
  });

  // حالة الرصيد بالدينار
  bool get hasIqdDebt => netBalanceIqd.abs() > 0.001;
  bool get isIqdForMe => netBalanceIqd > 0;
  bool get isIqdOnMe => netBalanceIqd < 0;

  // حالة الرصيد بالدولار
  bool get hasUsdDebt => netBalanceUsd.abs() > 0.001;
  bool get isUsdForMe => netBalanceUsd > 0;
  bool get isUsdOnMe => netBalanceUsd < 0;

  // هل الشخص خالص الذمة تماماً
  bool get isSettled => !hasIqdDebt && !hasUsdDebt;

  Person copyWith({
    int? id,
    String? name,
    String? phone,
    String? notes,
    DateTime? createdAt,
    double? netBalanceIqd,
    double? netBalanceUsd,
    double? totalForMeIqd,
    double? totalOnMeIqd,
    double? totalForMeUsd,
    double? totalOnMeUsd,
    int? transactionCount,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      netBalanceIqd: netBalanceIqd ?? this.netBalanceIqd,
      netBalanceUsd: netBalanceUsd ?? this.netBalanceUsd,
      totalForMeIqd: totalForMeIqd ?? this.totalForMeIqd,
      totalOnMeIqd: totalOnMeIqd ?? this.totalOnMeIqd,
      totalForMeUsd: totalForMeUsd ?? this.totalForMeUsd,
      totalOnMeUsd: totalOnMeUsd ?? this.totalOnMeUsd,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      netBalanceIqd: (map['net_balance_iqd'] as num?)?.toDouble() ?? 0.0,
      netBalanceUsd: (map['net_balance_usd'] as num?)?.toDouble() ?? 0.0,
      totalForMeIqd: (map['total_for_me_iqd'] as num?)?.toDouble() ?? 0.0,
      totalOnMeIqd: (map['total_on_me_iqd'] as num?)?.toDouble() ?? 0.0,
      totalForMeUsd: (map['total_for_me_usd'] as num?)?.toDouble() ?? 0.0,
      totalOnMeUsd: (map['total_on_me_usd'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transaction_count'] as num?)?.toInt() ?? 0,
    );
  }
}
