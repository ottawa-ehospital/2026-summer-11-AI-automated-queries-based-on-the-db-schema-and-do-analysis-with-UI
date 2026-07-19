import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ui/ui.dart';
import '../data/report_interpreter_repository.dart';
import '../models/report_interpreter_models.dart';

class ReportInterpreterScreen extends StatefulWidget {
  const ReportInterpreterScreen({
    super.key,
    ReportInterpreterRepository? repository,
  }) : _repository = repository;

  final ReportInterpreterRepository? _repository;

  @override
  State<ReportInterpreterScreen> createState() =>
      _ReportInterpreterScreenState();
}

class _ReportInterpreterScreenState extends State<ReportInterpreterScreen> {
  static const int _maxUploadBytes = 25 * 1024 * 1024;
  late final ReportInterpreterRepository _repository;
  late final bool _ownsRepository;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  ReportSession _session = ReportSession.blank();
  PickedReport? _pendingReport;
  String? _patientId;
  String? _activeTestType;
  String? _activeDate;
  List<TestType> _testTypes = [];
  List<String> _dates = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget._repository ?? ReportInterpreterRepository();
    _ownsRepository = widget._repository == null;
    _loadPatientContext();
    _loadTestTypes();
  }

  Future<void> _loadPatientContext() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.get('patient_id')?.toString();
    if (!mounted) return;
    setState(() => _patientId = id?.trim().isEmpty == true ? null : id);
    await _loadDates();
  }

  Future<void> _loadTestTypes() async {
    try {
      final types = await _repository.fetchTestTypes();
      if (!mounted) return;
      setState(() {
        _testTypes = types;
        _activeTestType = types.isEmpty ? null : types.first.id;
      });
      await _loadDates();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _loadDates() async {
    final patientId = _patientId;
    final type = _activeTestType;
    if (patientId == null || type == null) return;
    try {
      final dates = await _repository.fetchDates(
        testType: type,
        patientId: patientId,
      );
      if (!mounted) return;
      setState(() {
        _dates = dates;
        _activeDate = dates.isEmpty ? null : dates.first;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _pickReport() async {
    try {
      setState(() => _error = null);
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Reports',
            extensions: [
              'txt',
              'json',
              'pdf',
              'jpg',
              'jpeg',
              'png',
              'bmp',
              'tif',
              'tiff',
            ],
            mimeTypes: [
              'text/plain',
              'application/json',
              'application/pdf',
              'image/jpeg',
              'image/png',
              'image/bmp',
              'image/tiff',
            ],
            uniformTypeIdentifiers: [
              'public.plain-text',
              'public.json',
              'com.adobe.pdf',
              'public.jpeg',
              'public.png',
              'com.microsoft.bmp',
              'public.tiff',
            ],
          ),
        ],
      );
      if (file == null) return;
      final size = await file.length();
      if (size > _maxUploadBytes) {
        if (!mounted) return;
        setState(
          () => _error =
              'That file is too large to upload on device. Please choose a report under 25 MB.',
        );
        return;
      }
      final path = file.path;
      final bytes = path.isEmpty ? await file.readAsBytes() : null;
      if (!mounted) return;
      setState(() {
        _pendingReport = PickedReport(
          name: file.name,
          path: path.isEmpty ? null : path,
          bytes: bytes,
          sizeBytes: size,
        );
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not open that report file: $error');
    }
  }

  Future<void> _loadSampleReport() async {
    try {
      final data = await rootBundle.load(
        'assets/sample_reports/blood_report_sample.txt',
      );
      if (!mounted) return;
      setState(() {
        _pendingReport = PickedReport(
          name: 'blood_report_sample.txt',
          bytes: data.buffer.asUint8List(),
          sizeBytes: data.lengthInBytes,
        );
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not load the sample report: $error');
    }
  }

  Future<void> _analyzePendingReport() async {
    final report = _pendingReport;
    if (report == null || _loading) return;
    await _analyzeReport(report);
  }

  Future<void> _loadSavedRecord() async {
    final patientId = _patientId;
    final type = _activeTestType;
    final date = _activeDate;
    if (patientId == null || type == null || date == null || _loading) return;
    try {
      final report = await _repository.fetchSavedRecord(
        type: type,
        date: date,
        patientId: patientId,
      );
      await _analyzeReport(report, fromSavedRecord: true);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _analyzeReport(
    PickedReport report, {
    String? userQuestion,
    bool fromSavedRecord = false,
  }) async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) {
      setState(() => _error = 'Please log in before analyzing reports.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _session.status = ReportSessionStatus.analyzing;
      _session.messages = [
        ..._session.messages,
        ReportChatMessage(
          sender: 'user',
          text: userQuestion?.trim().isNotEmpty == true
              ? userQuestion!.trim()
              : 'Analyze ${report.name}',
          timestamp: DateTime.now(),
          isFile: true,
          fileName: report.name,
        ),
      ];
    });
    _scrollToBottom();

    try {
      final result = await _repository.analyzeReport(
        report: report,
        previousFileContext: _session.fileContext,
        userQuestion: userQuestion,
        patientId: patientId,
        fromSavedRecord: fromSavedRecord,
      );
      final saveNote = _saveNote(result);
      final text = saveNote == null
          ? result.analysis
          : '${result.analysis}\n\n$saveNote';
      final questions = await _repository.suggestQuestions(
        latestResponse: result.analysis,
        fileContext: result.fileContext,
        patientId: int.tryParse(patientId),
      );
      if (!mounted) return;
      setState(() {
        _pendingReport = null;
        _session
          ..status = ReportSessionStatus.complete
          ..fileContext = result.fileContext
          ..suggestedQuestions = questions
          ..needsPatientName = result.patientNameNeeded
          ..pendingLabValues = result.labValues
          ..pendingReportDate = result.reportDate
          ..pendingDetectedTestType = result.detectedTestType
          ..messages = [
            ..._session.messages,
            ReportChatMessage(
              sender: 'assistant',
              text: result.patientNameNeeded
                  ? '${result.patientNameQuestion}\n\n$text'
                  : text,
              timestamp: DateTime.now(),
              labValues: result.labValues,
            ),
          ];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _session.status = ReportSessionStatus.error;
        _session.messages = [
          ..._session.messages,
          ReportChatMessage(
            sender: 'assistant',
            text: 'I could not analyze that report: $error',
            timestamp: DateTime.now(),
          ),
        ];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || _loading) return;
    if (!_session.needsPatientName && _session.fileContext == null) {
      setState(
        () => _error = 'Analyze a report before asking follow-up questions.',
      );
      return;
    }
    _inputController.clear();

    if (_session.needsPatientName) {
      await _assignPatient(text);
      return;
    }

    setState(() {
      _loading = true;
      _session.messages = [
        ..._session.messages,
        ReportChatMessage(
          sender: 'user',
          text: text,
          timestamp: DateTime.now(),
        ),
      ];
    });
    _scrollToBottom();

    try {
      final reply = await _repository.sendChat(
        messages: _session.messages
            .map(
              (message) => {
                'role': message.isUser ? 'user' : 'assistant',
                'content': message.text,
              },
            )
            .toList(),
        fileContext: _session.fileContext,
      );
      final questions = await _repository.suggestQuestions(
        latestResponse: reply,
        fileContext: _session.fileContext,
        patientId: int.tryParse(_patientId ?? ''),
      );
      if (!mounted) return;
      setState(() {
        _session
          ..suggestedQuestions = questions
          ..messages = [
            ..._session.messages,
            ReportChatMessage(
              sender: 'assistant',
              text: reply,
              timestamp: DateTime.now(),
            ),
          ];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _assignPatient(String patientName) async {
    setState(() => _loading = true);
    try {
      final result = await _repository.assignPendingReportToPatient(
        name: patientName,
        labValues: _session.pendingLabValues,
        reportDate: _session.pendingReportDate,
        detectedTestType: _session.pendingDetectedTestType,
      );
      final errors = result.saveErrors.isEmpty
          ? ''
          : '\n${result.saveErrors.join('\n')}';
      if (!mounted) return;
      setState(() {
        _session
          ..needsPatientName = false
          ..messages = [
            ..._session.messages,
            ReportChatMessage(
              sender: 'assistant',
              text:
                  'Saved ${result.savedLabRecordCount} parsed record${result.savedLabRecordCount == 1 ? '' : 's'} for ${result.patient?.name ?? patientName}.$errors',
              timestamp: DateTime.now(),
            ),
          ];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _saveNote(AnalyzeReportResult result) {
    final notes = <String>[];
    if (result.savedLabRecordCount > 0) {
      notes.add(
        'Saved ${result.savedLabRecordCount} ${result.detectedTestType} record${result.savedLabRecordCount == 1 ? '' : 's'}${result.reportDate == null ? '' : ' for ${result.reportDate}'}.',
      );
    }
    notes.addAll(result.saveErrors);
    return notes.isEmpty ? null : notes.join('\n');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showReportActions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _ReportActionsSheet(
          patientId: _patientId,
          pendingReport: _pendingReport,
          loading: _loading,
          testTypes: _testTypes,
          dates: _dates,
          activeTestType: _activeTestType,
          activeDate: _activeDate,
          onPickReport: () {
            Navigator.of(context).pop();
            _pickReport();
          },
          onLoadSample: () {
            Navigator.of(context).pop();
            _loadSampleReport();
          },
          onAnalyze: () {
            Navigator.of(context).pop();
            _analyzePendingReport();
          },
          onLoadSaved: () {
            Navigator.of(context).pop();
            _loadSavedRecord();
          },
          onTestTypeChanged: (value) async {
            setState(() {
              _activeTestType = value;
              _activeDate = null;
              _dates = [];
            });
            await _loadDates();
          },
          onDateChanged: (value) => setState(() => _activeDate = value),
        );
      },
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    if (_ownsRepository) {
      _repository.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAskQuestion =
        _session.fileContext != null || _session.needsPatientName;
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _InlineError(message: _error!),
          ),
        Expanded(
          child: _session.messages.isEmpty
              ? SingleChildScrollView(
                  child: _ReportEmptyState(pendingReport: _pendingReport),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: _session.messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_loading && index == _session.messages.length) {
                      return const _ReportTypingIndicator();
                    }
                    return _ReportMessageBubble(
                      message: _session.messages[index],
                    );
                  },
                ),
        ),
        if (_session.suggestedQuestions.isNotEmpty)
          _SuggestedQuestions(
            questions: _session.suggestedQuestions,
            onSelected: _sendMessage,
          ),
        _ReportInputBar(
          controller: _inputController,
          loading: _loading,
          needsPatientName: _session.needsPatientName,
          canAskQuestion: canAskQuestion,
          hasPendingReport: _pendingReport != null,
          onActions: _showReportActions,
          onSend: _sendMessage,
        ),
      ],
    );
  }
}

class _ReportActionsSheet extends StatelessWidget {
  const _ReportActionsSheet({
    required this.patientId,
    required this.pendingReport,
    required this.loading,
    required this.testTypes,
    required this.dates,
    required this.activeTestType,
    required this.activeDate,
    required this.onPickReport,
    required this.onLoadSample,
    required this.onAnalyze,
    required this.onLoadSaved,
    required this.onTestTypeChanged,
    required this.onDateChanged,
  });

  final String? patientId;
  final PickedReport? pendingReport;
  final bool loading;
  final List<TestType> testTypes;
  final List<String> dates;
  final String? activeTestType;
  final String? activeDate;
  final VoidCallback onPickReport;
  final VoidCallback onLoadSample;
  final VoidCallback onAnalyze;
  final VoidCallback onLoadSaved;
  final ValueChanged<String?> onTestTypeChanged;
  final ValueChanged<String?> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final hasReport = pendingReport != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload report',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      hasReport
                          ? Icons.description
                          : Icons.description_outlined,
                      color: hasReport
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pendingReport?.name ?? 'No report selected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: loading ? null : onLoadSample,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Load sample'),
                ),
                OutlinedButton.icon(
                  onPressed: loading ? null : onPickReport,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Choose file'),
                ),
                FilledButton.icon(
                  onPressed: loading || !hasReport ? null : onAnalyze,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Analyze'),
                ),
              ],
            ),
            if (!hasReport) ...[
              const SizedBox(height: 8),
              Text(
                'Start by loading the sample or choosing a report from Files.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Saved records',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(activeTestType),
                    initialValue: activeTestType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Saved type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: testTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type.id,
                            child: Text(type.name),
                          ),
                        )
                        .toList(),
                    onChanged: loading ? null : onTestTypeChanged,
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(activeDate),
                    initialValue: activeDate,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Saved date',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: dates
                        .map(
                          (date) =>
                              DropdownMenuItem(value: date, child: Text(date)),
                        )
                        .toList(),
                    onChanged: loading ? null : onDateChanged,
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      loading ||
                          patientId == null ||
                          activeTestType == null ||
                          activeDate == null
                      ? null
                      : onLoadSaved,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Analyze saved'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportEmptyState extends StatelessWidget {
  const _ReportEmptyState({required this.pendingReport});

  final PickedReport? pendingReport;

  @override
  Widget build(BuildContext context) {
    final fileName = pendingReport?.name;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 44,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Ready for a report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              fileName == null
                  ? 'Tap + to load the sample, choose a file, or open saved records.'
                  : '$fileName selected. Tap +, then Analyze.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMessageBubble extends StatelessWidget {
  const _ReportMessageBubble({required this.message});

  final ReportChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.fileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    Flexible(
                      child: Text(
                        message.fileName!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            isUser
                ? Text(message.text)
                : MarkdownBody(data: message.text, selectable: true),
            if (message.labValues.isNotEmpty) ...[
              const SizedBox(height: 12),
              _LabValueList(values: message.labValues),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabValueList extends StatelessWidget {
  const _LabValueList({required this.values});

  final List<LabValueVisual> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final color = switch (value.status) {
          'high' => Colors.red,
          'low' => Colors.blue,
          _ => Colors.green,
        };
        final display =
            value.display ?? '${value.value.g} ${value.unit}'.trim();
        return Chip(
          avatar: CircleAvatar(backgroundColor: color, radius: 5),
          label: Text('${value.name}: $display'),
        );
      }).toList(),
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions({
    required this.questions,
    required this.onSelected,
  });

  final List<String> questions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ActionChip(
          label: Text(questions[index]),
          onPressed: () => onSelected(questions[index]),
        ),
      ),
    );
  }
}

class _ReportInputBar extends StatelessWidget {
  const _ReportInputBar({
    required this.controller,
    required this.loading,
    required this.needsPatientName,
    required this.canAskQuestion,
    required this.hasPendingReport,
    required this.onActions,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool loading;
  final bool needsPatientName;
  final bool canAskQuestion;
  final bool hasPendingReport;
  final VoidCallback onActions;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Report actions',
              onPressed: onActions,
              icon: Icon(
                hasPendingReport ? Icons.description_outlined : Icons.add,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !loading && canAskQuestion,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: needsPatientName
                      ? 'Enter the patient full name'
                      : canAskQuestion
                      ? 'Ask a question about this report'
                      : 'Analyze a report first',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: loading || !canAskQuestion ? null : onSend,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ReportTypingIndicator extends StatelessWidget {
  const _ReportTypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 16),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Reviewing report...'),
        ],
      ),
    );
  }
}

extension on double {
  String get g => toStringAsFixed(truncateToDouble() == this ? 0 : 2);
}
