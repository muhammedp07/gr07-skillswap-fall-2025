enum SkillCategory {
  technology,
  arts,
  languages,
  sports,
  music,
  cooking,
  business,
  other;

  String get displayName {
    switch (this) {
      case SkillCategory.technology:
        return 'Technology';
      case SkillCategory.arts:
        return 'Arts';
      case SkillCategory.languages:
        return 'Languages';
      case SkillCategory.sports:
        return 'Sports';
      case SkillCategory.music:
        return 'Music';
      case SkillCategory.cooking:
        return 'Cooking';
      case SkillCategory.business:
        return 'Business';
      case SkillCategory.other:
        return 'Other';
    }
  }

  static SkillCategory fromString(String value) {
    return SkillCategory.values.firstWhere(
      (category) => category.name == value.toLowerCase(),
      orElse: () => SkillCategory.other,
    );
  }
}
