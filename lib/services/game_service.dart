import '../models/game_model.dart';
import '../models/extension_model.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  // Liste des jeux disponibles
  final List<GameModel> _availableGames = [
    const GameModel(
      id: 'gundam_card_game',
      name: 'Gundam Card Game',
      description: 'Le jeu de cartes officiel Gundam avec des mechas légendaires',
      imagePath: 'assets/images/extensions/newtype_risings/GD01-001.png', // Image temporaire
      folderPath: 'assets/images/extensions',
    ),
    // Exemple pour Pokemon (à ajouter plus tard)
    // const GameModel(
    //   id: 'pokemon_tcg',
    //   name: 'Pokémon TCG',
    //   description: 'Le célèbre jeu de cartes Pokémon',
    //   imagePath: 'assets/images/games/pokemon_logo.png',
    //   folderPath: 'assets/images/pokemon_extensions',
    // ),
  ];

  List<GameModel> get availableGames => _availableGames;

  // Récupérer un jeu par son ID
  GameModel? getGameById(String id) {
    try {
      return _availableGames.firstWhere((game) => game.id == id);
    } catch (e) {
      return null;
    }
  }

  // Récupérer les extensions pour un jeu donné
  List<ExtensionModel> getExtensionsForGame(String gameId) {
    switch (gameId) {
      case 'gundam_card_game':
        return _getGundamExtensions();
      case 'pokemon_tcg':
        return _getPokemonExtensions();
      default:
        return [];
    }
  }

  // Extensions Gundam (existantes)
  List<ExtensionModel> _getGundamExtensions() {
    return [
      ExtensionModel(
        id: 'GD01',
        name: 'NEWTYPE RISINGS',
        description: 'L\'extension de base du Gundam Card Game',
        imagePath: 'assets/images/extensions/newtype_risings/GD01-001.png',
        cardImages: _getNewtypeRisingsCards(),
      ),
    ];
  }

  // Extensions Pokemon (exemple pour plus tard)
  List<ExtensionModel> _getPokemonExtensions() {
    // À implémenter plus tard
    return [];
  }

  // Cartes Newtype Risings (logique existante)
  List<String> _getNewtypeRisingsCards() {
    List<String> cards = [];
    
    // Cartes de base
    for (int i = 1; i <= 107; i++) {
      String cardNumber = i.toString().padLeft(3, '0');
      cards.add('assets/images/extensions/newtype_risings/GD01-$cardNumber.png');
    }
    
    // Variantes
    const Map<String, List<String>> variants = {
      '001': ['P1', 'P2'],
      '002': ['P1'],
      '003': ['P1'],
      '004': ['P1', 'P2'],
      '005': ['P1', 'P2', 'P3'],
      '006': ['P1'],
      '008': ['P1'],
      '009': ['P1'],
      '011': ['P1'],
      '012': ['P1'],
      '013': ['P1'],
      '014': ['P1', 'P2'],
      '015': ['P1'],
      '016': ['P1'],
      '017': ['P1'],
      '018': ['P1'],
      '019': ['P1'],
      '020': ['P1'],
      '021': ['P1'],
      '022': ['P1'],
      '023': ['P1'],
      '024': ['P1'],
      '025': ['P1'],
      '026': ['P1'],
      '027': ['P1'],
      '028': ['P1'],
      '029': ['P1'],
      '030': ['P1'],
      '031': ['P1'],
      '032': ['P1'],
      '033': ['P1'],
      '034': ['P1'],
      '035': ['P1'],
      '036': ['P1'],
      '037': ['P1'],
      '038': ['P1'],
      '039': ['P1'],
      '040': ['P1'],
      '041': ['P1'],
      '042': ['P1'],
      '043': ['P1'],
      '044': ['P1'],
      '045': ['P1'],
      '046': ['P1'],
      '047': ['P1'],
      '048': ['P1'],
      '049': ['P1'],
      '050': ['P1'],
      '051': ['P1'],
      '052': ['P1'],
      '053': ['P1'],
      '054': ['P1'],
      '055': ['P1'],
      '056': ['P1'],
      '057': ['P1'],
      '058': ['P1'],
      '059': ['P1'],
      '060': ['P1'],
      '061': ['P1'],
      '062': ['P1'],
      '063': ['P1'],
      '064': ['P1'],
      '065': ['P1'],
      '066': ['P1'],
      '067': ['P1'],
      '068': ['P1'],
      '069': ['P1'],
      '070': ['P1'],
      '071': ['P1'],
      '072': ['P1'],
      '073': ['P1'],
      '074': ['P1'],
      '075': ['P1'],
      '076': ['P1'],
      '077': ['P1'],
      '078': ['P1'],
      '079': ['P1'],
      '080': ['P1'],
      '081': ['P1'],
      '082': ['P1'],
      '083': ['P1'],
      '084': ['P1'],
      '085': ['P1'],
      '086': ['P1'],
      '087': ['P1'],
      '088': ['P1'],
      '089': ['P1'],
      '090': ['P1'],
      '091': ['P1'],
      '092': ['P1'],
      '093': ['P1'],
      '094': ['P1'],
      '095': ['P1'],
      '096': ['P1'],
      '097': ['P1'],
      '098': ['P1'],
      '099': ['P1'],
      '100': ['P1'],
      '101': ['P1'],
      '102': ['P1'],
      '103': ['P1'],
      '104': ['P1'],
      '105': ['P1'],
      '106': ['P1'],
      '107': ['P1'],
    };
    
    // Ajouter les variantes
    variants.forEach((cardNumber, variantList) {
      for (String variant in variantList) {
        cards.add('assets/images/extensions/newtype_risings/GD01-${cardNumber}_Variante_$variant.png');
      }
    });
    
    return cards;
  }
}
