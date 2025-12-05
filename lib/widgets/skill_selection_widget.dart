// skill_selection_widget.dart - Updated for light theme
import 'package:flutter/material.dart';
import '../models/skill_category.dart';
import '../models/skill_entry.dart';
import '../services/skill_service.dart';
import '../utils/string_normalizer.dart';

class SkillSelectionWidget extends StatefulWidget {
  final List<SkillEntry> selectedSkills;
  final Function(List<SkillEntry>) onSkillsChanged;
  final String title;
  final Color chipColor;
  final List<SkillEntry>? excludedSkills;

  const SkillSelectionWidget({
    super.key,
    required this.selectedSkills,
    required this.onSkillsChanged,
    required this.title,
    required this.chipColor,
    this.excludedSkills,
  });

  @override
  State<SkillSelectionWidget> createState() => _SkillSelectionWidgetState();
}

class _SkillSelectionWidgetState extends State<SkillSelectionWidget> {
  final SkillService _skillService = SkillService();
  final TextEditingController _tagController = TextEditingController();
  
  SkillCategory? _selectedCategory;
  List<String> _availableTagsForCategory = [];
  List<String> _filteredTags = [];
  bool _isLoadingTags = false;

  @override
  void initState() {
    super.initState();
    _tagController.addListener(_onTagSearchChanged);
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _onTagSearchChanged() {
    if (_selectedCategory == null) return;
    
    final query = StringNormalizer.normalize(_tagController.text);
    setState(() {
      if (query.isEmpty) {
        _filteredTags = _availableTagsForCategory;
      } else {
        _filteredTags = _availableTagsForCategory
            .where((tag) => tag.contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadTagsForCategory(SkillCategory category) async {
    setState(() {
      _isLoadingTags = true;
    });

    try {
      final tags = await _skillService.getSkillsForCategory(category);
      setState(() {
        _availableTagsForCategory = tags;
        _filteredTags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  void _onCategorySelected(SkillCategory? category) {
    if (category == null) return;
    
    setState(() {
      _selectedCategory = category;
      _tagController.clear();
    });
    
    _loadTagsForCategory(category);
  }

  Future<void> _addSkill(String tag) async {
    if (_selectedCategory == null || tag.trim().isEmpty) return;

    final normalizedTag = StringNormalizer.normalize(tag);
    final newSkill = SkillEntry(category: _selectedCategory!, tag: normalizedTag);

    if (widget.selectedSkills.contains(newSkill)) {
      _showMessage('This skill is already selected');
      return;
    }

    if (widget.excludedSkills != null && widget.excludedSkills!.contains(newSkill)) {
      _showMessage('This skill is already in the other list');
      return;
    }

    if (!_availableTagsForCategory.contains(normalizedTag)) {
      try {
        await _skillService.addSkillToCategory(_selectedCategory!, normalizedTag);
        setState(() {
          _availableTagsForCategory.add(normalizedTag);
          _filteredTags = _availableTagsForCategory;
        });
      } catch (e) {
        _showMessage('Failed to add skill to database');
        return;
      }
    }

    final updatedSkills = [...widget.selectedSkills, newSkill];
    widget.onSkillsChanged(updatedSkills);

    setState(() {
      _selectedCategory = null;
      _tagController.clear();
      _availableTagsForCategory = [];
      _filteredTags = [];
    });
  }

  void _removeSkill(SkillEntry skill) {
    final updatedSkills = widget.selectedSkills.where((s) => s != skill).toList();
    widget.onSkillsChanged(updatedSkills);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Display selected skills as chips
        if (widget.selectedSkills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedSkills.map((skill) {
              // Determine text color based on chip color brightness
              final chipBrightness = ThemeData.estimateBrightnessForColor(widget.chipColor);
              final textColor = chipBrightness == Brightness.dark ? Colors.white : Colors.black;
              
              return Chip(
                label: Text(
                  skill.displaySkill,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: widget.chipColor,
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: textColor,
                ),
                onDeleted: () => _removeSkill(skill),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Category Dropdown - Updated for light theme
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkTheme ? const Color(0xFF1A1D36) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkTheme ? Colors.white30 : theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: DropdownButton<SkillCategory>(
            value: _selectedCategory,
            hint: Text(
              'Select Category',
              style: TextStyle(
                color: isDarkTheme ? Colors.white54 : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            isExpanded: true,
            dropdownColor: isDarkTheme ? const Color(0xFF1A1D36) : theme.colorScheme.surface,
            style: TextStyle(
              color: theme.colorScheme.onBackground,
            ),
            underline: const SizedBox(),
            items: SkillCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category.displayName,
                  style: TextStyle(
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onCategorySelected,
          ),
        ),

        const SizedBox(height: 12),

        // Tag input with autocomplete
        if (_selectedCategory != null) ...[
          if (_isLoadingTags)
            Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          else ...[
            // Text field for tag input
            TextField(
              controller: _tagController,
              style: TextStyle(
                color: theme.colorScheme.onBackground,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkTheme ? const Color(0xFF1A1D36) : theme.colorScheme.surface,
                hintText: 'Type skill name...',
                hintStyle: TextStyle(
                  color: isDarkTheme ? Colors.white54 : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkTheme ? Colors.white30 : theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    if (_tagController.text.trim().isNotEmpty) {
                      _addSkill(_tagController.text.trim());
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addSkill(value.trim());
                }
              },
            ),

            const SizedBox(height: 8),

            // Autocomplete suggestions
            if (_filteredTags.isNotEmpty && _tagController.text.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDarkTheme ? const Color(0xFF1A1D36) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkTheme ? Colors.white30 : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredTags.length,
                  itemBuilder: (context, index) {
                    final tag = _filteredTags[index];
                    final displayTag = StringNormalizer.capitalize(tag);
                    
                    return ListTile(
                      title: Text(
                        displayTag,
                        style: TextStyle(
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      onTap: () => _addSkill(tag),
                    );
                  },
                ),
              ),
            ],
          ],
        ],

        const SizedBox(height: 8),
        Text(
          _selectedCategory == null
              ? 'Select a category to add skills'
              : 'Type a skill name or select from suggestions',
          style: TextStyle(
            color: isDarkTheme ? Colors.white54 : theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}