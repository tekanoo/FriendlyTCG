import 'dart:io';

// ignore_for_file: avoid_print

void main() {
  print('🎯 Génération automatique des cartes...');
  
  final assetsDir = Directory('assets/images');
  if (!assetsDir.existsSync()) {
    print('❌ Dossier assets/images introuvable');
    exit(1);
  }
  
  final output = StringBuffer();
  output.writeln('// Généré automatiquement - Ne pas modifier');
  output.writeln('class GeneratedCardsList {');
  
  final allExtensions = <String>[];
  final gameStructure = <String, List<String>>{};
  
  for (final gameDir in assetsDir.listSync().whereType<Directory>()) {
    final gameName = gameDir.path.split(Platform.pathSeparator).last;
    gameStructure[gameName] = [];
    print('🎮 Jeu détecté: $gameName');
    
    for (final extDir in gameDir.listSync().whereType<Directory>()) {
      final extName = extDir.path.split(Platform.pathSeparator).last;
      allExtensions.add(extName);
      gameStructure[gameName]!.add(extName);
      print('  📂 Extension: $extName');
      
      final cards = extDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .map((f) => f.path.split(Platform.pathSeparator).last)
          .toList()..sort();
      
      print('    📋 ${cards.length} cartes trouvées');
      
      final methodName = 'get${extName.split(RegExp(r'[_\-]'))
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join('')}Cards';
      
      output.writeln('  static List<String> $methodName() => [');
      for (final card in cards) {
        output.writeln('    "$card",');
      }
      output.writeln('  ];');
    }
  }
  
  output.writeln('  static Map<String, List<String>> getGameStructure() => {');
  for (final entry in gameStructure.entries) {
    output.writeln('    "${entry.key}": [');
    for (final ext in entry.value) {
      output.writeln('      "$ext",');
    }
    output.writeln('    ],');
  }
  output.writeln('  };');
  
  output.writeln('  static List<String> getAllExtensionIds() => [');
  for (final ext in allExtensions) {
    output.writeln('    "$ext",');
  }
  output.writeln('  ];');
  
  output.writeln('  static String? getGameForExtension(String extId) {');
  output.writeln('    for (final entry in getGameStructure().entries) {');
  output.writeln('      if (entry.value.contains(extId)) return entry.key;');
  output.writeln('    }');
  output.writeln('    return null;');
  output.writeln('  }');
  
  output.writeln('  static List<String> getCardsByExtensionId(String extId) {');
  output.writeln('    switch (extId) {');
  for (final ext in allExtensions) {
    final methodName = 'get${ext.split(RegExp(r'[_\-]'))
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join('')}Cards';
    output.writeln('      case "$ext": return $methodName();');
  }
  output.writeln('      default: return [];');
  output.writeln('    }');
  output.writeln('  }');
  
  output.writeln('  static String getCardPath(String extId, String cardName) {');
  output.writeln('    final game = getGameForExtension(extId);');
  output.writeln('    if (game == null) return "";');
  output.writeln('    return "assets/images/\$game/\$extId/\$cardName";');
  output.writeln('  }');
  
  output.writeln('}');
  
  File('lib/services/generated_cards_list.dart').writeAsStringSync(output.toString());
  print('✅ Fichier généré avec succès');
  print('📊 ${gameStructure.length} jeux, ${allExtensions.length} extensions');
}
