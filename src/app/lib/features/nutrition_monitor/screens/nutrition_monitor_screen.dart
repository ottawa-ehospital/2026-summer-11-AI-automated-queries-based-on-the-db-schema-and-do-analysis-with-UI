import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_card.dart';
import '../../../ui/ui.dart';
import '../data/nutrition_monitor_repository.dart';
import '../models/nutrition_monitor_models.dart';

class NutritionMonitorScreen extends StatefulWidget {
  const NutritionMonitorScreen({
    super.key,
    NutritionMonitorRepository? repository,
    ImagePicker? imagePicker,
  }) : _repository = repository,
       _imagePicker = imagePicker;

  final NutritionMonitorRepository? _repository;
  final ImagePicker? _imagePicker;

  @override
  State<NutritionMonitorScreen> createState() => _NutritionMonitorScreenState();
}

class _NutritionMonitorScreenState extends State<NutritionMonitorScreen> {
  late final NutritionMonitorRepository _repository;
  late final bool _ownsRepository;
  late final ImagePicker _imagePicker;
  final _hintController = TextEditingController();
  PickedMealImage? _pickedImage;
  NutritionAnalysisResult? _analysis;
  NutritionModelCapabilities? _capabilities;
  DailySummary? _summary;
  NutritionGoals _goals = NutritionGoals.defaults();
  List<MealLogRecord> _history = [];
  int? _patientId;
  bool _loading = true;
  bool _analyzing = false;
  bool _logging = false;
  String? _status;
  String? _error;

  bool get _canAnalyze =>
      !_analyzing &&
      _patientId != null &&
      _pickedImage != null &&
      (_capabilities?.supportsImageInput ?? false);

  @override
  void initState() {
    super.initState();
    _repository = widget._repository ?? NutritionMonitorRepository();
    _ownsRepository = widget._repository == null;
    _imagePicker = widget._imagePicker ?? ImagePicker();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final patientId = int.tryParse(prefs.get('patient_id')?.toString() ?? '');
    NutritionHealth? health;
    DailySummary? summary;
    List<MealLogRecord> history = [];
    NutritionGoals goals = NutritionGoals.defaults();
    String? error;
    try {
      health = await _repository.fetchHealth();
      if (patientId != null) {
        summary = await _repository.fetchDailySummary(patientId);
        history = await _repository.fetchMealHistory(patientId);
        goals = await _loadGoals(patientId);
      }
    } catch (err) {
      error = err.toString();
    }
    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _capabilities = health?.imageAnalysis;
      _summary =
          summary ?? (patientId == null ? null : DailySummary.empty(patientId));
      _history = history;
      _goals = goals;
      _loading = false;
      _error = error;
    });
  }

  Future<NutritionGoals> _loadGoals(int patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _goalKey(patientId);
    final local = prefs.getStringList(key);
    if (local != null && local.length == 4) {
      return NutritionGoals(
        calories: int.tryParse(local[0]) ?? 2000,
        protein: int.tryParse(local[1]) ?? 120,
        carbs: int.tryParse(local[2]) ?? 250,
        fat: int.tryParse(local[3]) ?? 70,
      );
    }
    try {
      return await _repository.fetchGoals(patientId);
    } catch (_) {
      return NutritionGoals.defaults();
    }
  }

  Future<void> _saveGoals(NutritionGoals goals) async {
    final patientId = _patientId;
    if (patientId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_goalKey(patientId), [
      goals.calories.toString(),
      goals.protein.toString(),
      goals.carbs.toString(),
      goals.fat.toString(),
    ]);
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _status = 'Nutrition goals updated.';
    });
  }

  Future<void> _pickFromFiles() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Meal images',
            extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/heic'],
            uniformTypeIdentifiers: [
              'public.jpeg',
              'public.png',
              'org.webmproject.webp',
              'public.heic',
            ],
          ),
        ],
      );
      if (file == null) return;
      final path = file.path;
      Uint8List? bytes;
      if (path.isEmpty) {
        bytes = await file.readAsBytes();
      }
      if (!mounted) return;
      setState(() {
        _pickedImage = PickedMealImage(
          name: file.name,
          path: path.isEmpty ? null : path,
          bytes: bytes,
          mimeType: file.mimeType,
        );
        _analysis = null;
        _error = null;
        _status = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _pickWithImagePicker(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
    );
    if (image == null) return;
    final path = image.path;
    Uint8List? bytes;
    if (path.isEmpty) {
      bytes = await image.readAsBytes();
    }
    if (!mounted) return;
    setState(() {
      _pickedImage = PickedMealImage(
        name: image.name,
        path: path.isEmpty ? null : path,
        bytes: bytes,
        mimeType: image.mimeType,
      );
      _analysis = null;
      _error = null;
      _status = null;
    });
  }

  Future<void> _analyze() async {
    final patientId = _patientId;
    final image = _pickedImage;
    if (patientId == null || image == null || !_canAnalyze) return;
    setState(() {
      _analyzing = true;
      _error = null;
      _status = null;
    });
    try {
      final result = await _repository.analyzeImage(
        image: image,
        patientId: patientId,
        hint: _hintController.text,
      );
      if (!mounted) return;
      setState(() => _analysis = result);
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _logMeal() async {
    final analysis = _analysis;
    final patientId = _patientId;
    if (analysis == null || !analysis.isFood || patientId == null || _logging)
      return;
    setState(() {
      _logging = true;
      _error = null;
      _status = null;
    });
    try {
      await _repository.logMeal(analysis);
      final summary = await _repository.fetchDailySummary(patientId);
      final history = await _repository.fetchMealHistory(patientId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _history = history;
        _status = 'Meal logged successfully.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal logged successfully.')),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  Future<void> _showGoalSheet() async {
    final result = await showModalBottomSheet<NutritionGoals>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _GoalSheet(goals: _goals),
    );
    if (result != null) {
      await _saveGoals(result);
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    if (_ownsRepository) {
      _repository.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_patientId == null) {
      return const _NoticeState(
        icon: Icons.lock_outline,
        title: 'Patient context required',
        message: 'Please log in before using Nutrition Monitor.',
      );
    }

    final unsupported = _capabilities?.supportsImageInput == false;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              _HeaderCard(
                capabilities: _capabilities,
                unsupported: unsupported,
              ),
              const SizedBox(height: 14),
              if (_error != null)
                _InlineBanner(message: _error!, isError: true),
              if (_status != null)
                _InlineBanner(message: _status!, isError: false),
              _ImageInputCard(
                pickedImage: _pickedImage,
                hintController: _hintController,
                analyzing: _analyzing,
                unsupported: unsupported,
                onCamera: () => _pickWithImagePicker(ImageSource.camera),
                onGallery: () => _pickWithImagePicker(ImageSource.gallery),
                onFiles: _pickFromFiles,
                onAnalyze: _canAnalyze ? _analyze : null,
              ),
              const SizedBox(height: 14),
              _ProgressCard(
                summary: _summary ?? DailySummary.empty(_patientId!),
                goals: _goals,
                onEditGoals: _showGoalSheet,
              ),
              const SizedBox(height: 14),
              if (_analysis != null)
                _AnalysisCard(
                  analysis: _analysis!,
                  logging: _logging,
                  onLogMeal: _analysis!.isFood ? _logMeal : null,
                ),
              const SizedBox(height: 14),
              _HistoryCard(history: _history),
            ],
          ),
        ),
      ],
    );
  }

  String _goalKey(int patientId) => 'nutrition_goals_$patientId';
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.capabilities, required this.unsupported});

  final NutritionModelCapabilities? capabilities;
  final bool unsupported;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.restaurant_menu_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrition Monitor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Analyze meal images with EHR-aware safety guidance.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (capabilities != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    unsupported
                        ? 'Image analysis unavailable for ${capabilities!.provider}/${capabilities!.model}.'
                        : 'Image analysis ready: ${capabilities!.provider}/${capabilities!.model}',
                    style: TextStyle(
                      color: unsupported
                          ? Theme.of(context).colorScheme.error
                          : Colors.green.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageInputCard extends StatelessWidget {
  const _ImageInputCard({
    required this.pickedImage,
    required this.hintController,
    required this.analyzing,
    required this.unsupported,
    required this.onCamera,
    required this.onGallery,
    required this.onFiles,
    required this.onAnalyze,
  });

  final PickedMealImage? pickedImage;
  final TextEditingController hintController;
  final bool analyzing;
  final bool unsupported;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFiles;
  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meal image', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
              OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
              OutlinedButton.icon(
                onPressed: onFiles,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Files'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pickedImage?.name ?? 'No meal image selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: hintController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Optional hint',
              hintText: 'e.g. homemade soup, low-salt version',
              border: OutlineInputBorder(),
            ),
          ),
          if (unsupported) ...[
            const SizedBox(height: 10),
            Text(
              'The current model does not support food image analysis. Change model settings before analyzing.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAnalyze,
            icon: analyzing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(analyzing ? 'Analyzing...' : 'Analyze meal'),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.summary,
    required this.goals,
    required this.onEditGoals,
  });

  final DailySummary summary;
  final NutritionGoals goals;
  final VoidCallback onEditGoals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's progress",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: onEditGoals,
                icon: const Icon(Icons.tune),
                label: const Text('Goals'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressLine(
            label: 'Calories',
            value: summary.totals.totalCalories,
            goal: goals.calories.toDouble(),
            suffix: 'kcal',
          ),
          _ProgressLine(
            label: 'Protein',
            value: summary.totals.totalProtein,
            goal: goals.protein.toDouble(),
            suffix: 'g',
          ),
          _ProgressLine(
            label: 'Carbs',
            value: summary.totals.totalCarbs,
            goal: goals.carbs.toDouble(),
            suffix: 'g',
          ),
          _ProgressLine(
            label: 'Fat',
            value: summary.totals.totalFat,
            goal: goals.fat.toDouble(),
            suffix: 'g',
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.goal,
    required this.suffix,
  });

  final String label;
  final double value;
  final double goal;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${value.round()} / ${goal.round()} $suffix'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analysis,
    required this.logging,
    required this.onLogMeal,
  });

  final NutritionAnalysisResult analysis;
  final bool logging;
  final VoidCallback? onLogMeal;

  @override
  Widget build(BuildContext context) {
    final nutrients = analysis.nutritionalBreakdown;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  analysis.isFood ? analysis.dishName : 'No food detected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _VerdictChip(verdict: analysis.finalVerdict),
            ],
          ),
          const SizedBox(height: 6),
          Text(analysis.finalVerdictReasoning),
          const SizedBox(height: 12),
          Text('Portion: ${analysis.portionSize}'),
          Text(
            'Ingredients: ${analysis.ingredients.isEmpty ? 'None listed' : analysis.ingredients.join(', ')}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _NutrientChip(
                label: 'Calories',
                value: nutrients.totalCalories,
                suffix: 'kcal',
              ),
              _NutrientChip(
                label: 'Protein',
                value: nutrients.totalProtein,
                suffix: 'g',
              ),
              _NutrientChip(
                label: 'Carbs',
                value: nutrients.totalCarbs,
                suffix: 'g',
              ),
              _NutrientChip(
                label: 'Fat',
                value: nutrients.totalFat,
                suffix: 'g',
              ),
              _NutrientChip(
                label: 'Sodium',
                value: nutrients.totalSodium,
                suffix: 'mg',
              ),
              _NutrientChip(
                label: 'Sugar',
                value: nutrients.totalSugar,
                suffix: 'g',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InsightSection(title: 'Risks', items: analysis.insights.risks),
          _InsightSection(title: 'Warnings', items: analysis.insights.warnings),
          _InsightSection(
            title: 'Benefits',
            items: analysis.insights.positives,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onLogMeal,
            icon: logging
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_task_outlined),
            label: Text(logging ? 'Logging...' : 'Log meal'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});

  final List<MealLogRecord> history;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meal history', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('No logged meals yet. Analyze a meal to start tracking.')
          else
            ...history
                .take(8)
                .map(
                  (meal) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      meal.dishName.isEmpty ? 'Logged meal' : meal.dishName,
                    ),
                    subtitle: Text(meal.loggedAt ?? 'Unknown time'),
                    trailing: Text(
                      '${meal.nutritionalBreakdown.totalCalories.round()} kcal',
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.goals});

  final NutritionGoals goals;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final _calories = TextEditingController(
    text: widget.goals.calories.toString(),
  );
  late final _protein = TextEditingController(
    text: widget.goals.protein.toString(),
  );
  late final _carbs = TextEditingController(
    text: widget.goals.carbs.toString(),
  );
  late final _fat = TextEditingController(text: widget.goals.fat.toString());
  String? _error;

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Daily goals', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _numberField(_calories, 'Calories'),
            _numberField(_protein, 'Protein g'),
            _numberField(_carbs, 'Carbs g'),
            _numberField(_fat, 'Fat g'),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text('Save goals')),
          ],
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _save() {
    final goals = NutritionGoals(
      calories: int.tryParse(_calories.text) ?? -1,
      protein: int.tryParse(_protein.text) ?? -1,
      carbs: int.tryParse(_carbs.text) ?? -1,
      fat: int.tryParse(_fat.text) ?? -1,
    );
    if ([
      goals.calories,
      goals.protein,
      goals.carbs,
      goals.fat,
    ].any((value) => value < 0)) {
      setState(() => _error = 'Goals must be zero or greater.');
      return;
    }
    Navigator.of(context).pop(goals);
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          ...items.map((item) => Text('• $item')),
        ],
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final double value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label ${value.round()} $suffix'));
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.verdict});

  final String verdict;

  @override
  Widget build(BuildContext context) {
    final color = switch (verdict) {
      'not_recommended' => Theme.of(context).colorScheme.errorContainer,
      'consume_in_moderation' => Colors.amber.shade100,
      'recommended' => Colors.green.shade100,
      _ => Theme.of(context).colorScheme.surfaceContainerHighest,
    };
    return Chip(
      backgroundColor: color,
      label: Text(verdict.replaceAll('_', ' ')),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isError
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.check_circle_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeState extends StatelessWidget {
  const _NoticeState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
