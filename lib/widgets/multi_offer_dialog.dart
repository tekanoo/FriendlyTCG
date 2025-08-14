import 'package:flutter/material.dart';

class MultiOfferDialog extends StatefulWidget {
  final List<String> cardNames;
  final void Function(Map<String, int> offers) onSend;
  const MultiOfferDialog({Key? key, required this.cardNames, required this.onSend}) : super(key: key);

  @override
  State<MultiOfferDialog> createState() => _MultiOfferDialogState();
}

class _MultiOfferDialogState extends State<MultiOfferDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final card in widget.cardNames) {
      _controllers[card] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Définir les prix d\'offre'),
      content: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final card in widget.cardNames)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(card.replaceAll('.png',''))),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _controllers[card],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prix (€)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final Map<String, int> offers = {};
            for (final card in widget.cardNames) {
              final text = _controllers[card]?.text ?? '';
              final price = int.tryParse(text.replaceAll(',', '.'));
              if (price != null && price > 0) {
                offers[card] = price * 100;
              }
            }
            if (offers.isNotEmpty) {
              Navigator.of(context).pop();
              widget.onSend(offers);
            }
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
