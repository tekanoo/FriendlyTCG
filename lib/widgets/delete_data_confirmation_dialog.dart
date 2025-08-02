import 'package:flutter/material.dart';

class DeleteDataConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const DeleteDataConfirmationDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<DeleteDataConfirmationDialog> createState() => _DeleteDataConfirmationDialogState();
}

class _DeleteDataConfirmationDialogState extends State<DeleteDataConfirmationDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isFirstConfirmation = true;
  bool _canProceed = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _handleFirstConfirmation() {
    setState(() {
      _isFirstConfirmation = false;
    });
  }

  void _handleSecondConfirmation() {
    if (_confirmController.text.toLowerCase() == 'supprimer définitivement') {
      setState(() {
        _canProceed = true;
      });
    }
  }

  void _handleFinalConfirmation() {
    Navigator.of(context).pop();
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red.shade600,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            'Suppression des données',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isFirstConfirmation) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ ATTENTION - ACTION IRRÉVERSIBLE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cette action supprimera DÉFINITIVEMENT :',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Votre collection de cartes'),
                    const Text('• Tous vos échanges en cours'),
                    const Text('• L\'historique de vos messages'),
                    const Text('• Votre profil utilisateur'),
                    const Text('• Votre compte Firebase'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '💡 Conseil : Exportez vos données importantes avant de continuer.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Êtes-vous absolument certain(e) de vouloir continuer ?',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ] else if (!_canProceed) ...[
              const Text(
                'Pour confirmer, tapez exactement :',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'supprimer définitivement',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation',
                  border: OutlineInputBorder(),
                  hintText: 'Tapez le texte exact...',
                ),
                onChanged: (_) => _handleSecondConfirmation(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DERNIÈRE ÉTAPE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cliquez sur "Supprimer définitivement" pour procéder à la suppression complète de vos données.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        if (_isFirstConfirmation)
          ElevatedButton(
            onPressed: _handleFirstConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Je comprends, continuer'),
          )
        else if (!_canProceed)
          ElevatedButton(
            onPressed: null,
            child: const Text('Confirmation requise'),
          )
        else
          ElevatedButton(
            onPressed: _handleFinalConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer définitivement'),
          ),
      ],
    );
  }
}
