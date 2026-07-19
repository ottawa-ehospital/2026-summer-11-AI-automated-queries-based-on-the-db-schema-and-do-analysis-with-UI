import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../../../data/models/model_invocation_settings.dart';
import '../../../data/repositories/model_invocation_settings_store.dart';
import '../../../ui/ui.dart';

class ModelInvocationSettingsScreen extends StatefulWidget {
  const ModelInvocationSettingsScreen({super.key});

  @override
  State<ModelInvocationSettingsScreen> createState() =>
      _ModelInvocationSettingsScreenState();
}

class _ModelInvocationSettingsScreenState
    extends State<ModelInvocationSettingsScreen> {
  final _store = ModelInvocationSettingsStore();
  final _modelNameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  String _providerKey = ModelInvocationSettings.providerWearableLangGraph;
  String _modelProvider = 'ollama';
  bool _useGraphFlow = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _store.loadEffective();
    if (!mounted) return;
    setState(() {
      _providerKey = settings.providerKey;
      _modelProvider = settings.modelProvider;
      _modelNameController.text = settings.modelName;
      _baseUrlController.text = settings.baseUrl;
      _useGraphFlow = settings.useGraphFlow;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final settings = ModelInvocationSettings(
      providerKey: _useGraphFlow
          ? ModelInvocationSettings.providerWearableLangGraph
          : _providerKey,
      modelProvider: _modelProvider,
      modelName: _modelNameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      useGraphFlow: _useGraphFlow,
    );
    await _store.save(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Model invocation settings saved.')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Model Invocation',
      body: _loading
          ? const LoadingStateView()
          : SingleChildScrollView(
              child: AppFormPanel(
                children: [
                  Text(
                    'Assistant Routing',
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _providerKey,
                    decoration: const InputDecoration(
                      labelText: 'Assistant provider',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value:
                            ModelInvocationSettings.providerWearableLangGraph,
                        child: Text('Wearable LangGraph'),
                      ),
                      DropdownMenuItem(
                        value: ModelInvocationSettings.providerDirectLocal,
                        child: Text('Direct local'),
                      ),
                      DropdownMenuItem(
                        value: ModelInvocationSettings.providerDirectGemini,
                        child: Text('Direct Gemini'),
                      ),
                    ],
                    onChanged: _useGraphFlow
                        ? null
                        : (value) => setState(() {
                            _providerKey = value ?? _providerKey;
                          }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use graph-backed flow'),
                    subtitle: const Text(
                      'Routes chart-capable assistant requests through the backend graph.',
                    ),
                    value: _useGraphFlow,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) => setState(() {
                      _useGraphFlow = value;
                      if (value) {
                        _providerKey =
                            ModelInvocationSettings.providerWearableLangGraph;
                      }
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Model Transport',
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _modelProvider,
                    decoration: const InputDecoration(
                      labelText: 'Model provider',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ollama',
                        child: Text('Ollama / local'),
                      ),
                      DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
                      DropdownMenuItem(
                        value: 'openai',
                        child: Text('OpenAI-compatible'),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _modelProvider = value ?? _modelProvider;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _modelNameController,
                    decoration: const InputDecoration(
                      labelText: 'Model name',
                      hintText: 'llama3.1:8b',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint / base URL',
                      hintText: 'http://127.0.0.1:11434',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
