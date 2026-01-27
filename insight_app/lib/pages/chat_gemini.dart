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
  void _onSend(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      gemini.streamGenerateContent(question).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user.id == chatGemini.id) {
          lastMessage == messages.removeAt(0);
          String response =
              event.content?.parts?.fold(
                "",
                (previousValue, current) => "$previousValue${current.text}",
              ) ??
              "";
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage, ...messages];
          });
        }
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Gemini'), centerTitle: true),
      body: _buildChatUi(),
    );
  }

  Widget _buildChatUi() {
    return DashChat(
      currentUser: currentUser,
      onSend: _onSend,
      messages: messages,
    );
  }
}
