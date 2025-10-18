import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:login/Model/User.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isBroadcasting = false;
  final List<User> _messages = [];
  late final WebSocketChannel _channel;

  final String _toggleUrl = 'http://localhost:8080/toggle';
  final String _websocketUrl = 'ws://localhost:8080/chat';
  
  // Note: For Android emulators, use 'http://10.0.2.2:8080' instead of localhost.
  // final String _toggleUrl = 'http://10.0.2.2:8080/toggle';
  // final String _websocketUrl = 'ws://10.0.2.2:8080/chat';

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  // Establishes a connection to the WebSocket server
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_websocketUrl));
      
      // Listen for incoming messages
      _channel.stream.listen(
        (data) {
          if (data != null) {
            // Decode the JSON string and create a User object
            final messageData = jsonDecode(data);
            final message = User.fromJson(messageData);
            
            // Add the new message to the list and update the UI
            setState(() {
              _messages.insert(0, message); // Insert at the top
            });
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _showFeedback('WebSocket connection error.', isError: true);
        },
        onDone: () {
          print('WebSocket connection closed.');
          _showFeedback('WebSocket connection closed.');
        },
      );
    } catch (e) {
      print("Error connecting to WebSocket: $e");
      _showFeedback('Could not connect to WebSocket.', isError: true);
    }
  }

  // Sends a GET request to the /toggle endpoint
  Future<void> _toggleBroadcast() async {
    try {
      final response = await http.get(Uri.parse(_toggleUrl));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final status = body['status'];
        final message = body['message'];

        setState(() {
          _isBroadcasting = (status == 'started');
        });
        _showFeedback(message);
      } else {
        _showFeedback('Server error: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showFeedback('Could not connect to the server.', isError: true);
    }
  }
  
  // Helper method to show a SnackBar
  void _showFeedback(String message, {bool isError = false}) {
     if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    // It's important to close the connection when the screen is disposed
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Chat'),
        backgroundColor: const Color(0xFF1F1F1F),
        actions: [
          // This is the toggle button
          IconButton(
            onPressed: _toggleBroadcast,
            icon: Icon(
              _isBroadcasting ? Icons.stop_circle_outlined : Icons.play_circle_outline,
              color: _isBroadcasting ? Colors.redAccent : Colors.cyanAccent,
            ),
            tooltip: _isBroadcasting ? 'Stop Broadcast' : 'Start Broadcast',
          ),
        ],
      ),
      body: _messages.isEmpty
          ? Center(
              child: Text(
                'No messages yet.\nPress the play button to start receiving chats.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            )
          : ListView.builder(
              reverse: true, // Shows latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(
                    message.user ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                  ),
                  subtitle: Text(
                    message.message ?? '...',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    message.timestamp != null ? TimeOfDay.fromDateTime(DateTime.parse(message.timestamp!)).format(context) : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                );
              },
            ),
    );
  }
}
