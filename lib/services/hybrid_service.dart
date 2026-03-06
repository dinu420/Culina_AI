import 'dart:typed_data';
import '../utils/ingredient_mapper.dart';
import 'tflite_service.dart';

abstract class TflitePredictor {
  Future<List<Pred>> predictTop3(Uint8List imageBytes); // returns sorted top-3
}

abstract class VisionLabeler {
  Future<List<String>> getLabels(Uint8List imageBytes); 
}

class HybridService {
  final TflitePredictor tflite;
  final VisionLabeler vision;

  HybridService({required this.tflite, required this.vision});

  bool _shouldCallVision(List<Pred> top3) {
    final top1 = top3[0].conf;
    final top2 = top3.length > 1 ? top3[1].conf : 0.0;

    
    if (top1 < 0.80) return true;              // low confidence
    if ((top1 - top2) < 0.15) return true;     // low margin
    if (top2 > 0.20) return true;              // split probability
    return false;
  }

  Future<List<String>> getSuggestions(Uint8List imageBytes) async {
    final top3 = await tflite.predictTop3(imageBytes);

    final suggestions = <String>{...top3.map((p) => p.label)};

    if (_shouldCallVision(top3)) {
      final visionLabels = await vision.getLabels(imageBytes);
      final mapped = IngredientMapper.mapMany(visionLabels);
      suggestions.addAll(mapped);
    }

    // Keep stable ordering: model top-3 first, then extras
    final ordered = <String>[];
    for (final p in top3) {
      if (suggestions.contains(p.label)) ordered.add(p.label);
    }
    for (final s in suggestions) {
      if (!ordered.contains(s)) ordered.add(s);
    }
    return ordered;
  }
}