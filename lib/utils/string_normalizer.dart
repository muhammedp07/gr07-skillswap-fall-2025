class StringNormalizer {
  /// Normalize string for database storage and search
  /// Returns lowercase, trimmed string
  static String normalize(String input) {
    return input.trim().toLowerCase();
  }

  /// Capitalize first letter for UI display
  static String capitalize(String input) {
    if (input.isEmpty) return input;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  /// Capitalize each word (for multi-word skills like "Web Development")
  static String capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input
        .trim()
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
