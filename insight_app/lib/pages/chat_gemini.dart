import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; //

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "CurrentUser");
  ChatUser chatGemini = ChatUser(id: "1", firstName: "GeminiChat");
  void _onSend(ChatMessage message) {
    setState(() {
      messages.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Gemini')),
      body: _buildChatUi(),
    );
  }

  Widget _buildChatUi() {
    return DashChat(currentUser: currentUser, onSend: _onSend, messages: []);
  }
}
