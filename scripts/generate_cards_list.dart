import 'dart:io';

void main() {
  print('🎯 Génération automatique de la liste des cartes...');
  
  final assetsDir = Directory('assets/images/Gundam Cards');
  
  if (!assetsDir.existsSync()) {
    print('❌ Le dossier assets/images/Gundam Cards n\'existe pas');
    exit(1);
  }
  
  final StringBuffer output = StringBuffer();
  output.writeln('// Ce fichier est généré automatiquement par scripts/generate_cards_list.dart');
  output.writeln('// Ne pas modifier manuellement');
  output.writeln('');
  output.writeln('class GeneratedCardsList {');
  
  final List<String> extensionIds = [];
  
  // Parcourir chaque dossier d'extension
  for (final extensionDir in assetsDir.listSync().whereType<Directory>()) {
    final extensionName = extensionDir.path.split(Platform.pathSeparator).last;
    extensionIds.add(extensionName);
    print('📂 Extension trouvée: $extensionName');
    
    // Récupérer tous les fichiers PNG
    final cardFiles = extensionDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.png'))
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toList()
      ..sort();
    
    print('   📋 ${cardFiles.length} cartes trouvées');
    
    // Générer la méthode pour cette extension
    final methodName = _toMethodName(extensionName);
    output.writeln('  static List<String> $methodName() {');
    output.writeln('    return [');
    
    for (final cardFile in cardFiles) {
      output.writeln('      \'$cardFile\',');
    }
    
    output.writeln('    ];');
    output.writeln('  }');
    output.writeln('');
  }
  
  // Ajouter une méthode pour obtenir tous les IDs d'extensions
  output.writeln('  static List<String> getAllExtensionIds() {');
  output.writeln('    return [');
  for (final extensionId in extensionIds) {
    output.writeln('      \'$extensionId\',');
  }
  output.writeln('    ];');
  output.writeln('  }');
  output.writeln('');
  
  // Ajouter une méthode pour obtenir les cartes par ID d'extension
  output.writeln('  static List<String> getCardsByExtensionId(String extensionId) {');
  output.writeln('    switch (extensionId) {');
  for (final extensionDir in assetsDir.listSync().whereType<Directory>()) {
    final extensionName = extensionDir.path.split(Platform.pathSeparator).last;
    final methodName = _toMethodName(extensionName);
    output.writeln('      case \'$extensionName\':');
    output.writeln('        return $methodName();');
  }
  output.writeln('      default:');
  output.writeln('        return [];');
  output.writeln('    }');
  output.writeln('  }');
  
  output.writeln('}');
  
  // Écrire le fichier généré
  final outputFile = File('lib/services/generated_cards_list.dart');
  outputFile.writeAsStringSync(output.toString());
  
  print('✅ Fichier généré: ${outputFile.path}');
  print('🎉 Génération terminée !');
}

String _toMethodName(String extensionName) {
  // Convertir le nom d'extension en nom de méthode Dart valide
  return 'get${extensionName.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join('')}Cards';
}
