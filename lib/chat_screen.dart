import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../message_model.dart';
import '../storage_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  List<Message> messages = [];

  final List<String> languages = ['English', 'Hindi', 'Nepali', 'Sinhalese', 'Tamil', 'Bengali'];
  String sourceLang = 'English';
  String targetLang = 'Nepali';

  @override
  void initState() {
    super.initState();
    StorageService.load().then((loaded) => setState(() => messages = loaded));
  }

  void send(String text) async {
  final userMsg = Message(text, true);
  setState(() => messages.add(userMsg)); // Show original input

  final translated = await translateText(text, sourceLang, targetLang);
  final botMsg = Message(translated, false);
  setState(() => messages.add(botMsg)); // Show translated output

  StorageService.save(messages);
  controller.clear();
  scrollController.jumpTo(scrollController.position.maxScrollExtent + 80);
}

  Future<String> translateText(String text, String from, String to) async {
    try {
      final uri = Uri.parse('http://localhost:5000/translate'); // Use localhost for emulator
      final res = await http.post(uri, body: {
        'text': text,
        'source': from,
        'target': to,
      });
      if (res.statusCode == 200) {
        return res.body;
      } else {
        return 'Translation error: ${res.body}';
      }
    } catch (e) {
      print('Caught error: $e');
      return 'Error connecting to backend';
    }
  }

  Widget bubble(Message msg) => Align(
    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: msg.isUser ? Colors.teal[400] : Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(msg.text, style: const TextStyle(fontSize: 15)),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🧠 Multilingual Copilot')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<String>(
                value: sourceLang,
                items: languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                onChanged: (val) => setState(() => sourceLang = val!),
              ),
              const Icon(Icons.swap_horiz),
              DropdownButton<String>(
                value: targetLang,
                items: languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                onChanged: (val) => setState(() => targetLang = val!),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: messages.length,
            itemBuilder: (_, i) => bubble(messages[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.tealAccent),
                onPressed: () => send(controller.text),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}