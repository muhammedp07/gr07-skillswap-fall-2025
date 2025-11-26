import 'skill_category.dart';
import '../utils/string_normalizer.dart';

class SkillEntry {
  final SkillCategory category;
  final String tag; // Normalized (lowercase, trimmed)
  
  SkillEntry({
    required this.category,
    required String tag,
  }) : tag = StringNormalizer.normalize(tag);

  // Display version with capitalized first letter
  String get displayTag => StringNormalizer.capitalize(tag);
  
  String get displaySkill => '${category.displayName} - $displayTag';
  
  // Normalized version for comparison
  String get normalizedSkill => tag;

  Map<String, dynamic> toMap() {
    return {
      'category': category.name,
      'tag': tag, // Store normalized version
    };
  }

  factory SkillEntry.fromMap(Map<String, dynamic> map) {
    // Handle null or missing fields gracefully
    final categoryStr = map['category'] as String?;
    final tagStr = map['tag'] as String?;
    
    if (categoryStr == null || tagStr == null) {
      // If data is incomplete, treat as legacy string format
      final fallbackTag = tagStr ?? map.toString();
      return SkillEntry.fromLegacyString(fallbackTag);
    }
    
    return SkillEntry(
      category: SkillCategory.fromString(categoryStr),
      tag: tagStr,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillEntry &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          tag == other.tag;

  @override
  int get hashCode => category.hashCode ^ tag.hashCode;

  @override
  String toString() => displaySkill;

  // Helper to create from legacy string format (for migration)
  factory SkillEntry.fromLegacyString(String skill) {
    final normalized = StringNormalizer.normalize(skill);
    
    // Map common legacy skills to categories
    final techSkills = ['python', 'java', 'c++', 'web development', 'ui/ux', 'flutter', 'data analysis'];
    final artSkills = ['photography', 'painting', 'editing'];
    final musicSkills = ['music'];
    final cookingSkills = ['cooking'];
    final businessSkills = ['public speaking'];
    
    SkillCategory category;
    if (techSkills.contains(normalized)) {
      category = SkillCategory.technology;
    } else if (artSkills.contains(normalized)) {
      category = SkillCategory.arts;
    } else if (musicSkills.contains(normalized)) {
      category = SkillCategory.music;
    } else if (cookingSkills.contains(normalized)) {
      category = SkillCategory.cooking;
    } else if (businessSkills.contains(normalized)) {
      category = SkillCategory.business;
    } else {
      category = SkillCategory.other;
    }
    
    return SkillEntry(category: category, tag: skill);
  }
}
