import 'dart:math';
import 'package:flutter/material.dart';

class MessageGeneratorPage extends StatefulWidget {
  final String language;
  final bool premiumUser;
  final VoidCallback onPremiumToggle;

  const MessageGeneratorPage({
    Key? key,
    required this.language,
    required this.premiumUser,
    required this.onPremiumToggle,
  }) : super(key: key);

  @override
  State<MessageGeneratorPage> createState() => _MessageGeneratorPageState();
}

class _MessageGeneratorPageState extends State<MessageGeneratorPage> {
  final List<String> sampleMessages = [
    "Hi! How's your day going?",
    "You look amazing in your photos!",
    "Would you like to grab coffee sometime?",
    "Hey! I love your taste in music.",
    "What's your favorite movie?",
  ];

  String? generatedMessage;

  final Random _random = Random();

  void generateMessage() {
    final message = sampleMessages[_random.nextInt(sampleMessages.length)];
    setState(() {
      generatedMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTurkish = widget.language.toLowerCase() == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTurkish ? 'Mesaj Üretici' : 'Message Generator'),
        actions: [
          // Dil değiştirme butonu kaldırıldı.
          IconButton(
            onPressed: widget.onPremiumToggle,
            icon: Icon(widget.premiumUser ? Icons.star : Icons.star_border),
            tooltip: isTurkish ? 'Premium durumunu değiştir' : 'Toggle Premium',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              isTurkish
                  ? 'Flört mesajları oluşturmak için butona basın.'
                  : 'Press the button to generate a dating message.',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (generatedMessage != null)
              Card(
                color: widget.premiumUser ? Colors.pink.shade50 : Colors.grey.shade200,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    generatedMessage!,
                    style: TextStyle(
                      fontSize: 20,
                      color: widget.premiumUser ? Colors.pink.shade900 : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    isTurkish
                        ? 'Henüz mesaj üretilmedi.'
                        : 'No message generated yet.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: generateMessage,
                icon: const Icon(Icons.message),
                label: Text(isTurkish ? 'Mesaj Üret' : 'Generate Message'),
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
