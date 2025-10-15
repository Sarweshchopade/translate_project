import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../message_model.dart';

class StorageService {
  static Future<void> save(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => m.toJson()).toList();
    prefs.setString('chat_history', jsonEncode(jsonList));
  }

  static Future<List<Message>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('chat_history');
    if (json == null) return [];
    final decoded = jsonDecode(json) as List;
    return decoded.map((m) => Message.fromJson(m)).toList();
  }
}