import '../models/game_model.dart';
import '../services/auto_game_service.dart';

/// Feature flags / masquage conditionnel de contenu.
/// Permet de masquer certains jeux (ex: Pokémon) sans supprimer le code ou les assets.
class FeatureFlags {
  /// Active le masquage de Pokémon dans les écrans Collection / Échanges / Statistiques
  static const bool hidePokemon = true;

  /// Mode analytics minimal : ne remonter que l'utilisateur unique (userId) et les pages vues.
  /// Si true : on ignore les événements personnalisés (add_card, remove_card, etc.).
  static const bool analyticsMinimal = true;

  /// Empêche l'envoi de plusieurs screen_view pour la même page dans une session.
  static const bool deduplicateScreenViews = true;

  /// Vérifie si un jeu doit être masqué.
  static bool isGameHidden(GameModel game) {
    if (!hidePokemon) return false;
  return AutoGameService.isPokemonGame(game.name);
  }
}
