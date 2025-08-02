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
              constraints: const BoxConstraints(maxWidth: 800), // Limite la largeur sur grands écrans
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // Ratio ajusté pour des cartes plus hautes
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
              itemCount: extensions.length,
              itemBuilder: (context, index) {
                final extension = extensions[index];
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
              },
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
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image de l'extension (taille augmentée)
              Container(
                height: 220, // Taille augmentée pour une meilleure visibilité
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    extension.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Informations de l'extension (hauteur ajustée)
              Container(
                height: 90, // Hauteur légèrement augmentée
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      extension.name,
                      style: TextStyle(
                        fontSize: 16, // Taille de police augmentée
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      extension.description,
                      style: TextStyle(
                        fontSize: 12, // Taille de police augmentée
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${extension.cardImages.length} cartes',
                          style: TextStyle(
                            fontSize: 12, // Taille de police augmentée
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14, // Icône plus grande
                          color: Colors.blue[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
