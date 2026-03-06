class IngredientMapper {
  // Returns one of your 15 class names, or null if not recognized
  static String? mapVisionLabelToClass(String label) {
    final s = label.toLowerCase().trim();

    // Brinjal
    if (s.contains('eggplant') || s.contains('aubergine') || s.contains('brinjal')) return 'Brinjal';

    // Capsicum
    if (s.contains('bell pepper') || s.contains('capsicum') || s.contains('pepper')) return 'Capsicum';

    // Cabbage / Broccoli / Cauliflower
    if (s.contains('broccoli')) return 'Broccoli';
    if (s.contains('cauliflower')) return 'Cauliflower';
    if (s.contains('cabbage')) return 'Cabbage';

    // Roots
    if (s.contains('carrot')) return 'Carrot';
    if (s.contains('radish') || s.contains('daikon')) return 'Radish';
    if (s.contains('potato')) return 'Potato';

    // Gourds
    if (s.contains('bitter gourd') || s.contains('bitter melon')) return 'Bitter_Gourd';
    if (s.contains('bottle gourd') || s.contains('calabash') || s.contains('lauki')) return 'Bottle_Gourd';
    if (s.contains('pumpkin')) return 'Pumpkin';

    // Others
    if (s.contains('cucumber')) return 'Cucumber';
    if (s.contains('papaya')) return 'Papaya';
    if (s.contains('tomato')) return 'Tomato';
    if (s == 'bean' || s.contains('green bean') || s.contains('string bean')) return 'Bean';

    return null;
  }

  static List<String> mapMany(List<String> labels) {
    final out = <String>{};
    for (final l in labels) {
      final mapped = mapVisionLabelToClass(l);
      if (mapped != null) out.add(mapped);
    }
    return out.toList();
  }
}