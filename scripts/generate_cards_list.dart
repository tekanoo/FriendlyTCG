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
      
      cardFiles.sort(_smartCardSort);
      
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

/// Tri intelligent des cartes : prend en compte les numéros dans les noms de fichiers
int _smartCardSort(String a, String b) {
  // Cas spécial pour les cartes Pokémon avec format SV8pt5_FR_X.png
  final pokemonRegex = RegExp(r'SV\d+pt\d+_FR_(\d+)');
  final pokemonMatchA = pokemonRegex.firstMatch(a);
  final pokemonMatchB = pokemonRegex.firstMatch(b);
  
  if (pokemonMatchA != null && pokemonMatchB != null) {
    final numberA = int.parse(pokemonMatchA.group(1)!);
    final numberB = int.parse(pokemonMatchB.group(1)!);
    return numberA.compareTo(numberB);
  }
  
  // Cas spécial pour les cartes Gundam - trier par ordre alphabétique des préfixes
  final prefixA = _extractGundamPrefix(a);
  final prefixB = _extractGundamPrefix(b);
  
  if (prefixA != null && prefixB != null) {
    // Si les préfixes sont différents, trier par ordre alphabétique
    if (prefixA != prefixB) {
      return prefixA.compareTo(prefixB);
    }
    
    // Même préfixe, trier par numéro
    final numberA = _extractGundamNumber(a);
    final numberB = _extractGundamNumber(b);
    
    if (numberA != null && numberB != null) {
      if (numberA != numberB) {
        return numberA.compareTo(numberB);
      }
      
      // Même numéro de base, gérer les variantes
      final variantA = _extractVariantSuffix(a);
      final variantB = _extractVariantSuffix(b);
      
      // Ordre: carte de base, puis variantes, puis autres suffixes
      if (variantA.isEmpty && variantB.isNotEmpty) return -1;
      if (variantA.isNotEmpty && variantB.isEmpty) return 1;
      
      return variantA.compareTo(variantB);
    }
  }
  
  // Tri général basé sur les numéros extraits
  final aNumbers = _extractNumbers(a);
  final bNumbers = _extractNumbers(b);
  
  // Si les deux ont des numéros au même endroit, comparer numériquement
  for (int i = 0; i < aNumbers.length && i < bNumbers.length; i++) {
    if (aNumbers[i] != bNumbers[i]) {
      return aNumbers[i].compareTo(bNumbers[i]);
    }
  }
  
  // Si une carte a plus de numéros, elle vient après
  if (aNumbers.length != bNumbers.length) {
    return aNumbers.length.compareTo(bNumbers.length);
  }
  
  // Sinon, tri alphabétique standard
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Extrait le préfixe d'une carte Gundam (GD01, EXB, EXR, R, T)
String? _extractGundamPrefix(String cardName) {
  final patterns = [
    RegExp(r'^(GD\d+)-'),
    RegExp(r'^(EXB)-'),
    RegExp(r'^(EXR)-'),
    RegExp(r'^(R)-'),
    RegExp(r'^(T)-'),
  ];
  
  for (final pattern in patterns) {
    final match = pattern.firstMatch(cardName);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}

/// Extrait le numéro principal d'une carte Gundam
int? _extractGundamNumber(String cardName) {
  final patterns = [
    RegExp(r'GD\d+-(\d+)'),
    RegExp(r'EXB-(\d+)'),
    RegExp(r'EXR-(\d+)'),
    RegExp(r'R-(\d+)'),
    RegExp(r'T-(\d+)'),
  ];
  
  for (final pattern in patterns) {
    final match = pattern.firstMatch(cardName);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
  }
  return null;
}

/// Extrait le suffixe variant/spécial d'une carte
String _extractVariantSuffix(String cardName) {
  final patterns = [
    RegExp(r'_Variante_P(\d+)'),
    RegExp(r'_p(\d+)'),
    RegExp(r'-(\d+x)'),
  ];
  
  for (final pattern in patterns) {
    final match = pattern.firstMatch(cardName);
    if (match != null) {
      return match.group(0)!;
    }
  }
  return '';
}

/// Extrait tous les nombres d'une chaîne de caractères
List<int> _extractNumbers(String input) {
  final RegExp numberRegex = RegExp(r'\d+');
  return numberRegex.allMatches(input)
      .map((match) => int.parse(match.group(0)!))
      .toList();
}

String _toMethodName(String extensionName) {
  // Convertir le nom d'extension en nom de méthode valide
  // Remplacer les tirets par des underscores, puis traiter normalement
  final cleanName = extensionName.replaceAll('-', '_');
  return 'get${cleanName.split('_').map((word) => 
    word[0].toUpperCase() + word.substring(1).toLowerCase()).join('')}Cards';
}
