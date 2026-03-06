import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Pred {
  final String label;
  final double conf;
  Pred(this.label, this.conf);
}

class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  Future<void> init({
    required String modelAssetPath,
    required String labelsAssetPath,
    int threads = 2,
  }) async {
    // Load labels.json (supports ["a","b"] OR {"labels":[...]})
    final labelsStr = await rootBundle.loadString(labelsAssetPath);
    final decoded = jsonDecode(labelsStr);

    if (decoded is List) {
      _labels = decoded.map((e) => e.toString()).toList();
    } else if (decoded is Map && decoded['labels'] is List) {
      _labels = (decoded['labels'] as List).map((e) => e.toString()).toList();
    } else {
      throw Exception("labels.json format not supported");
    }

    // Load model bytes
    final modelData = await rootBundle.load(modelAssetPath);
    final modelBytes = modelData.buffer.asUint8List(
      modelData.offsetInBytes,
      modelData.lengthInBytes,
    );

    final options = InterpreterOptions()..threads = threads;
    _interpreter = Interpreter.fromBuffer(modelBytes, options: options);

    
  }

  
  Future<List<Pred>> predictTop3(Uint8List imageBytes) async {
    if (!isReady) throw Exception("TfliteService not initialized");

    // Decode image
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception("Could not decode image");

    // Resize to 224x224
    const inputSize = 224;
    final resized = img.copyResize(decoded, width: inputSize, height: inputSize);

    // Build input tensor: [1,224,224,3] float32
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(inputSize, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        input[0][y][x][0] = p.r.toDouble(); // 0..255
        input[0][y][x][1] = p.g.toDouble();
        input[0][y][x][2] = p.b.toDouble();
      }
    }

    // Output: [1,15]
    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

    _interpreter!.run(input, output);

    final probs = output[0].cast<double>();

    // Top-3
    final indexed = List.generate(probs.length, (i) => MapEntry(i, probs[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));
    return indexed.take(3).map((e) => Pred(_labels[e.key], e.value)).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}