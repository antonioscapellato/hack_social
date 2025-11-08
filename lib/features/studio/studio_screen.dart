import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'models/chest.dart';
import 'services/chest_storage_service.dart';
import '../profile/models/inventory_item.dart';
import '../profile/models/user_profile.dart';
import '../profile/utils/item_icons.dart';
import '../../core/theme/app_theme.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _moneyAmountController = TextEditingController();
  
  Map<ItemType, int> _selectedItems = {}; // Map of item type to quantity
  int _selectedLevel = 1;
  ChestContentType _contentType = ChestContentType.media;
  XFile? _selectedMedia;
  bool _isImage = true;
  
  // Categories for organizing items
  Map<String, List<ItemType>> get _itemCategories => {
    'Common': [ItemType.key, ItemType.gem, ItemType.coin],
    'Warrior': [ItemType.sword, ItemType.armor],
    'Mage': [ItemType.staff, ItemType.spellbook],
    'Rogue': [ItemType.dagger, ItemType.lockpick],
    'Ranger': [ItemType.bow, ItemType.quiver],
    'Paladin': [ItemType.holySymbol, ItemType.shield],
    'Druid': [ItemType.totem, ItemType.herbs],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _moneyAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    
    // Show dialog to choose image or video
    final mediaType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Select Media Type',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white),
              title: const Text('Image', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.white),
              title: const Text('Video', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );

    if (mediaType == null) return;

    try {
      XFile? media;
      if (mediaType == 'image') {
        media = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
      } else {
        media = await picker.pickVideo(
          source: ImageSource.gallery,
        );
      }
      
      if (media != null) {
        setState(() {
          _selectedMedia = media;
          _isImage = mediaType == 'image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking media: $e')),
        );
      }
    }
  }

  Future<void> _handleStripePayment() async {
    // For now, we'll just validate the amount and show a placeholder
    // In a real app, you would integrate with Stripe Payment Sheet here
    final amount = double.tryParse(_moneyAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Placeholder for Stripe integration
    // In production, you would:
    // 1. Create a payment intent on your backend
    // 2. Initialize Stripe Payment Sheet
    // 3. Present the payment sheet
    // 4. Handle the payment result
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Stripe Integration',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Stripe payment integration would be implemented here.\n\n'
          'Amount: \$${amount.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // In production, proceed with Stripe payment
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Future<void> _createChest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Filter out items with 0 quantity
    final validItems = Map<ItemType, int>.fromEntries(
      _selectedItems.entries.where((e) => e.value > 0),
    );
    
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one required item with quantity > 0')),
      );
      return;
    }

    if (_contentType == ChestContentType.media && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or video')),
      );
      return;
    }

    if (_contentType == ChestContentType.money) {
      final amount = double.tryParse(_moneyAmountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid money amount')),
        );
        return;
      }
    }

    try {
      final userProfile = UserProfile.getFakeProfile();
      final chest = Chest(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        creatorUsername: userProfile.username,
        creatorProfilePicture: userProfile.profilePicturePath,
        requiredItems: validItems,
        requiredLevel: _selectedLevel,
        contentType: _contentType,
        mediaPath: _selectedMedia?.path,
        moneyAmount: _contentType == ChestContentType.money
            ? double.parse(_moneyAmountController.text)
            : null,
        createdAt: DateTime.now(),
      );

      await ChestStorageService.saveChest(chest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chest created successfully!')),
        );
        
        // Reset form
        _nameController.clear();
        _moneyAmountController.clear();
        setState(() {
          _selectedItems = {};
          _selectedLevel = 1;
          _contentType = ChestContentType.media;
          _selectedMedia = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chest: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Custom Chest',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Chest Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Chest Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.gemGreen),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a chest name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Required Items
                const Text(
                  'Required Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _itemCategories.entries.map((entry) {
                      return _buildItemCategory(entry.key, entry.value);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Required Level
                const Text(
                  'Required Level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _selectedLevel.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: 'Level $_selectedLevel',
                          onChanged: (value) {
                            setState(() {
                              _selectedLevel = value.toInt();
                            });
                          },
                        ),
                      ),
                      Image.asset(
                        'assets/chests/level-$_selectedLevel.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppTheme.gemGreen.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$_selectedLevel',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Content Type
                const Text(
                  'Content Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildContentTypeOption(
                        ChestContentType.media,
                        'Media',
                        Icons.image,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContentTypeOption(
                        ChestContentType.money,
                        'Money',
                        Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Media Upload or Money Input
                if (_contentType == ChestContentType.media) ...[
                  InkWell(
                    onTap: _pickMedia,
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: _selectedMedia != null
                              ? AppTheme.gemGreen
                              : Colors.white24,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedMedia != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _isImage
                                  ? Image.file(
                                      File(_selectedMedia!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.video_library,
                                        size: 80,
                                        color: Colors.white70,
                                      ),
                                    ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 64, color: Colors.white70),
                                SizedBox(height: 12),
                                Text(
                                  'Tap to select image or video',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _moneyAmountController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (\$)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleStripePayment,
                      icon: const Icon(Icons.payment),
                      label: const Text('Configure Stripe Payment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.gemGreen),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createChest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gemGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Chest',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeOption(
    ChestContentType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _contentType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _contentType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.gemGreen.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? AppTheme.gemGreen : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.gemGreen : Colors.white70, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCategory(String categoryName, List<ItemType> items) {
    final hasSelectedItems = items.any((item) => 
      _selectedItems.containsKey(item) && _selectedItems[item]! > 0);
    
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        initiallyExpanded: hasSelectedItems,
        title: Row(
          children: [
            Text(
              categoryName,
              style: TextStyle(
                color: hasSelectedItems ? AppTheme.gemGreen : Colors.white,
                fontWeight: hasSelectedItems ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            if (hasSelectedItems) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.gemGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  items.where((item) => 
                    _selectedItems.containsKey(item) && _selectedItems[item]! > 0
                  ).length.toString(),
                  style: const TextStyle(
                    color: AppTheme.gemGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          hasSelectedItems ? Icons.expand_less : Icons.expand_more,
          color: Colors.white70,
        ),
        children: items.map((item) => _buildItemRow(item)).toList(),
      ),
    );
  }

  Widget _buildItemRow(ItemType item) {
    final quantity = _selectedItems[item] ?? 0;
    const maxQuantity = 99;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ItemIcons.getIcon(item, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: quantity > 0 ? Colors.white : Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: quantity > 0 ? Colors.white : Colors.white54,
                  onPressed: quantity > 0
                      ? () {
                          setState(() {
                            final newQuantity = quantity - 1;
                            if (newQuantity == 0) {
                              _selectedItems.remove(item);
                            } else {
                              _selectedItems[item] = newQuantity;
                            }
                          });
                        }
                      : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    quantity.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: quantity > 0 ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: quantity < maxQuantity ? Colors.white : Colors.white54,
                  onPressed: quantity < maxQuantity
                      ? () {
                          setState(() {
                            _selectedItems[item] = quantity + 1;
                          });
                        }
                      : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
