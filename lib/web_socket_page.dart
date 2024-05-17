import 'package:flutter/material.dart';
import 'web_socket_manager.dart';

class WebSocketPage extends StatefulWidget {
  @override
  _WebSocketPageState createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  WebSocketManager? _webSocketManager;
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _webSocketManager = WebSocketManager(
      onMessage: (message) {
        _insertMessage(message);
      },
      onConnected: (address) {
        _insertMessage('Connected to $address');
      },
      onDisconnected: (manual) {
        _insertMessage(manual ? 'Disconnected manually' : 'Disconnected');
      },
      onError: (error) {
        _insertMessage('Error: $error');
      },
      onReconnecting: () {
        _insertMessage('Reconnecting...');
      },
      onPongTimeout: () {
        _insertMessage('PONG timeout, disconnecting...');
      },
    );
  }

  void _insertMessage(String message) {
    setState(() {
      _messages.insert(0, {
        'message': message,
        'timestamp': DateTime.now().toString()
      });
    });
  }

  void _connect() {
    if (_controller.text.isNotEmpty) {
      _webSocketManager!.connect(_controller.text);
    }
  }

  void _manualDisconnect() {
    _webSocketManager!.manualDisconnect();
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _webSocketManager!.sendMessage(_messageController.text);
      _messageController.clear();
    }
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
    _webSocketManager!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'WebSocket Address',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: _connect,
                  child: const Text('Connect'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _manualDisconnect,
                  child: const Text('Disconnect'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _clearMessages,
                  child: const Text('Clear Messages'),
                ),
              ],
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Send a message',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send'),
            ),
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(_messages[index]['message']!)),
                            Text(
                              _messages[index]['timestamp']!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Divider(), // 添加分割线
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}