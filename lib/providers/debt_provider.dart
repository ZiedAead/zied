import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/backup_data_model.dart';
import '../models/person_model.dart';
import '../models/transaction_model.dart';

class DebtProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Person> _persons = [];
  List<DebtTransaction> _currentPersonTransactions = [];
  Map<String, double> _globalTotals = {
    'total_for_me_iqd': 0.0,
    'total_on_me_iqd': 0.0,
    'total_for_me_usd': 0.0,
    'total_on_me_usd': 0.0,
  };

  bool _isLoading = false;
  String _searchQuery = '';

  List<Person> get persons => _persons;
  List<DebtTransaction> get currentPersonTransactions => _currentPersonTransactions;
  Map<String, double> get globalTotals => _globalTotals;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // إجماليات عامة
  double get totalForMeIqd => _globalTotals['total_for_me_iqd'] ?? 0.0;
  double get totalOnMeIqd => _globalTotals['total_on_me_iqd'] ?? 0.0;
  double get totalForMeUsd => _globalTotals['total_for_me_usd'] ?? 0.0;
  double get totalOnMeUsd => _globalTotals['total_on_me_usd'] ?? 0.0;

  double get netIqd => totalForMeIqd - totalOnMeIqd;
  double get netUsd => totalForMeUsd - totalOnMeUsd;

  DebtProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // زرع البيانات التجريبية تلقائياً في أول تشغيل للتطبيق لتسهيل التجربة
    await _dbHelper.seedInitialData();
    await refreshAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadPersons(),
      loadGlobalTotals(),
    ]);
  }

  Future<void> loadPersons() async {
    _persons = await _dbHelper.getAllPersonsWithBalances(searchQuery: _searchQuery);
    notifyListeners();
  }

  Future<void> loadGlobalTotals() async {
    _globalTotals = await _dbHelper.getGlobalTotals();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadPersons();
  }

  // =========================================================================
  // عمليات الأشخاص (Persons)
  // =========================================================================

  Future<int> addPerson(String name, {String? phone, String? notes}) async {
    final person = Person(
      name: name.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: DateTime.now(),
    );
    final id = await _dbHelper.insertPerson(person);
    await refreshAll();
    return id;
  }

  Future<void> updatePerson(Person person) async {
    await _dbHelper.updatePerson(person);
    await refreshAll();
  }

  Future<void> deletePerson(int id) async {
    await _dbHelper.deletePerson(id);
    await refreshAll();
  }

  Future<Person?> getPerson(int id) async {
    return await _dbHelper.getPersonById(id);
  }

  // =========================================================================
  // عمليات الحركات المالية (Transactions)
  // =========================================================================

  Future<void> loadTransactionsForPerson(int personId) async {
    _currentPersonTransactions = await _dbHelper.getTransactionsForPerson(personId);
    notifyListeners();
  }

  Future<void> addTransaction({
    required int personId,
    required String type,
    required double amount,
    required String currency,
    required DateTime date,
    String? notes,
  }) async {
    final transaction = DebtTransaction(
      personId: personId,
      type: type,
      amount: amount,
      currency: currency,
      date: date,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );

    await _dbHelper.insertTransaction(transaction);
    await loadTransactionsForPerson(personId);
    await refreshAll();
  }

  Future<void> updateTransaction(DebtTransaction transaction) async {
    await _dbHelper.updateTransaction(transaction);
    await loadTransactionsForPerson(transaction.personId);
    await refreshAll();
  }

  Future<void> deleteTransaction(int transactionId, int personId) async {
    await _dbHelper.deleteTransaction(transactionId);
    await loadTransactionsForPerson(personId);
    await refreshAll();
  }

  // =========================================================================
  // النسخ الاحتياطي ومسح البيانات
  // =========================================================================

  Future<void> restoreFromBackup(BackupData backupData) async {
    _isLoading = true;
    notifyListeners();

    await _dbHelper.restoreBackupData(backupData);
    await refreshAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearAll() async {
    _isLoading = true;
    notifyListeners();

    await _dbHelper.clearAllData();
    _persons = [];
    _currentPersonTransactions = [];
    _globalTotals = {
      'total_for_me_iqd': 0.0,
      'total_on_me_iqd': 0.0,
      'total_for_me_usd': 0.0,
      'total_on_me_usd': 0.0,
    };

    _isLoading = false;
    notifyListeners();
  }
}
