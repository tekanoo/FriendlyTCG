import 'package:flutter/material.dart';

class AdaptiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double maxWidth;

  const AdaptiveCardGrid({
    super.key,
    required this.children,
    this.padding,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer le nombre de colonnes basé sur la largeur
        int crossAxisCount;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4; // Écrans très larges
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3; // Écrans larges (tablet/desktop)
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2; // Écrans moyens (petites tablettes)
        } else {
          crossAxisCount = 1; // Mobiles
        }
        
        // Calculer le ratio optimal basé sur la hauteur disponible
        final screenHeight = MediaQuery.of(context).size.height;
        final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top + 60; // AppBar + SearchBar
        final paginationHeight = 80.0; // Hauteur approximative de la pagination
        final headerHeight = 80.0; // Hauteur approximative du header
        final availableHeight = screenHeight - appBarHeight - paginationHeight - headerHeight;
        
        // Calculer l'aspect ratio pour que les lignes tiennent dans la hauteur disponible
        final itemHeight = (availableHeight - (2 * 12) - (padding?.vertical ?? 32)) / 3; // 3 lignes + espacing
        final itemWidth = (constraints.maxWidth - (2 * 12) - (padding?.horizontal ?? 48)) / crossAxisCount;
        final aspectRatio = (itemWidth / itemHeight).clamp(0.6, 1.2); // Limiter le ratio
        
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: GridView.builder(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
            ),
          ),
        );
      },
    );
  }
}

/// Calculateur d'aspect ratio optimisé pour cartes
class CardAspectRatioCalculator {
  static double calculate(BuildContext context, {
    int maxRows = 3,
    int columns = 3,
    double minRatio = 0.6,
    double maxRatio = 0.8,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Hauteurs fixes
    const appBarHeight = kToolbarHeight + 60; // AppBar + SearchBar
    const paginationHeight = 80.0;
    const headerHeight = 80.0;
    const padding = 32.0;
    
    final availableHeight = screenHeight - appBarHeight - paginationHeight - headerHeight - padding;
    final availableWidth = screenWidth.clamp(0.0, 1200.0) - 48; // Max width avec padding
    
    // Calculer les dimensions idéales
    final itemHeight = (availableHeight - ((maxRows - 1) * 12)) / maxRows;
    final itemWidth = (availableWidth - ((columns - 1) * 12)) / columns;
    
    final calculatedRatio = (itemWidth / itemHeight).clamp(minRatio, maxRatio);
    
    return calculatedRatio;
  }
}
