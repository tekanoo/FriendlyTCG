import 'package:flutter/material.dart';
import '../models/collection_stats.dart';
import '../services/collection_stats_service.dart';
import '../services/collection_service.dart';

class CollectionOverviewWidget extends StatefulWidget {
  const CollectionOverviewWidget({super.key});

  @override
  State<CollectionOverviewWidget> createState() => _CollectionOverviewWidgetState();
}

class _CollectionOverviewWidgetState extends State<CollectionOverviewWidget> {
  final CollectionStatsService _statsService = CollectionStatsService();
  final CollectionService _collectionService = CollectionService();
  List<CollectionStats> _gameStats = [];
  final Map<String, bool> _expandedGames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    
    // Écouter les changements de collection
    _collectionService.collectionStream.listen((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final stats = _statsService.getCollectionStats();
    if (mounted) {
      setState(() {
        _gameStats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_gameStats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune collection trouvée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Titre
          Text(
            'Ma Collection',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Organisée par jeux et extensions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Statistiques globales
          _buildGlobalStats(),
          const SizedBox(height: 24),
          
          // Liste des jeux
          ...(_gameStats.map((gameStat) => _buildGameCard(gameStat))),
        ],
      ),
    );
  }

  Widget _buildGlobalStats() {
    final totalOwnedCards = _gameStats.fold<int>(0, (sum, game) => sum + game.totalOwnedCards);
    final totalAvailableCards = _gameStats.fold<int>(0, (sum, game) => sum + game.totalAvailableCards);
    final globalPercentage = totalAvailableCards > 0 ? (totalOwnedCards / totalAvailableCards) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Statistiques Globales',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Cartes Possédées',
                    '$totalOwnedCards',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Disponible',
                    '$totalAvailableCards',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completion',
                    '${globalPercentage.toStringAsFixed(1)}%',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: globalPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                globalPercentage < 30 ? Colors.red :
                globalPercentage < 70 ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGameCard(CollectionStats gameStat) {
    final isExpanded = _expandedGames[gameStat.gameId] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedGames[gameStat.gameId] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gameStat.gameName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${gameStat.totalOwnedCards} / ${gameStat.totalAvailableCards} cartes',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${gameStat.completionPercentage.toStringAsFixed(1)}% complété',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${gameStat.extensions.length} extensions',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: gameStat.completionPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      gameStat.completionPercentage < 30 ? Colors.red :
                      gameStat.completionPercentage < 70 ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildExtensionsList(gameStat.extensions),
        ],
      ),
    );
  }

  Widget _buildExtensionsList(List<ExtensionStats> extensions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: extensions.map((extension) => _buildExtensionItem(extension)).toList(),
      ),
    );
  }

  Widget _buildExtensionItem(ExtensionStats extension) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Icône de l'extension
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: extension.completionPercentage > 0 ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.extension,
              color: extension.completionPercentage > 0 ? Colors.blue : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Informations de l'extension
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extension.extensionName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${extension.ownedCards} / ${extension.totalCards} cartes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: extension.completionPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    extension.completionPercentage < 30 ? Colors.red :
                    extension.completionPercentage < 70 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Pourcentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: extension.completionPercentage < 30 ? Colors.red[100] :
                     extension.completionPercentage < 70 ? Colors.orange[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${extension.completionPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: extension.completionPercentage < 30 ? Colors.red[800] :
                       extension.completionPercentage < 70 ? Colors.orange[800] : Colors.green[800],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
