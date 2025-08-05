import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../services/auto_game_service.dart';
import '../models/extension_model.dart';
import 'extension_gallery_screen.dart';

class ExtensionsScreen extends StatefulWidget {
  final String? gameId;
  final String? gameTitle;

  const ExtensionsScreen({
    super.key,
    this.gameId,
    this.gameTitle,
  });

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen> {
  @override
  void initState() {
    super.initState();
    // Invalider le cache pour s'assurer d'avoir les dernières données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invalidateCache();
    });
  }

  void _invalidateCache() {
    AutoGameService.invalidateCache();
  }

  @override
  Widget build(BuildContext context) {
    final gameService = GameService();
    
    // Si gameId est fourni, récupérer les extensions pour ce jeu
    // Sinon, utiliser la logique par défaut (pour rétrocompatibilité)
    List<ExtensionModel> extensions;
    String title;
    
    if (widget.gameId != null) {
      extensions = gameService.getExtensionsForGame(widget.gameId!);
      title = widget.gameTitle ?? 'Extensions';
    } else {
      // Logique par défaut - Gundam
      extensions = gameService.getExtensionsForGame('gundam_card_game');
      title = 'Extensions';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extensions disponibles',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: extensions.map((extension) {
                  return _ExtensionCard(
                    extension: extension,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExtensionGalleryScreen(
                            extension: extension,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtensionCard extends StatelessWidget {
  final ExtensionModel extension;
  final VoidCallback onTap;

  const _ExtensionCard({
    required this.extension,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image de l'extension (taille native, sans bordures)
          Image.asset(
            extension.imagePath,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 300,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Informations de l'extension
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              children: [
                Text(
                  extension.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${extension.cardImages.length} cartes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
