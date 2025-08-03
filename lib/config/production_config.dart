/// Configuration pour le mode production
class ProductionConfig {
  // En production, on désactive tous les logs de debug
  static const bool isDebugMode = false;
  
  /// Log conditionnel pour le debug uniquement
  static void debugLog(String message) {
    if (isDebugMode) {
      print(message);
    }
  }
}
