import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../config/color_palette.dart';
import '../../../models/menu_item.dart';
import '../../../models/category.dart';
import '../../../services/menu_service.dart';

/// Modal for adding/editing menu items
class ItemFormModal extends ConsumerStatefulWidget {
  final MenuItem? item; // null = create new, non-null = edit existing
  final List<Category> categories;

  const ItemFormModal({
    super.key,
    this.item,
    required this.categories,
  });

  @override
  ConsumerState<ItemFormModal> createState() => _ItemFormModalState();
}

class _ItemFormModalState extends ConsumerState<ItemFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedCategoryId;
  String? _imagePath;
  bool _isAvailable = true;
  bool _isSaving = false;
  
  // Modifiers/Variants for the item
  List<ItemModifier> _modifiers = [];
  bool _isLoadingModifiers = false;
  List<Category> _localCategories = [];

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toStringAsFixed(2);
      _descController.text = widget.item!.description ?? '';
      _selectedCategoryId = widget.item!.categoryId;
      _imagePath = widget.item!.imageUrl;
      _isAvailable = widget.item!.isAvailable;
      _loadModifiers();
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
    _localCategories = List.from(widget.categories);
  }

  Future<void> _loadModifiers() async {
    if (widget.item == null) return;
    setState(() => _isLoadingModifiers = true);
    try {
      final modifiers = await ref.read(menuServiceProvider).getModifiersForItem(widget.item!.id);
      setState(() {
        _modifiers = modifiers;
        _isLoadingModifiers = false;
      });
    } catch (e) {
      setState(() => _isLoadingModifiers = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
        backgroundColor: CarmenColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo picker
            _buildPhotoPicker(),
            const SizedBox(height: 20),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              validator: (v) => v?.isEmpty == true ? 'Name required' : null,
            ),
            const SizedBox(height: 16),

            // Price field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Base Price (₱) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v?.isEmpty == true) return 'Price required';
                final price = double.tryParse(v!);
                if (price == null) return 'Invalid price';
                if (price > 1000000) return 'Max price is 1,000,000';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                ..._localCategories.map((cat) {
                  return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                }),
                const DropdownMenuItem(
                  value: '__add_new__',
                  child: Text(
                    '+ Add New Category',
                    style: TextStyle(
                      color: CarmenColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == '__add_new__') {
                  _showAddCategoryDialog();
                } else {
                  setState(() => _selectedCategoryId = val);
                }
              },
              validator: (v) => v == null ? 'Category required' : null,
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Availability toggle
            SwitchListTile(
              title: const Text('Available in POS'),
              subtitle: Text(_isAvailable ? 'Visible to cashier' : 'Hidden from POS'),
              value: _isAvailable,
              onChanged: (val) => setState(() => _isAvailable = val),
              activeColor: CarmenColors.primaryGreen,
            ),
            
            // Variants/Modifiers Section (only for editing existing items)
            if (isEditing) ...[
              const SizedBox(height: 24),
              _buildVariantsSection(),
            ],
            
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CarmenColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Add Item',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Variants / Modifiers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddModifierDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: CarmenColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set price adjustments for sizes, flavors, etc.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          
          if (_isLoadingModifiers)
            const Center(child: CircularProgressIndicator())
          else if (_modifiers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No variants added yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ..._modifiers.map((modifier) => _buildModifierCard(modifier)),
        ],
      ),
    );
  }

  Widget _buildModifierCard(ItemModifier modifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          modifier.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${modifier.options.length} options • ${modifier.isRequired ? "Required" : "Optional"}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditModifierDialog(modifier),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _confirmDeleteModifier(modifier),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: modifier.options.map((option) {
                final priceText = option.priceAdjustment == 0
                    ? 'Base price'
                    : option.priceAdjustment > 0
                        ? '+₱${option.priceAdjustment.toStringAsFixed(0)}'
                        : '-₱${option.priceAdjustment.abs().toStringAsFixed(0)}';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.name),
                  trailing: Text(
                    priceText,
                    style: TextStyle(
                      color: option.priceAdjustment > 0 ? Colors.green : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddModifierDialog() {
    _showModifierFormDialog(null);
  }

  void _showEditModifierDialog(ItemModifier modifier) {
    _showModifierFormDialog(modifier);
  }

  void _showModifierFormDialog(ItemModifier? existingModifier) {
    final nameController = TextEditingController(text: existingModifier?.name ?? '');
    bool isRequired = existingModifier?.isRequired ?? false;
    List<ModifierOption> options = existingModifier?.options.toList() ?? [];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(existingModifier == null ? 'Add Variant' : 'Edit Variant'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Variant Name (e.g., Size, Temperature)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Required'),
                      value: isRequired,
                      onChanged: (val) => setDialogState(() => isRequired = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              options.add(const ModifierOption(name: '', priceAdjustment: 0));
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Option'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final optionNameCtrl = TextEditingController(text: option.name);
                      final optionPriceCtrl = TextEditingController(
                        text: option.priceAdjustment.toStringAsFixed(0),
                      );
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: optionNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Option',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  options[index] = ModifierOption(
                                    name: val,
                                    priceAdjustment: options[index].priceAdjustment,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: optionPriceCtrl,
                                decoration: const InputDecoration(
                                  labelText: '+/- ₱',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                onChanged: (val) {
                                  final price = double.tryParse(val) ?? 0;
                                  options[index] = ModifierOption(
                                    name: options[index].name,
                                    priceAdjustment: price,
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                              onPressed: () {
                                setDialogState(() => options.removeAt(index));
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a variant name')),
                    );
                    return;
                  }
                  if (options.isEmpty || options.any((o) => o.name.trim().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add at least one option with a name')),
                    );
                    return;
                  }
                  
                  Navigator.pop(ctx);
                  
                  try {
                    final menuService = ref.read(menuServiceProvider);
                    
                    if (existingModifier == null) {
                      // Create new
                      final newModifier = ItemModifier(
                        id: const Uuid().v4(),
                        menuItemId: widget.item!.id,
                        name: nameController.text.trim(),
                        type: 'single_select',
                        options: options.where((o) => o.name.trim().isNotEmpty).toList(),
                        isRequired: isRequired,
                        createdAt: DateTime.now(),
                      );
                      await menuService.createModifier(newModifier);
                    } else {
                      // Update existing
                      final updatedModifier = ItemModifier(
                        id: existingModifier.id,
                        menuItemId: existingModifier.menuItemId,
                        name: nameController.text.trim(),
                        type: existingModifier.type,
                        options: options.where((o) => o.name.trim().isNotEmpty).toList(),
                        isRequired: isRequired,
                        createdAt: existingModifier.createdAt,
                      );
                      await menuService.updateModifier(updatedModifier);
                    }
                    
                    await _loadModifiers();
                    ref.read(menuProvider.notifier).loadMenu();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save variant: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CarmenColors.primaryGreen,
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteModifier(ItemModifier modifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Variant?'),
        content: Text('Are you sure you want to delete "${modifier.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(menuServiceProvider).deleteModifier(modifier.id);
                await _loadModifiers();
                ref.read(menuProvider.notifier).loadMenu();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imagePath!.startsWith('http')
                    ? Image.network(_imagePath!, fit: BoxFit.cover, width: double.infinity)
                    : Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Tap to add photo', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(source: source, maxWidth: 800);
      if (picked != null) {
        // Copy to app directory for persistence
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${const Uuid().v4()}${path.extension(picked.path)}';
        final savedPath = path.join(appDir.path, 'item_images', fileName);
        
        await Directory(path.dirname(savedPath)).create(recursive: true);
        await File(picked.path).copy(savedPath);
        
        setState(() => _imagePath = savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final menuService = ref.read(menuServiceProvider);

      if (isEditing) {
        // Update existing item
        final updated = widget.item!.copyWith(
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          categoryId: _selectedCategoryId!,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          imageUrl: _imagePath,
          isAvailable: _isAvailable,
          updatedAt: now,
        );
        // Build changes description for logging
        final changes = <String>[];
        if (widget.item!.name != updated.name) changes.add('name');
        if (widget.item!.price != updated.price) changes.add('price');
        if (widget.item!.imageUrl != updated.imageUrl) changes.add('photo');
        if (widget.item!.isAvailable != updated.isAvailable) changes.add('availability');
        await menuService.updateItem(updated, changes: changes.isEmpty ? 'Updated' : changes.join(', '));
      } else {
        // Create new item
        final categoryName = widget.categories.firstWhere((c) => c.id == _selectedCategoryId).name;
        final newItem = MenuItem(
          id: const Uuid().v4(),
          categoryId: _selectedCategoryId!,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          imageUrl: _imagePath,
          isAvailable: _isAvailable,
          createdAt: now,
          updatedAt: now,
        );
        await menuService.createItem(newItem, categoryName: categoryName);
      }

      // Refresh menu and close
      ref.read(menuProvider.notifier).loadMenu();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${widget.item!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteItem();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(menuServiceProvider).deleteItem(widget.item!.id, itemName: widget.item!.name);
      ref.read(menuProvider.notifier).loadMenu();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await _createCategory(name);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: CarmenColors.primaryGreen),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createCategory(String name) async {
    try {
      final now = DateTime.now();
      final newCategory = Category(
        id: const Uuid().v4(),
        name: name,
        sortOrder: _localCategories.length,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(menuServiceProvider).createCategory(newCategory);
      
      setState(() {
        _localCategories.add(newCategory);
        _selectedCategoryId = newCategory.id;
      });
      
      // Refresh global menu to sync
      ref.read(menuProvider.notifier).loadMenu();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create category: $e')),
        );
      }
    }
  }
}
