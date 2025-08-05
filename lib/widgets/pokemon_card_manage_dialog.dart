import 'package:flutter/material.dart';
import '../services/collection_service.dart';

class PokemonCardManageDialog extends StatefulWidget {
  final String cardName;
  final String displayName;
  final bool isAdd; // true = ajouter, false = retirer

  const PokemonCardManageDialog({
    super.key,
    required this.cardName,
    required this.displayName,
    this.isAdd = true,
  });

  @override
  State<PokemonCardManageDialog> createState() => _PokemonCardManageDialogState();
}

class _PokemonCardManageDialogState extends State<PokemonCardManageDialog> {
  final CollectionService _collectionService = CollectionService();
  String _selectedVariant = 'normal';

  @override
  Widget build(BuildContext context) {
    final variants = _collectionService.getCardVariants(widget.cardName);

    return AlertDialog(
      title: Text(widget.isAdd ? 'Ajouter une carte' : 'Retirer une carte'),
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
          Text(widget.isAdd ? 'Sélectionnez la variante à ajouter :' : 'Sélectionnez la variante à retirer :'),
          const SizedBox(height: 12),
          
          // Option normale
          RadioListTile<String>(
            value: 'normal',
            groupValue: _selectedVariant,
            onChanged: (widget.isAdd || (variants['normal'] ?? 0) > 0) ? (value) {
              setState(() {
                _selectedVariant = value!;
              });
            } : null,
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
                    '${variants['normal'] ?? 0}x',
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
            onChanged: (widget.isAdd || (variants['reverse'] ?? 0) > 0) ? (value) {
              setState(() {
                _selectedVariant = value!;
              });
            } : null,
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
                    '${variants['reverse'] ?? 0}x',
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
          
          if (!widget.isAdd && (variants['normal'] ?? 0) == 0 && (variants['reverse'] ?? 0) == 0)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Aucune variante de cette carte dans votre collection.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _canPerformAction(variants) ? () async {
            if (widget.isAdd) {
              await _collectionService.addCardWithVariant(widget.cardName, _selectedVariant);
            } else {
              await _removeCardVariant();
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isAdd ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isAdd ? 'Ajouter' : 'Retirer'),
        ),
      ],
    );
  }

  bool _canPerformAction(Map<String, int> variants) {
    if (widget.isAdd) return true;
    
    // Pour la suppression, vérifier qu'on a au moins une carte de la variante sélectionnée
    return (variants[_selectedVariant] ?? 0) > 0;
  }

  Future<void> _removeCardVariant() async {
    final cardKey = _selectedVariant == 'normal' ? widget.cardName : '${widget.cardName}_$_selectedVariant';
    await _collectionService.removeCard(cardKey);
  }
}
