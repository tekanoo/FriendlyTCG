import 'package:flutter/material.dart';

class CardTileWidget extends StatelessWidget {
  final String cardName;
  final String? imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final String? subtitle;

  const CardTileWidget({
    super.key,
    required this.cardName,
    this.imagePath,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => onTap(),
          activeColor: Colors.blue,
        ),
        title: Text(
          cardName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue.shade800 : null,
          ),
        ),
        subtitle: subtitle != null 
            ? Text(subtitle!)
            : null,
        trailing: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  imagePath!,
                  width: 40,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 40,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 20,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              )
            : Container(
                width: 40,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.image_not_supported,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
