import 'lib/services/auto_game_service.dart';

void main() {
  print('=== Diagnostic du tri des cartes ===');
  
  final extensions = AutoGameService.getAllExtensions();
  
  for (final extension in extensions) {
    print('\n📦 Extension: ${extension.name} (${extension.id})');
    final cards = AutoGameService.getCardsForExtension(extension.id);
    
    print('Premières 10 cartes:');
    for (int i = 0; i < 10 && i < cards.length; i++) {
      print('  ${i + 1}. ${cards[i]}');
    }
    
    if (cards.length > 10) {
      print('  ...');
      print('  ${cards.length - 1}. ${cards[cards.length - 2]}');
      print('  ${cards.length}. ${cards[cards.length - 1]}');
    }
  }
}
