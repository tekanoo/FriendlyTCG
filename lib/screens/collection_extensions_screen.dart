import 'package:flutter/material.dart';
import '../models/extension_model.dart';
import '../services/extension_service.dart';
import 'collection_gallery_screen.dart';

class CollectionExtensionsScreen extends StatefulWidget {
  const CollectionExtensionsScreen({super.key});

  @override
  State<CollectionExtensionsScreen> createState() => _CollectionExtensionsScreenState();
}

class _CollectionExtensionsScreenState extends State<CollectionExtensionsScreen> {
  late List<ExtensionModel> extensions;

  @override
  void initState() {
    super.initState();
    final extensionService = ExtensionService();
    extensions = extensionService.availableExtensions;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Ma Collection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Consultez votre collection par extension. Les cartes grisées ne sont pas encore dans votre collection.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                            builder: (context) => CollectionGalleryScreen(
                              extension: extension,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
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
          // Image de l'extension (taille native, comme dans Extensions)
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
