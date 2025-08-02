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
        // Calculer le ratio optimal basé sur la hauteur disponible
        final screenHeight = MediaQuery.of(context).size.height;
        final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top + 60; // AppBar + SearchBar
        final paginationHeight = 80.0; // Hauteur approximative de la pagination
        final headerHeight = 80.0; // Hauteur approximative du header
        final availableHeight = screenHeight - appBarHeight - paginationHeight - headerHeight;
        
        // Calculer l'aspect ratio pour que 3 lignes tiennent dans la hauteur disponible
        final itemHeight = (availableHeight - (2 * 12) - (padding?.vertical ?? 32)) / 3; // 3 lignes + espacing
        final itemWidth = (constraints.maxWidth - (2 * 12) - (padding?.horizontal ?? 48)) / 3; // 3 colonnes + espacing
        final aspectRatio = (itemWidth / itemHeight).clamp(0.6, 0.8); // Limiter le ratio
        
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: GridView.builder(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
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
