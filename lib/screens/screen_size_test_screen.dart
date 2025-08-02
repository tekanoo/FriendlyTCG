import 'package:flutter/material.dart';
import '../widgets/adaptive_card_grid.dart';

class ScreenSizeTestScreen extends StatefulWidget {
  const ScreenSizeTestScreen({super.key});

  @override
  State<ScreenSizeTestScreen> createState() => _ScreenSizeTestScreenState();
}

class _ScreenSizeTestScreenState extends State<ScreenSizeTestScreen> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final aspectRatio = CardAspectRatioCalculator.calculate(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Tailles d\'Écran'),
        backgroundColor: Colors.purple[100],
      ),
      body: Column(
        children: [
          // Informations d'écran
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations d\'Écran',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Largeur: ${screenSize.width.toInt()}px'),
                Text('Hauteur: ${screenSize.height.toInt()}px'),
                Text('Ratio calculé: ${aspectRatio.toStringAsFixed(2)}'),
                Text('Orientation: ${screenSize.width > screenSize.height ? "Paysage" : "Portrait"}'),
              ],
            ),
          ),
          
          // Grille de test avec cartes simulées
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: 9, // 3x3 grille
                      itemBuilder: (context, index) {
                        return _TestCard(index: index + 1);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Simulation pagination
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Page précédente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[100],
                    foregroundColor: Colors.purple[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: const Text('1 / 1'),
                ),
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Page suivante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[100],
                    foregroundColor: Colors.purple[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final int index;

  const _TestCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[100]!,
              Colors.purple[200]!,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 40,
              color: Colors.purple[700],
            ),
            const SizedBox(height: 8),
            Text(
              'Carte $index',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Test',
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
