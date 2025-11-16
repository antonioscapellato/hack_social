import 'package:flutter/material.dart';
import '../../core/widgets/lucky_wrappers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'models/chest.dart';
import 'services/chest_storage_service.dart';
import 'services/chest_reward_service.dart';
import 'services/stripe_service.dart';
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
  bool _hasMedia = true; // Whether media is selected
  bool _hasMoney = false; // Whether money is selected
  List<XFile> _selectedMedia = []; // List of selected media files
  Map<String, bool> _mediaIsImage = {}; // Map of media path to isImage flag
  Map<String, String> _mediaDescriptions = {}; // Map of media path to description text
  
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
      
      final selectedMedia = media;
      if (selectedMedia != null) {
        setState(() {
          _selectedMedia.add(selectedMedia);
          _mediaIsImage[selectedMedia.path] = mediaType == 'image';
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

  void _removeMedia(int index) {
    setState(() {
      final removedMedia = _selectedMedia.removeAt(index);
      _mediaIsImage.remove(removedMedia.path);
      _mediaDescriptions.remove(removedMedia.path);
    });
  }

  void _editMediaDescription(int index) {
    final media = _selectedMedia[index];
    final currentDescription = _mediaDescriptions[media.path] ?? '';
    final controller = TextEditingController(text: currentDescription);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
        title: const Text(
          'Add Description',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLength: 200,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter a short description for this media...',
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.gemGreen),
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
          ),
        ),
        actions: [
          LuckyButtonWrapper(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
            variant: LuckyButtonVariant.outline,
          ),
          LuckyButtonWrapper(
            text: 'Save',
            onPressed: () {
              setState(() {
                final description = controller.text.trim();
                if (description.isEmpty) {
                  _mediaDescriptions.remove(media.path);
                } else {
                  _mediaDescriptions[media.path] = description;
                }
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleStripePayment() async {
    final amount = double.tryParse(_moneyAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create payment intent
      final paymentIntent = await StripeService.createPaymentIntent(
        amount: amount,
        currency: 'USD',
      );

      if (paymentIntent == null || !mounted) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create payment intent. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Present payment sheet
      final success = await StripeService.presentPaymentSheet(
        clientSecret: paymentIntent['clientSecret'] as String,
      );

      if (!mounted) return;

      if (success) {
        // Payment successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment successful! \$${amount.toStringAsFixed(2)} has been processed.',
            ),
            backgroundColor: AppTheme.gemGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Payment was canceled or failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was canceled.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    // Validate that at least one reward type is selected
    if (!_hasMedia && !_hasMoney) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one reward type (Media or Money)')),
      );
      return;
    }

    if (_hasMedia && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image or video')),
      );
      return;
    }

    if (_hasMoney) {
      final amount = double.tryParse(_moneyAmountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid money amount')),
        );
        return;
      }
    }

    // Determine contentType based on what's selected
    final ChestContentType contentType;
    if (_hasMedia && _hasMoney) {
      contentType = ChestContentType.both;
    } else if (_hasMedia) {
      contentType = ChestContentType.media;
    } else {
      contentType = ChestContentType.money;
    }

    try {
      final userProfile = UserProfile.getFakeProfile();
      // Generate rewards based on chest level
      final rewards = ChestRewardService.generateRewards(_selectedLevel);
      final chest = Chest(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        creatorUsername: userProfile.username,
        creatorProfilePicture: userProfile.profilePicturePath,
        requiredItems: validItems,
        requiredLevel: _selectedLevel,
        contentType: contentType,
        mediaPaths: _hasMedia && _selectedMedia.isNotEmpty
            ? _selectedMedia.map((m) => m.path).toList()
            : null,
        mediaDescriptions: _hasMedia && _mediaDescriptions.isNotEmpty
            ? Map<String, String>.from(_mediaDescriptions)
            : null,
        moneyAmount: _hasMoney
            ? double.parse(_moneyAmountController.text)
            : null,
        createdAt: DateTime.now(),
        rewards: rewards,
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
          _hasMedia = true;
          _hasMoney = false;
          _selectedMedia = [];
          _mediaIsImage = {};
          _mediaDescriptions = {};
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
                LuckyTextFieldWrapper(
                  controller: _nameController,
                  labelText: 'Chest Name',
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
                  'Rewards',
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
                      child: _buildContentTypeToggle(
                        'Media',
                        Icons.image,
                        _hasMedia,
                        (value) {
                          setState(() {
                            _hasMedia = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContentTypeToggle(
                        'Money',
                        Icons.attach_money,
                        _hasMoney,
                        (value) {
                          setState(() {
                            _hasMoney = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Media Upload - Show if media is selected
                if (_hasMedia) ...[
                  // Selected Media List
                  if (_selectedMedia.isNotEmpty) ...[
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedMedia.length,
                        itemBuilder: (context, index) {
                          final media = _selectedMedia[index];
                          final isImage = _mediaIsImage[media.path] ?? false;
                          final hasDescription = _mediaDescriptions.containsKey(media.path) && 
                                                 _mediaDescriptions[media.path]!.isNotEmpty;
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(
                                color: AppTheme.gemGreen,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(10),
                                        ),
                                        child: isImage
                                            ? Image.file(
                                                File(media.path),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              )
                                            : Container(
                                                color: Colors.black,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.video_library,
                                                    size: 60,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: InkWell(
                                          onTap: () => _removeMedia(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Description section
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        onTap: () => _editMediaDescription(index),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: hasDescription
                                                ? AppTheme.gemGreen.withOpacity(0.2)
                                                : Colors.white.withOpacity(0.05),
                                            border: Border.all(
                                              color: hasDescription
                                                  ? AppTheme.gemGreen
                                                  : Colors.white24,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                hasDescription
                                                    ? Icons.text_fields
                                                    : Icons.add_comment,
                                                size: 14,
                                                color: hasDescription
                                                    ? AppTheme.gemGreen
                                                    : Colors.white70,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  hasDescription
                                                      ? _mediaDescriptions[media.path]!
                                                      : 'Add description',
                                                  style: TextStyle(
                                                    color: hasDescription
                                                        ? Colors.white
                                                        : Colors.white54,
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Add Media Button
                  InkWell(
                    onTap: _pickMedia,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: Colors.white24,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 48, color: Colors.white70),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add image or video',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You can add multiple media files',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Money Input - Show if money is selected
                if (_hasMoney) ...[
                  if (_hasMedia) const SizedBox(height: 24),
                  LuckyTextFieldWrapper(
                    controller: _moneyAmountController,
                    labelText: 'Amount (\$)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.attach_money,
                    validator: (value) {
                      if (_hasMoney) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: LuckyButtonWrapper(
                      text: 'Configure Stripe Payment',
                      onPressed: _handleStripePayment,
                      icon: Icons.payment,
                      variant: LuckyButtonVariant.outline,
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: LuckyButtonWrapper(
                    text: 'Create Chest',
                    onPressed: _createChest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeToggle(
    String label,
    IconData icon,
    bool isSelected,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () {
        onChanged(!isSelected);
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
            const SizedBox(height: 4),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppTheme.gemGreen : Colors.white54,
              size: 20,
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
                LuckyIconButtonWrapper(
                  icon: Icons.remove,
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
                LuckyIconButtonWrapper(
                  icon: Icons.add,
                  onPressed: quantity < maxQuantity
                      ? () {
                          setState(() {
                            _selectedItems[item] = quantity + 1;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
