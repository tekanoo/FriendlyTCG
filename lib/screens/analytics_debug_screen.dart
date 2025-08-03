import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/collection_service.dart';

class AnalyticsDebugScreen extends StatefulWidget {
  const AnalyticsDebugScreen({super.key});

  @override
  State<AnalyticsDebugScreen> createState() => _AnalyticsDebugScreenState();
}

class _AnalyticsDebugScreenState extends State<AnalyticsDebugScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final CollectionService _collectionService = CollectionService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Analytics Debug'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Analytics Debug',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Testez les événements Analytics et vérifiez la console Firebase',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Statut Analytics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _analyticsService.isInitialized ? Icons.check_circle : Icons.error,
                          color: _analyticsService.isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'État de Firebase Analytics',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _analyticsService.isInitialized 
                          ? '✅ Analytics initialisé et prêt'
                          : '❌ Analytics non initialisé',
                      style: TextStyle(
                        color: _analyticsService.isInitialized ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons de test
            const Text(
              'Tests d\'événements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildTestButton(
              'Test App Start',
              Icons.play_arrow,
              Colors.blue,
              () => _analyticsService.logAppStart(),
            ),
            
            _buildTestButton(
              'Test Login',
              Icons.login,
              Colors.green,
              () => _analyticsService.logLogin(method: 'test'),
            ),
            
            _buildTestButton(
              'Test View Game',
              Icons.games,
              Colors.orange,
              () => _analyticsService.logViewGame(
                gameId: 'test_game',
                gameName: 'Test Game',
              ),
            ),
            
            _buildTestButton(
              'Test Add Card',
              Icons.add,
              Colors.purple,
              () => _analyticsService.logAddCard(
                cardName: 'TEST-001.png',
                gameId: 'test_game',
                extensionId: 'test_extension',
              ),
            ),
            
            _buildTestButton(
              'Test Collection Stats',
              Icons.analytics,
              Colors.teal,
              () => _sendCollectionStats(),
            ),
            
            _buildTestButton(
              'Test Screen View',
              Icons.screen_share,
              Colors.indigo,
              () => _analyticsService.logScreenView(
                screenName: 'analytics_debug',
                screenClass: 'AnalyticsDebugScreen',
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Comment vérifier les Analytics',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Allez sur la console Firebase'),
                    const Text('2. Sélectionnez votre projet'),
                    const Text('3. Allez dans Analytics > Dashboard'),
                    const Text('4. Cliquez sur "Realtime" pour voir les événements en temps réel'),
                    const Text('5. Testez les boutons ci-dessus'),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Les événements peuvent prendre quelques minutes à apparaître dans la console.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, IconData icon, Color color, Future<void> Function() onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await onPressed();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Événement envoyé: $title'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Future<void> _sendCollectionStats() async {
    final collection = _collectionService.collection;
    final structuredCollection = _collectionService.structuredCollection;
    
    final Map<String, int> cardsByGame = {};
    for (final entry in structuredCollection.games.entries) {
      cardsByGame[entry.key] = entry.value.extensions.values
          .fold(0, (sum, ext) => sum + ext.cards.length);
    }
    
    await _analyticsService.logCollectionStats(
      totalCards: collection.totalCards,
      uniqueCards: collection.totalUniqueCards,
      totalGames: structuredCollection.games.length,
      cardsByGame: cardsByGame,
    );
  }
}
