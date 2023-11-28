import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<types.Message> _messages = [];
  late types.User ai;
  late types.User user;

  bool isAiTyping = false;

  @override
  void initState() {
    super.initState();
    ai = const types.User(id: 'ai', firstName: 'AI');
    user = const types.User(id: 'user', firstName: 'You');
  }

  Future<String> _completeChat(String prompt) async {
    // Replace 'your_flask_api_endpoint' with the actual endpoint of your Flask API
    final apiUrl = Uri.parse('http://127.0.0.1:5000/chat');

    final headers = {'Content-Type': 'application/json'};

    final data = {'question': prompt};

    try {
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['response'];
      } else {
        print('API request failed: ${response.statusCode}');
        return 'Oops, something went wrong';
      }
    } catch (e) {
      print('Error during API request: $e');
      return 'Oops, something went wrong';
    }
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final userMessage = types.TextMessage(
      author: user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message.text,
    );

    _addMessage(userMessage);

    setState(() {
      isAiTyping = true;
    });

    try {
      final aiResponse = await _completeChat(message.text);

      setState(() {
        isAiTyping = false;
      });

      final aiMessage = types.TextMessage(
        author: ai,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: aiResponse,
      );

      _addMessage(aiMessage);
    } catch (e) {
      setState(() {
        isAiTyping = false;
      });

      print('Error during AI response: $e');
      // Handle error, e.g., show a user-friendly message in the chat
    }
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nischal - Your personal AI chatbot'),
      ),
      body: Chat(
        typingIndicatorOptions: TypingIndicatorOptions(
          typingUsers: [if (isAiTyping) ai],
        ),
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: user,
        theme: const DefaultChatTheme(),
      ),
    );
  }
}
