import 'dart:io';

// ignore_for_file: avoid_print

void main() {
  print('🎯 Génération automatique de la liste des cartes pour tous les jeux...');
  
  final assetsDir = Directory('assets/images');
  
  if (!assetsDir.existsSync()) {
    print('❌ Le dossier assets/images n\'existe pas');
    exit(1);
  }
  
  final StringBuffer output = StringBuffer();
  output.writeln('// Ce fichier est généré automatiquement par scripts/generate_cards_list.dart');
  output.writeln('// Ne pas modifier manuellement');
  output.writeln('');
  output.writeln('class GeneratedCardsList {');
  output.writeln('');
  
  final Map<String, List<String>> gameStructure = {};
  final List<String> allExtensionIds = [];
  final Map<String, String> extensionToGameMap = {};
  
  // Parcourir chaque dossier de jeu
  for (final gameDir in assetsDir.listSync().whereType<Directory>()) {
    final gameName = gameDir.path.split(Platform.pathSeparator).last;
    print('🎮 Jeu détecté: $gameName');
    
    gameStructure[gameName] = [];
    
    // Parcourir chaque dossier d'extension dans ce jeu
    for (final extensionDir in gameDir.listSync().whereType<Directory>()) {
      final extensionName = extensionDir.path.split(Platform.pathSeparator).last;
      gameStructure[gameName]!.add(extensionName);
      allExtensionIds.add(extensionName);
      extensionToGameMap[extensionName] = gameName;
      print('  📂 Extension trouvée: $extensionName');
      
      // Récupérer tous les fichiers PNG
      final cardFiles = extensionDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .map((file) => file.path.split(Platform.pathSeparator).last)
          .toList();
      
      cardFiles.sort(_naturalAlphanumericSort);
      
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
  }
  
  // Ajouter une méthode pour obtenir la structure complète des jeux
  output.writeln('  static Map<String, List<String>> getGameStructure() {');
  output.writeln('    return {');
  for (final entry in gameStructure.entries) {
    output.writeln('      \'${entry.key}\': [');
    for (final extension in entry.value) {
      output.writeln('        \'$extension\',');
    }
    output.writeln('      ],');
  }
  output.writeln('    };');
  output.writeln('  }');
  output.writeln('');
  
  // Ajouter une méthode pour obtenir tous les IDs d'extensions
  output.writeln('  static List<String> getAllExtensionIds() {');
  output.writeln('    return [');
  for (final extensionId in allExtensionIds) {
    output.writeln('      \'$extensionId\',');
  }
  output.writeln('    ];');
  output.writeln('  }');
  output.writeln('');
  
  // Ajouter une méthode pour obtenir le jeu d'une extension
  output.writeln('  static String? getGameForExtension(String extensionId) {');
  output.writeln('    final gameMap = {');
  for (final entry in extensionToGameMap.entries) {
    output.writeln('      \'${entry.key}\': \'${entry.value}\',');
  }
  output.writeln('    };');
  output.writeln('    return gameMap[extensionId];');
  output.writeln('  }');
  output.writeln('');
  
  // Ajouter une méthode pour obtenir les cartes par ID d'extension
  output.writeln('  static List<String> getCardsByExtensionId(String extensionId) {');
  output.writeln('    switch (extensionId) {');
  for (final extensionId in allExtensionIds) {
    final methodName = _toMethodName(extensionId);
    output.writeln('      case \'$extensionId\':');
    output.writeln('        return $methodName();');
  }
  output.writeln('      default:');
  output.writeln('        return [];');
  output.writeln('    }');
  output.writeln('  }');
  output.writeln('');
  
  // Ajouter une méthode pour obtenir le chemin complet d'une carte
  output.writeln('  static String getCardPath(String extensionId, String cardName) {');
  output.writeln('    final gameName = getGameForExtension(extensionId);');
  output.writeln('    if (gameName == null) return \'\';');
  output.writeln('    return \'assets/images/\$gameName/\$extensionId/\$cardName\';');
  output.writeln('  }');
  
  output.writeln('}');
  
  // Écrire le fichier généré
  final outputFile = File('lib/services/generated_cards_list.dart');
  outputFile.writeAsStringSync(output.toString());
  
  print('');
  print('✅ Fichier généré: ${outputFile.path}');
  print('📊 Statistiques:');
  print('   🎮 ${gameStructure.length} jeux détectés');
  print('   📂 ${allExtensionIds.length} extensions détectées');
  
  for (final entry in gameStructure.entries) {
    print('   - ${entry.key}: ${entry.value.length} extensions');
  }
}

/// Tri alphanumérique naturel qui gère les nombres correctement
int _naturalAlphanumericSort(String a, String b) {
  return _compareNatural(a.toLowerCase(), b.toLowerCase());
}

/// Comparaison naturelle qui gère les nombres correctement  
int _compareNatural(String a, String b) {
  final regex = RegExp(r'(\d+|\D+)');
  final aParts = regex.allMatches(a).map((m) => m.group(0)!).toList();
  final bParts = regex.allMatches(b).map((m) => m.group(0)!).toList();
  
  for (int i = 0; i < aParts.length && i < bParts.length; i++) {
    final aPart = aParts[i];
    final bPart = bParts[i];
    
    // Si les deux parties sont des nombres
    final aNum = int.tryParse(aPart);
    final bNum = int.tryParse(bPart);
    
    if (aNum != null && bNum != null) {
      final numComparison = aNum.compareTo(bNum);
      if (numComparison != 0) return numComparison;
    } else {
      // Comparaison alphabétique
      final strComparison = aPart.compareTo(bPart);
      if (strComparison != 0) return strComparison;
    }
  }
  
  // Si toutes les parties comparées sont égales, comparer par longueur
  return aParts.length.compareTo(bParts.length);
}

String _toMethodName(String extensionName) {
  // Convertir le nom d'extension en nom de méthode valide
  // Remplacer les tirets par des underscores, puis traiter normalement
  final cleanName = extensionName.replaceAll('-', '_');
  return 'get${cleanName.split('_').map((word) => 
    word[0].toUpperCase() + word.substring(1).toLowerCase()).join('')}Cards';
}
