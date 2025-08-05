import 'package:flutter/material.dart';
import '../services/collection_service.dart';

class PokemonCardAddDialog extends StatefulWidget {
  final String cardName;
  final String displayName;

  const PokemonCardAddDialog({
    super.key,
    required this.cardName,
    required this.displayName,
  });

  @override
  State<PokemonCardAddDialog> createState() => _PokemonCardAddDialogState();
}

class _PokemonCardAddDialogState extends State<PokemonCardAddDialog> {
  final CollectionService _collectionService = CollectionService();
  String _selectedVariant = 'normal';

  @override
  Widget build(BuildContext context) {
    final variants = _collectionService.getCardVariants(widget.cardName);

    return AlertDialog(
      title: Text('Ajouter une carte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Sélectionnez la variante :'),
          const SizedBox(height: 12),
          
          // Option normale
          RadioListTile<String>(
            value: 'normal',
            groupValue: _selectedVariant,
            onChanged: (value) {
              setState(() {
                _selectedVariant = value!;
              });
            },
            title: Row(
              children: [
                const Text('Normale'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Text(
                    '${variants['normal'] ?? 0}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            dense: true,
          ),
          
          // Option reverse
          RadioListTile<String>(
            value: 'reverse',
            groupValue: _selectedVariant,
            onChanged: (value) {
              setState(() {
                _selectedVariant = value!;
              });
            },
            title: Row(
              children: [
                const Text('Reverse'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[300]!),
                  ),
                  child: Text(
                    '${variants['reverse'] ?? 0}',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _collectionService.addCardWithVariant(widget.cardName, _selectedVariant);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
