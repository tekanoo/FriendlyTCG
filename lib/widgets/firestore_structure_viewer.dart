import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/collection_service.dart';
import '../models/structured_collection.dart';
import '../services/game_service.dart';
import '../services/extension_service.dart';

class FirestoreStructureViewer extends StatefulWidget {
  const FirestoreStructureViewer({super.key});

  @override
  State<FirestoreStructureViewer> createState() => _FirestoreStructureViewerState();
}

class _FirestoreStructureViewerState extends State<FirestoreStructureViewer> {
  final CollectionService _collectionService = CollectionService();
  final GameService _gameService = GameService();
  final ExtensionService _extensionService = ExtensionService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Structure Firestore'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Structure des données dans Firestore',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visualisation de l\'organisation par jeux et extensions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Bouton pour voir la structure JSON
            ElevatedButton.icon(
              onPressed: () => _showJsonStructure(context),
              icon: const Icon(Icons.code),
              label: const Text('Voir la structure JSON'),
            ),
            
            const SizedBox(height: 24),
            _buildStructureView(),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureView() {
    final structuredCollection = _collectionService.structuredCollection;
    
    if (structuredCollection.games.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucune carte dans la collection',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Ajoutez des cartes pour voir la structure organisée',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Résumé global
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Résumé de la Structure',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${structuredCollection.games.length} jeux trouvés'),
                const SizedBox(height: 4),
                Text('${_getTotalExtensions(structuredCollection)} extensions au total'),
                const SizedBox(height: 4),
                Text('${_getTotalCards(structuredCollection)} cartes possédées'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Structure détaillée par jeu
        ...structuredCollection.games.entries.map((gameEntry) {
          return _buildGameCard(gameEntry.key, gameEntry.value);
        }),
      ],
    );
  }

  Widget _buildGameCard(String gameId, GameCollection gameCollection) {
    final game = _gameService.getGameById(gameId);
    final gameName = game?.name ?? gameId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(Icons.games, color: Colors.green[700]),
        title: Text(
          gameName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${gameCollection.extensions.length} extensions'),
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[50],
            child: Column(
              children: gameCollection.extensions.entries.map((extensionEntry) {
                return _buildExtensionTile(extensionEntry.key, extensionEntry.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionTile(String extensionId, ExtensionCollection extensionCollection) {
    final extension = _extensionService.getExtensionById(extensionId);
    final extensionName = extension?.name ?? extensionId;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(Icons.extension, color: Colors.purple[600]),
      title: Text(
        extensionName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${extensionCollection.cards.length} cartes possédées'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: extensionCollection.cards.entries.take(5).map((cardEntry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_formatCardName(cardEntry.key)}: ${cardEntry.value}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                  ),
                ),
              );
            }).toList(),
          ),
          if (extensionCollection.cards.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... et ${extensionCollection.cards.length - 5} autres cartes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${_getTotalCardQuantity(extensionCollection.cards)}',
          style: TextStyle(
            color: Colors.green[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatCardName(String cardName) {
    return cardName.replaceAll('.png', '').replaceAll('_', ' ');
  }

  int _getTotalExtensions(StructuredCollection collection) {
    return collection.games.values
        .fold(0, (sum, game) => sum + game.extensions.length);
  }

  int _getTotalCards(StructuredCollection collection) {
    return collection.games.values
        .fold(0, (sum, game) => sum + game.extensions.values
            .fold(0, (extSum, ext) => extSum + _getTotalCardQuantity(ext.cards)));
  }

  int _getTotalCardQuantity(Map<String, int> cards) {
    return cards.values.fold(0, (sum, quantity) => sum + quantity);
  }

  void _showJsonStructure(BuildContext context) {
    final structuredCollection = _collectionService.structuredCollection;
    final jsonData = structuredCollection.toFirestore();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Structure JSON pour Firestore'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Structure JSON copiée dans le presse-papiers')),
              );
            },
            child: const Text('Copier'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
