import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/skill_entry.dart';
import '../models/skill_category.dart';
import '../utils/string_normalizer.dart';

class SkillService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Collection to store all available skills globally
  static const String _skillsCollection = 'available_skills';
  
  // Default predefined skills organized by category
  static final Map<SkillCategory, List<String>> _defaultSkills = {
    SkillCategory.technology: [
      'Python',
      'Java',
      'C++',
      'Web Development',
      'UI/UX',
      'Flutter',
      'Data Analysis',
      'React',
      'Angular',
      'Node.js',
      'Machine Learning',
      'Mobile Development',
    ],
    SkillCategory.arts: [
      'Photography',
      'Painting',
      'Drawing',
      'Editing',
      'Graphic Design',
      'Digital Art',
      'Sculpture',
    ],
    SkillCategory.music: [
      'Music',
      'Guitar',
      'Piano',
      'Singing',
      'Drums',
      'Music Production',
    ],
    SkillCategory.cooking: [
      'Cooking',
      'Baking',
      'Grilling',
      'Meal Prep',
    ],
    SkillCategory.languages: [
      'English',
      'Spanish',
      'French',
      'German',
      'Mandarin',
      'Japanese',
      'Arabic',
    ],
    SkillCategory.sports: [
      'Basketball',
      'Soccer',
      'Tennis',
      'Swimming',
      'Running',
      'Yoga',
      'Fitness',
    ],
    SkillCategory.business: [
      'Public Speaking',
      'Marketing',
      'Leadership',
      'Project Management',
      'Networking',
    ],
    SkillCategory.other: [
      'Other',
    ],
  };

  /// Initialize default skills in Firebase if not already present
  Future<void> initializeDefaultSkills() async {
    for (final category in SkillCategory.values) {
      final categoryDoc = _db.collection(_skillsCollection).doc(category.name);
      final docSnapshot = await categoryDoc.get();
      
      if (!docSnapshot.exists) {
        final skills = _defaultSkills[category] ?? [];
        final normalizedSkills = skills.map((s) => StringNormalizer.normalize(s)).toList();
        
        await categoryDoc.set({
          'skills': normalizedSkills,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Get all available skills for a specific category
  Future<List<String>> getSkillsForCategory(SkillCategory category) async {
    try {
      final doc = await _db.collection(_skillsCollection).doc(category.name).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['skills'] != null) {
          return List<String>.from(data['skills']);
        }
      }
      
      // Return default skills if not found in Firebase
      return (_defaultSkills[category] ?? [])
          .map((s) => StringNormalizer.normalize(s))
          .toList();
    } catch (e) {
      print('Error fetching skills for category ${category.name}: $e');
      return (_defaultSkills[category] ?? [])
          .map((s) => StringNormalizer.normalize(s))
          .toList();
    }
  }

  /// Add a new skill to a category (will be available for all users)
  Future<void> addSkillToCategory(SkillCategory category, String skillTag) async {
    final normalized = StringNormalizer.normalize(skillTag);
    
    if (normalized.isEmpty) return;
    
    final categoryDoc = _db.collection(_skillsCollection).doc(category.name);
    
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(categoryDoc);
        
        List<String> currentSkills = [];
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data['skills'] != null) {
            currentSkills = List<String>.from(data['skills']);
          }
        }
        
        // Only add if not already present
        if (!currentSkills.contains(normalized)) {
          currentSkills.add(normalized);
          transaction.set(categoryDoc, {
            'skills': currentSkills,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
    } catch (e) {
      print('Error adding skill to category: $e');
      rethrow;
    }
  }

  /// Get all skills across all categories (for migration or comprehensive search)
  Future<Map<SkillCategory, List<String>>> getAllSkills() async {
    final Map<SkillCategory, List<String>> allSkills = {};
    
    for (final category in SkillCategory.values) {
      allSkills[category] = await getSkillsForCategory(category);
    }
    
    return allSkills;
  }

  /// Search for skills across all categories matching a query
  Future<List<SkillEntry>> searchSkills(String query) async {
    final normalized = StringNormalizer.normalize(query);
    final results = <SkillEntry>[];
    
    if (normalized.isEmpty) return results;
    
    final allSkills = await getAllSkills();
    
    for (final entry in allSkills.entries) {
      final category = entry.key;
      final skills = entry.value;
      
      for (final skill in skills) {
        if (skill.contains(normalized)) {
          results.add(SkillEntry(category: category, tag: skill));
        }
      }
    }
    
    return results;
  }
}
