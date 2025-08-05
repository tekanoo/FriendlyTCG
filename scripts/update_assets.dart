import 'dart:io';

/// Script pour vérifier que pubspec.yaml utilise la configuration assets simplifiée
void main() async {
  print('🔧 Vérification de la configuration des assets...');
  
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ Fichier pubspec.yaml non trouvé');
    return;
  }
  
  // Lire le contenu actuel
  final content = await pubspecFile.readAsString();
  
  // Vérifier si la configuration simplifiée est utilisée
  if (content.contains('assets:\n    - assets/') || content.contains('assets:\r\n    - assets/')) {
    print('✅ Configuration simplifiée détectée : tous les assets sont automatiquement inclus');
    
    // Compter les dossiers d'extensions disponibles
    int extensionCount = 0;
    final imagesDir = Directory('assets/images');
    if (imagesDir.existsSync()) {
      for (final gameDir in imagesDir.listSync()) {
        if (gameDir is Directory) {
          for (final extensionDir in gameDir.listSync()) {
            if (extensionDir is Directory) {
              extensionCount++;
            }
          }
        }
      }
    }
    
    print('📁 Extensions détectées automatiquement: $extensionCount');
    print('🎯 Toutes les nouvelles extensions seront automatiquement prises en compte');
  } else if (content.contains('assets:')) {
    print('⚠️  Configuration manuelle détectée');
    print('💡 Recommandation: Utilisez "assets: - assets/" pour inclure automatiquement toutes les images');
    
    // Proposer la correction
    print('\n🔧 Pour appliquer la configuration automatique:');
    print('   Remplacez la section assets par:');
    print('   assets:');
    print('     - assets/');
  } else {
    print('❌ Aucune section assets trouvée dans pubspec.yaml');
  }
  
  print('\n✅ Vérification terminée');
}
