import 'package:flutter/material.dart';
import 'package:sorade/models/inventory_item.dart';

/// Square thumbnail for list tiles (photo or placeholder).
class InventoryItemThumbnail extends StatelessWidget {
  const InventoryItemThumbnail({
    super.key,
    required this.item,
    this.size = 48,
  });

  final InventoryItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = item.photoUrl;
    final cs = Theme.of(context).colorScheme;
    if (url == null || url.isEmpty) {
      return _placeholder(cs);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholder(cs),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Icon(Icons.inventory_2_outlined, size: size * 0.45, color: cs.onSurfaceVariant),
    );
  }
}
