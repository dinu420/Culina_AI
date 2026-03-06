import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lottie/lottie.dart';

import 'services/recipe_service.dart';
import 'services/vision_service.dart';

class CulinaHomePage extends StatefulWidget {
  const CulinaHomePage({super.key});

  @override
  State<CulinaHomePage> createState() => _CulinaHomePageState();
}

class _CulinaHomePageState extends State<CulinaHomePage> {
  final List<Uint8List> _images = [];
  final Set<String> _detectedPool = {};
  final List<String> _fallbackSuggestions = [
    "Broccoli",
    "Capsicum",
    "Brinjal",
    "Garlic",
    "Onion"
  ];
  List<String> _suggestions = [];
  final List<String> _confirmed = [];
  final _prefController =
      TextEditingController(text: "Sri Lankan, spicy, quick");
  final ImagePicker _picker = ImagePicker();

  bool _isDetecting = false;
  bool _isGenerating = false;
  int _attempt = 0;
  String? _lastRecipe;

  @override
  void initState() {
    super.initState();
    _suggestions = List<String>.from(_fallbackSuggestions);

    // Optional: warm-up Lottie (safe to keep).
    try {
      AssetLottie('assets/animations/cooking.json').load();
    } catch (_) {}
  }

  @override
  void dispose() {
    _prefController.dispose();
    super.dispose();
  }

  void _addIngredient(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty || _confirmed.contains(cleaned)) return;
    setState(() => _confirmed.add(cleaned));
  }

  void _removeIngredient(String name) {
    setState(() => _confirmed.remove(name));
  }

  void _clearSession() {
    setState(() {
      _images.clear();
      _detectedPool.clear();
      _confirmed.clear();
      _suggestions = List<String>.from(_fallbackSuggestions);
      _isDetecting = false;
      _isGenerating = false;
      _attempt = 0;
      _lastRecipe = null;
    });
  }

  void _mergeDetected(List<String> newItems) {
    for (final item in newItems) {
      final v = item.trim();
      if (v.isEmpty) continue;
      _detectedPool.add(v);
    }
    setState(() {
      _suggestions = _detectedPool.isEmpty
          ? List<String>.from(_fallbackSuggestions)
          : _detectedPool.toList();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _images.add(bytes);
        _isDetecting = true;
        if (_detectedPool.isEmpty) _suggestions = [];
      });
      await _runVisionDetection(bytes);
    } catch (e) {
      setState(() => _isDetecting = false);
    }
  }

  Future<void> _runVisionDetection(Uint8List bytes) async {
    try {
      final labels = await VisionService.detect(bytes);
      final cleaned = labels
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(12)
          .toList();
      _mergeDetected(cleaned);
      setState(() => _isDetecting = false);
    } catch (e) {
      setState(() => _isDetecting = false);
    }
  }

  Future<void> _generateRecipe(
      {bool regenerate = false, String? modification}) async {
    if (_confirmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add ingredients first.")),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      _attempt = regenerate ? _attempt + 1 : 1;

      final recipe = await RecipeService.generate(
        _confirmed,
        _prefController.text,
        attempt: _attempt,
        avoidRecipe: _lastRecipe,
        modification: modification,
      );

      _lastRecipe = recipe;
      setState(() => _isGenerating = false);

      _showRecipeSheet(context, recipe);
    } catch (e) {
      setState(() => _isGenerating = false);
    }
  }

  void _showRecipeSheet(BuildContext pageContext, String recipe) {
  final recipeNotifier = ValueNotifier<String>(recipe);
  final loadingNotifier = ValueNotifier<bool>(false);

  showModalBottomSheet(
    context: pageContext,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Chef's Selection",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),

                /// BODY
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: loadingNotifier,
                    builder: (_, loading, __) {
                      if (loading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animations/cooking.json',
                                width: 200,
                                repeat: true,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "AI is cooking your new recipe...",
                                style: TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        );
                      }

                      return ValueListenableBuilder<String>(
                        valueListenable: recipeNotifier,
                        builder: (_, recipe, __) {
                          return SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              recipe,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.8,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                /// ACTIONS
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(LucideIcons.wand2),
                          label: const Text("Refine"),
                          onPressed: () async {
                            debugPrint("REFINE pressed");

                            final controller = TextEditingController();

                            final result = await showDialog<String>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Modify recipe"),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    hintText: "Less spicy, more protein...",
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(
                                        context,
                                        controller.text.trim()),
                                    child: const Text("Apply"),
                                  ),
                                ],
                              ),
                            );

                            if (result == null) return;

                            /// SHOW LOTTIE
                            loadingNotifier.value = true;

                            try {
                              _attempt++;

                              final newRecipe =
                                  await RecipeService.generate(
                                _confirmed,
                                _prefController.text,
                                attempt: _attempt,
                                avoidRecipe: recipeNotifier.value,
                                modification:
                                    result.isEmpty ? null : result,
                              );

                              debugPrint("REFINE success");

                              /// UPDATE UI
                              recipeNotifier.value = newRecipe;

                            } catch (e) {
                              debugPrint("REFINE failed: $e");
                            }

                            /// HIDE LOTTIE
                            loadingNotifier.value = false;
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(LucideIcons.copy),
                          label: const Text("Copy"),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                  text: recipeNotifier.value),
                            );

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text("Copied"),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text(
                "Culina AI",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent.withOpacity(0.2), Colors.transparent],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.rotateCcw, size: 20),
                onPressed: _clearSession,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(accent),
                  const SizedBox(height: 32),

                  _buildSectionHeader(
                      "Suggestions", _isDetecting ? "Scanning..." : null),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _suggestions.map((s) => _buildActionChip(s, accent)).toList(),
                  ),

                  const SizedBox(height: 32),

                  _buildSectionHeader("Pantry", "${_confirmed.length} items"),
                  const SizedBox(height: 12),
                  _confirmed.isEmpty
                      ? _buildEmptyState()
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _confirmed
                              .map((c) => _buildConfirmedChip(c, accent))
                              .toList(),
                        ),

                  const SizedBox(height: 32),

                  _buildSectionHeader("Cooking Style", null),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _prefController,
                    decoration: InputDecoration(
                      hintText: "Quick, Spicy, Vegan...",
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          Icon(LucideIcons.settings2, size: 18, color: accent),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: (_isGenerating || _isDetecting)
                          ? null
                          : () => _generateRecipe(),
                      child: _isGenerating
                          ? Lottie.asset(
                              'assets/animations/cooking.json',
                              height: 40,
                              repeat: true,
                              animate: true,
                              errorBuilder: (context, error, stack) {
                                debugPrint("Button Lottie error: $error");
                                return const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                            )
                          : const Text(
                              "GENERATE MAGIC",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE MODERN COMPONENTS ---

  Widget _buildImageSection(Color accent) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF161B22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            if (_images.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.camera,
                        size: 40, color: accent.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      "Upload Ingredients",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              )
            else
              Image.memory(
                _images.last,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: _buildGlassButton(
                      "Camera",
                      LucideIcons.aperture,
                      () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildGlassButton(
                      "Gallery",
                      LucideIcons.image,
                      () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildActionChip(String label, Color accent) {
    return GestureDetector(
      onTap: () => _addIngredient(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedChip(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeIngredient(label),
            child: const Icon(Icons.close, size: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Text(
      "Your pantry is empty. Tap suggestions above.",
      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
    );
  }
}