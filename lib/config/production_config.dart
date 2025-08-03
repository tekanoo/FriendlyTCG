/// Configuration pour le mode production
class ProductionConfig {
  // En production, on désactive tous les logs de debug
  static const bool isDebugMode = false;
  
  /// Log conditionnel pour le debug uniquement
  static void debugLog(String message) {
    if (isDebugMode) {
      // En production, les logs sont désactivés
      // ignore: avoid_print
      print(message);
    }
  }
}
