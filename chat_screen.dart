// lib/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late DialogFlowtter dialogFlowtter;
  final _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    // Load your Dialogflow service account JSON
    DialogFlowtter.fromFile(path: 'assets/dialogflow-key.json').then((df) {
      dialogFlowtter = df;

      // Add welcome message after DialogFlowtter is ready
      setState(() {
        messages.add({
          'msg': '''Hello 👋! I'm the "Wejhah" assistant, here to help you inside the stadium. You can ask me about:
📍 Navigation 
⚽ Match Information 
🎟 Ticket Support 
🍔 Recommendations 

How can I assist you today? 😊''',
          'isUser': false
        });
      });
    });
  }

  void sendMessage(String text) async {
    if (text.isEmpty) return;
    setState(() => messages.add({'msg': text, 'isUser': true}));
    _controller.clear();

    final response = await dialogFlowtter.detectIntent(
      queryInput: QueryInput(text: TextInput(text: text)),
    );

    final botMsg = response.text ?? '…';
    setState(() => messages.add({'msg': botMsg, 'isUser': false}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatbot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                return Align(
                  alignment: m['isUser']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m['isUser'] ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      m['msg'],
                      style: TextStyle(
                        color: m['isUser'] ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      controller: _controller,
                      decoration:
                      const InputDecoration(hintText: 'Type a message…'),
                      onSubmitted: sendMessage,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(_controller.text.trim()),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
