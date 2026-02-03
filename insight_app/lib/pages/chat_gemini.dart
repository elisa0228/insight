import 'dart:io'; //core dart libraries used to handle file system access and binary image data
import 'dart:typed_data'; //required to convert locally stored images into byte arrays for LLM upload

import 'package:dash_chat_2/dash_chat_2.dart'; //provides a full-features chat UI framework including message bubbles, input fields and message streaming visual updates
import 'package:flutter/material.dart'; //core flutter UI framework for building cross-platform widgets
import 'package:flutter_gemini/flutter_gemini.dart'; //gemini SDK used to interact with google's multimodal LLM (enbales both text only and image+text requests)
import 'package:image_picker/image_picker.dart'; //enables secure access to the device photo gallery for selecting stored images

//ChatGeminiPage represents the primary conversational AI interface
//it supports multimodal interaction by allowing users to submit both text and images
//the optional initialImagePath enables automated AI requests triggered on screen load
class ChatGeminiPage extends StatefulWidget {
  //optional image path passed via Navigator from the camera workflow
  //this enables automated processing of newly captured images
  final String? initialImagePath;

  const ChatGeminiPage({super.key, this.initialImagePath});

  @override
  State<ChatGeminiPage> createState() => _ChatGeminiPageState();
}

class _ChatGeminiPageState extends State<ChatGeminiPage> {
  final Gemini gemini = Gemini
      .instance; //gemini client instance used to manage API requests and streaming responses
  List<ChatMessage> messages =
      []; //local in memory chat history used to render messages in DashChat UI
  ChatUser currentUser = ChatUser(
    id: "0",
    firstName: "CurrentUser",
  ); //represents the human user in the chat UI
  ChatUser chatGemini = ChatUser(
    id: "1",
    firstName: "GeminiChat",
  ); //represents the gemini AI agent in the chat UI

  @override
  void initState() {
    super.initState();
    //if an image was passed from the camera page, automatically send it to gemini with a default prompt without requiring manual user input
    if (widget.initialImagePath != null) {
      //constructs a ChatMessage containing both a default prompt and the captured image as multimodal input for gemini
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
      _onSend(
        chatMessage,
      ); //automatically sends the constructed message to gemini on screen load
    }
  }

  //central message handling function
  //responsible for:
  // - updating UI state
  // - extracting text and image data
  // - sending multimodal requests to gemini
  // - handling streamed partial responses
  void _onSend(ChatMessage chatMessage) {
    setState(() {
      //immediately update UI with the users outgoing message
      messages = [chatMessage, ...messages];
    });
    try {
      final question = chatMessage.text;
      List<Uint8List>?
      images; //optional list of image byte arrays for multimodal gemini input
      //if the message includes an image, load and convert it to bytes
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }

      //initiates a streaming gemini request
      //this allows partial responses to be displayed in real-time, improving receieved responsiveness and user experience
      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        String response = "";
        //iterates over streamed content parts returned by gemini
        //each part may contain partial text tokens
        if (event.content?.parts != null) {
          for (final part in event.content!.parts!) {
            //ensures only text parts are processed
            if (part is TextPart) {
              final text = part.text;
              //accumulates streamed tokens into a continuous response string
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
        //prevents UI updates for empty or whitespace-only chunks
        if (response.trim().isEmpty) {
          return;
        }
        //if the last message is already a gemini message, append streamed tokens to the existing bubble
        if (lastMessage != null && lastMessage.user.id == chatGemini.id) {
          lastMessage = messages.removeAt(0);
          //ensures clean spacing when appending streamed text
          if (!lastMessage.text.endsWith(' ') && !response.startsWith(' ')) {
            lastMessage.text += ' ';
          }
          lastMessage.text += response;

          //updates UI with appended streamed content
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          //creates a new gemini message bubble for the first streamed chunk
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
      //robust error logging for debugging gemini API or file IO issues
      print("Gemini error: $e");
      print(stack);
    }
  }

  //allows users to manually select an image from the device gallery
  //this uspports secondary multimodal workflows in addition to live camera capture
  void _sendImageMessage() {
    ImagePicker().pickImage(source: ImageSource.gallery).then((image) {
      if (image != null) {
        //constructs a multimodal chat message using the selected image
        ChatMessage chatMessage = ChatMessage(
          text: "Describe this image please in detail",
          user: currentUser,
          createdAt: DateTime.now(),
          medias: [
            ChatMedia(url: image.path, fileName: "", type: MediaType.image),
          ],
        );
        //sends the image message through the same unified pipeline
        _onSend(chatMessage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar provides consistent navigation context for the chat screen
      appBar: AppBar(title: Text('Chat Gemini'), centerTitle: true),
      //main chat UI rendered via DashChat widget
      body: _buildChatUi(),
    );
  }

  //encapsulates DashChat configuration
  //separating this into a method improves readability and maintainability
  Widget _buildChatUi() {
    return DashChat(
      //adds an image picker button to the chat input field
      inputOptions: InputOptions(
        trailing: [
          IconButton(onPressed: _sendImageMessage, icon: Icon(Icons.image)),
        ],
      ),
      currentUser:
          currentUser, //idenitfies which messages belong to the current user
      onSend: _onSend, //binds send action to unified message handling logic
      messages:
          messages, //supplies current in-memory message list to the chat UI
    );
  }
}
