import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyExchangeRate = 'exchange_rate';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keySelectedCurrency = 'selected_currency';

  double _exchangeRate = 1530.0; // 1 USD = 1530 IQD افتراضياً
  ThemeMode _themeMode = ThemeMode.light;
  String _selectedCurrencyFilter = 'ALL'; // 'ALL', 'IQD', 'USD'

  double get exchangeRate => _exchangeRate;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get selectedCurrencyFilter => _selectedCurrencyFilter;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _exchangeRate = prefs.getDouble(_keyExchangeRate) ?? 1530.0;

    final themeStr = prefs.getString(_keyThemeMode);
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    _selectedCurrencyFilter = prefs.getString(_keySelectedCurrency) ?? 'ALL';
    notifyListeners();
  }

  Future<void> setExchangeRate(double rate) async {
    if (rate <= 0) return;
    _exchangeRate = rate;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyExchangeRate, rate);
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setCurrencyFilter(String filter) async {
    _selectedCurrencyFilter = filter;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedCurrency, filter);
  }
}
