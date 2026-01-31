import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart'; //

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
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }
      gemini.streamGenerateContent(question, images: images).listen((event) {
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
        } else {
          String response =
              event.content?.parts?.fold(
                "",
                (previousValue, current) => "$previousValue${current.text}",
              ) ??
              "";
          ChatMessage responseMessage = ChatMessage(
            text: response,
            user: chatMessage,
            createdAt: DateTime.now(),
          );
          setState(() {
            messages = [responseMessage, ...messages];
          });
        }
      });
    } catch (e) {}
  }

  void _sendImageMessage() {
    ImagePicker().pickImage(source: ImageSource.gallery).then((image) {
      if (image != null) {
        ChatMessage chatMessage = ChatMessage(
          text: "Tell me about this image",
          user: currentUser,
          createdAt: DateTime.now(),
          medias: [
            ChatMedia(url: image.path, fileName: "", type: MediaType.image),
          ],
        );
        _onSend(chatMessage);
      }
    });
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
      inputOptions: InputOptions(
        trailing: [
          IconButton(onPressed: _sendImageMessage, icon: Icon(Icons.image)),
        ],
      ),
      currentUser: currentUser,
      onSend: _onSend,
      messages: messages,
    );
  }
}
