import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const _key = 'viewed_services';
  static const _max = 10;

  Future<void> addToHistory(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(serviceId);
    list.insert(0, serviceId);
    await prefs.setStringList(_key, list.take(_max).toList());
  }

  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}