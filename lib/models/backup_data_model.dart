import 'dart:convert';
import 'person_model.dart';
import 'transaction_model.dart';

class BackupData {
  final String app;
  final String version;
  final DateTime exportedAt;
  final double exchangeRate;
  final List<Person> persons;
  final List<DebtTransaction> transactions;

  const BackupData({
    required this.app,
    required this.version,
    required this.exportedAt,
    required this.exchangeRate,
    required this.persons,
    required this.transactions,
  });

  Map<String, dynamic> toMap() {
    return {
      'app': app,
      'version': version,
      'exported_at': exportedAt.toIso8601String(),
      'exchange_rate': exchangeRate,
      'persons': persons.map((p) => p.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }

  String toJson() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }

  factory BackupData.fromMap(Map<String, dynamic> map) {
    final rawPersons = (map['persons'] as List<dynamic>?) ?? [];
    final rawTransactions = (map['transactions'] as List<dynamic>?) ?? [];

    return BackupData(
      app: map['app'] as String? ?? 'ZiedAeadDebts',
      version: map['version'] as String? ?? '1.0.0',
      exportedAt: DateTime.tryParse(map['exported_at'] as String? ?? '') ?? DateTime.now(),
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble() ?? 1530.0,
      persons: rawPersons
          .map((item) => Person.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      transactions: rawTransactions
          .map((item) => DebtTransaction.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  factory BackupData.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return BackupData.fromMap(map);
  }
}
