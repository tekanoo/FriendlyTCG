import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final Color? primaryColor;
  final String? label;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPreviousPage,
    this.onNextPage,
    this.primaryColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final Color themeColor = primaryColor ?? Colors.blue;
    
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: currentPage > 0 ? onPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Page précédente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor.withOpacity(0.1),
              foregroundColor: themeColor.withOpacity(0.8),
              disabledBackgroundColor: Colors.grey[200],
              disabledForegroundColor: Colors.grey[500],
            ),
          ),
          
          // Indicateur de page
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null) ...[
                  Text(
                    label!,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: themeColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${currentPage + 1} / $totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          ElevatedButton.icon(
            onPressed: currentPage < totalPages - 1 ? onNextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Page suivante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor.withOpacity(0.1),
              foregroundColor: themeColor.withOpacity(0.8),
              disabledBackgroundColor: Colors.grey[200],
              disabledForegroundColor: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget d'information pour l'en-tête avec pagination
class PageHeader extends StatelessWidget {
  final int totalItems;
  final int currentPage;
  final int totalPages;
  final String itemName;
  final String? subtitle;

  const PageHeader({
    super.key,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    required this.itemName,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalItems $itemName',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (totalPages > 1)
                Text(
                  'Page ${currentPage + 1} sur $totalPages',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
