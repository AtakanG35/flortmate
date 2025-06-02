import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class ChatPage extends StatefulWidget {
  final String matchedUserId;
  final String matchedUserName;
  final String? matchedUserPhotoUrl;

  const ChatPage({
    Key? key,
    required this.matchedUserId,
    required this.matchedUserName,
    this.matchedUserPhotoUrl,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

enum MessageType { text, image, video, audio }

class _ChatPageState extends State<ChatPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final Record _audioRecorder = Record();

  bool _isSending = false;
  bool _isRecording = false;

  String get chatId {
    if (currentUserId.compareTo(widget.matchedUserId) > 0) {
      return '$currentUserId-${widget.matchedUserId}';
    } else {
      return '${widget.matchedUserId}-$currentUserId';
    }
  }

  Future<void> sendMessage({
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? duration,
  }) async {
    if (text.trim().isEmpty && mediaUrl == null) return;

    setState(() => _isSending = true);
    _messageController.clear();
    FocusScope.of(context).unfocus();

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final messageData = {
      'senderId': currentUserId,
      'receiverId': widget.matchedUserId,
      'text': type == MessageType.text ? text.trim() : '',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'sending': true,
      'type': type.toString().split('.').last,
      'mediaUrl': mediaUrl ?? '',
      'duration': duration ?? 0,
    };

    await messageRef.set(messageData);

    scrollToBottom();

    await messageRef.update({'sending': false});
    setState(() => _isSending = false);

    scrollToBottom();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> markMessageAsRead(String messageId) async {
    final docRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      if (data['receiverId'] == currentUserId && data['read'] == false) {
        await docRef.update({'read': true});
      }
    }
  }

  void _onMessageLongPress(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı sil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .doc(messageId)
                  .delete();
              Navigator.of(context).pop();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget buildMessage(DocumentSnapshot doc) {
    final messageData = doc.data()! as Map<String, dynamic>;
    final isMe = messageData['senderId'] == currentUserId;
    final text = messageData['text'] ?? '';
    Timestamp? timestamp = messageData['timestamp'];
    DateTime time = timestamp != null ? timestamp.toDate() : DateTime.now();

    final bool sending = messageData['sending'] ?? false;
    final bool read = messageData['read'] ?? false;
    final String typeStr = messageData['type'] ?? 'text';
    final String mediaUrl = messageData['mediaUrl'] ?? '';
    final int duration = messageData['duration'] ?? 0;

    MessageType type = MessageType.text;
    if (typeStr == 'image') {
      type = MessageType.image;
    } else if (typeStr == 'video') {
      type = MessageType.video;
    } else if (typeStr == 'audio') {
      type = MessageType.audio;
    }

    if (!isMe && !read) {
      markMessageAsRead(doc.id);
    }

    Widget messageContent;

    switch (type) {
      case MessageType.text:
        messageContent = Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
        );
        break;

      case MessageType.image:
        messageContent = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(),
                  body: Center(child: Image.network(mediaUrl)),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              mediaUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        );
        break;

      case MessageType.video:
        messageContent = GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video oynatıcı eklenmeli')));
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(mediaUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6), BlendMode.darken),
              ),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
            ),
          ),
        );
        break;

      case MessageType.audio:
        messageContent = AudioPlayerWidget(url: mediaUrl, duration: duration);
        break;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () => _onMessageLongPress(doc.id) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isMe ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              messageContent,
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isMe)
                    Icon(
                      read ? Icons.done_all : Icons.done,
                      size: 14,
                      color: read ? Colors.lightGreenAccent : Colors.white70,
                    ),
                  if (sending)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileName = path.basename(file.path);
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_media')
        .child(chatId)
        .child('images')
        .child(fileName);

    try {
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      await sendMessage(text: '', type: MessageType.image, mediaUrl: url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mikrofon izni gerekli')),
      );
      return;
    }

    try {
      await _audioRecorder.start();
      setState(() => _isRecording = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başlatılamadı: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path == null) return;

      final file = File(path);
      final fileName = file.path.split('/').last;

      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_media')
          .child(chatId)
          .child('audio')
          .child(fileName);

      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();

      await sendMessage(text: '', type: MessageType.audio, mediaUrl: url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt durdurulamadı: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.matchedUserPhotoUrl != null &&
                widget.matchedUserPhotoUrl!.isNotEmpty)
              CircleAvatar(
                backgroundImage: NetworkImage(widget.matchedUserPhotoUrl!),
              )
            else
              const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.matchedUserName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('Henüz mesaj yok'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return buildMessage(docs[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[100],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  color: _isRecording ? Colors.red : null,
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopRecording();
                    } else {
                      await _startRecording();
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Mesaj yaz...',
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        sendMessage(text: value.trim());
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isSending
                      ? null
                      : () {
                    final text = _messageController.text.trim();
                    if (text.isNotEmpty) {
                      sendMessage(text: text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final int duration;

  const AudioPlayerWidget({Key? key, required this.url, required this.duration})
      : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.url);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlayback,
        ),
        const Text("Ses"),
      ],
    );
  }
}
