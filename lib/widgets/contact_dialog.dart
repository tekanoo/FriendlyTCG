import 'package:flutter/material.dart';

class ContactDialog extends StatelessWidget {
  final String title;
  final String offerText;
  final String cardText;
  final void Function(String message) onSend;

  const ContactDialog({
    Key? key,
    required this.title,
    required this.offerText,
    required this.cardText,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messageController = TextEditingController();
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offerText),
          Text(cardText),
          const SizedBox(height: 16),
          TextField(
            controller: messageController,
            decoration: const InputDecoration(
              labelText: 'Votre message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final message = messageController.text.trim();
            if (message.isNotEmpty) {
              Navigator.of(context).pop();
              onSend(message);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez saisir un message')),
              );
            }
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
