import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart'; //

class ChatGeminiPage extends StatefulWidget {
  final String? initialImagePath;

  const ChatGeminiPage({super.key, this.initialImagePath});

  @override
  State<ChatGeminiPage> createState() => _ChatGeminiPageState();
}

class _ChatGeminiPageState extends State<ChatGeminiPage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "CurrentUser");
  ChatUser chatGemini = ChatUser(id: "1", firstName: "GeminiChat");

  @override
  void initState() {
    super.initState();
    //if an image was passed from the camera page, automatically send it to gemini with a default prompt
    if (widget.initialImagePath != null) {
      final chatMessage = ChatMessage(
        text: "Describe this image please in detail",
        user: currentUser,
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            url: widget.initialImagePath!,
            fileName: "",
            type: MediaType.image,
          ),
        ],
      );
      _onSend(chatMessage);
    }
  }

  void _onSend(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      final question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }
      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        String response = "";
        if (event.content?.parts != null) {
          for (final part in event.content!.parts!) {
            if (part is TextPart) {
              final text = part.text;
              if (text.isNotEmpty) {
                if (response.isNotEmpty &&
                    !response.endsWith(' ') &&
                    !text.startsWith(' ')) {
                  response += ' ';
                }
                response += text;
              }
            }
          }
        }
        if (response.trim().isEmpty) {
          return;
        }
        if (lastMessage != null && lastMessage.user.id == chatGemini.id) {
          lastMessage = messages.removeAt(0);
          if (!lastMessage.text.endsWith(' ') && !response.startsWith(' ')) {
            lastMessage.text += ' ';
          }
          lastMessage.text += response;

          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          final responseMessage = ChatMessage(
            text: response,
            user: chatGemini,
            createdAt: DateTime.now(),
          );
          setState(() {
            messages = [responseMessage, ...messages];
          });
        }
      });
    } catch (e, stack) {
      print("Gemini error: $e");
      print(stack);
    }
  }

  void _sendImageMessage() {
    ImagePicker().pickImage(source: ImageSource.gallery).then((image) {
      if (image != null) {
        ChatMessage chatMessage = ChatMessage(
          text: "Describe this image please in detail",
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
