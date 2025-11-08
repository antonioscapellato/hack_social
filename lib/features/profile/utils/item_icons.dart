import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

class ItemIcons {
  static Widget getIcon(ItemType type, {double size = 24, Color? color}) {
    final assetPath = _getAssetPath(type);
    
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if asset not found
        return Icon(Icons.help_outline, size: size, color: color ?? Colors.white);
      },
    );
  }

  static String _getAssetPath(ItemType type) {
    switch (type) {
      case ItemType.key:
        return 'assets/items/key.png';
      case ItemType.gem:
        return 'assets/items/gem.png';
      case ItemType.coin:
        return 'assets/items/coin.png';
      case ItemType.sword:
        return 'assets/items/sword.png';
      case ItemType.armor:
        return 'assets/items/armor.png';
      case ItemType.staff:
        return 'assets/items/staff.png';
      case ItemType.spellbook:
        return 'assets/items/spellbook.png';
      case ItemType.dagger:
        return 'assets/items/dagger.png';
      case ItemType.lockpick:
        return 'assets/items/lockpick.png';
      case ItemType.bow:
        return 'assets/items/bow.png';
      case ItemType.quiver:
        return 'assets/items/quiver.png';
      case ItemType.holySymbol:
        return 'assets/items/holy-symbol.png';
      case ItemType.shield:
        return 'assets/items/shield.png';
      case ItemType.totem:
        return 'assets/items/totem.png';
      case ItemType.herbs:
        return 'assets/items/herbs.png';
    }
  }
}
