import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/api_config.dart';
import '../../../data/models/assistant_models.dart';
import '../../../l10n/l10n.dart';
import '../../../services/ai_service.dart';
import '../data/chat_session_store.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../presentation/assistant_styles.dart';
import '../widgets/ai_assistant_module_picker.dart';
import '../widgets/assistant_empty_state.dart';
import '../widgets/assistant_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../../nutrition_monitor/nutrition_monitor.dart';
import '../../report_interpreter/report_interpreter.dart';

class HealthAssistantScreen extends StatefulWidget {
  const HealthAssistantScreen({
    super.key,
    WidgetBuilder? reportInterpreterBuilder,
    WidgetBuilder? nutritionMonitorBuilder,
  }) : _reportInterpreterBuilder = reportInterpreterBuilder,
       _nutritionMonitorBuilder = nutritionMonitorBuilder;

  final WidgetBuilder? _reportInterpreterBuilder;
  final WidgetBuilder? _nutritionMonitorBuilder;

  @override
  State<HealthAssistantScreen> createState() => _HealthAssistantScreenState();
}

class _HealthAssistantScreenState extends State<HealthAssistantScreen> {
  int _selectedModuleIndex = 0;

  List<AiAssistantModuleDefinition> _buildModules(BuildContext context) {
    final l10n = context.l10n;
    return [
      AiAssistantModuleDefinition(
        id: 'health-chat',
        label: l10n.assistantModuleChatLabel,
        description: l10n.assistantModuleChatDescription,
        icon: Icons.chat_bubble_outline,
        builder: (_) => const _HealthChatPage(),
      ),
      AiAssistantModuleDefinition(
        id: 'report-analyze',
        label: l10n.assistantModuleReportLabel,
        description: l10n.assistantModuleReportDescription,
        icon: Icons.description_outlined,
        builder: (context) => _ReportInterpreterPage(
          title: l10n.assistantModuleReportLabel,
          child:
              widget._reportInterpreterBuilder?.call(context) ??
              const ReportInterpreterScreen(),
        ),
      ),
      AiAssistantModuleDefinition(
        id: 'nutrition-monitor',
        label: l10n.assistantModuleNutritionLabel,
        description: l10n.assistantModuleNutritionDescription,
        icon: Icons.restaurant_menu_outlined,
        builder: (context) => _ReportInterpreterPage(
          title: l10n.assistantModuleNutritionLabel,
          child:
              widget._nutritionMonitorBuilder?.call(context) ??
              const NutritionMonitorScreen(),
        ),
      ),
    ];
  }

  void _launchModule(AiAssistantModuleDefinition module) {
    Navigator.of(context).push(MaterialPageRoute(builder: module.builder));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final modules = _buildModules(context);
    final selectedIndex = _selectedModuleIndex.clamp(0, modules.length - 1);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiHealthAssistantTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: AssistantStyles.modulePickerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.assistantPickerTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: AiAssistantModulePicker(
                      modules: modules,
                      selectedIndex: selectedIndex,
                      onSelected: (index) {
                        setState(() => _selectedModuleIndex = index);
                      },
                      onLaunch: _launchModule,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HealthChatPage extends StatelessWidget {
  const _HealthChatPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.aiWellnessAssistantTitle),
            Text(
              l10n.aiWellnessAssistantDisclaimer,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: const HealthChatModule(),
    );
  }
}

class _ReportInterpreterPage extends StatelessWidget {
  const _ReportInterpreterPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}

class HealthChatModule extends StatefulWidget {
  const HealthChatModule({super.key});

  @override
  State<HealthChatModule> createState() => _HealthChatModuleState();
}

class _HealthChatModuleState extends State<HealthChatModule> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _sessionStore = ChatSessionStore();
  late ChatSession _currentSession;
  List<ChatSession> _savedSessions = [];
  bool _isLoading = false;

  List<ChatMessage> get _messages => _currentSession.messages;

  @override
  void initState() {
    super.initState();
    _currentSession = ChatSession.blank();
    _loadSavedSessions();
  }

  Future<void> _loadSavedSessions() async {
    final sessions = await _sessionStore.loadSessions();
    if (!mounted) return;
    setState(() => _savedSessions = sessions);
  }

  Future<void> _sendMessage() async {
    final question = _inputController.text.trim();
    if (question.isEmpty || _isLoading) return;

    final l10n = context.l10n;
    final priorMessages = List<ChatMessage>.from(_messages);
    final history = _recentHistory(priorMessages);
    _inputController.clear();
    final userMessage = ChatMessage(role: 'user', content: question);
    setState(() {
      _currentSession = _appendMessage(_currentSession, userMessage);
      _isLoading = true;
    });
    await _persistCurrentSession();
    _scrollToBottom();

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawId = prefs.get('patient_id');
      final patientId = int.tryParse(rawId?.toString() ?? '') ?? 0;
      debugPrint(
        '[HealthAssistant] provider=${ApiConfig.aiProvider} '
        'backend=${ApiConfig.backendBaseUrl} patient_id=$patientId',
      );
      if (patientId == 0) {
        final assistantMessage = ChatMessage(
          role: 'assistant',
          content: l10n.assistantLoginRequired,
        );
        setState(() {
          _currentSession = _appendMessage(_currentSession, assistantMessage);
        });
        await _persistCurrentSession();
        return;
      }

      final response = await AiService.generateAssistantReply(
        prompt: question,
        patientId: patientId.toString(),
        history: history,
      );

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.reply.trim(),
        results: response.results,
      );
      setState(() {
        _currentSession = _appendMessage(_currentSession, assistantMessage);
      });
      await _persistCurrentSession();
    } catch (error) {
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: l10n.assistantErrorMessage(error.toString()),
      );
      setState(() {
        _currentSession = _appendMessage(_currentSession, assistantMessage);
      });
      await _persistCurrentSession();
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  ChatSession _appendMessage(ChatSession session, ChatMessage message) {
    final messages = [...session.messages, message];
    final title = session.title.trim().isEmpty && message.isUser
        ? ChatSession.inferTitle(message.content)
        : session.title;
    return session.copyWith(
      title: title,
      updatedAt: DateTime.now(),
      messages: messages,
    );
  }

  List<AssistantConversationMessage> _recentHistory(
    List<ChatMessage> messages,
  ) {
    final session = _currentSession.copyWith(messages: messages);
    return session
        .recentMessagesForContext()
        .map(
          (message) => AssistantConversationMessage(
            role: message.role,
            content: message.content,
          ),
        )
        .toList();
  }

  Future<void> _persistCurrentSession() async {
    await _sessionStore.upsertSession(_currentSession);
    await _loadSavedSessions();
  }

  void _startNewChat() {
    if (_isLoading) return;
    setState(() => _currentSession = ChatSession.blank());
    _scrollToBottom();
  }

  Future<void> _showHistorySelector() async {
    await _loadSavedSessions();
    if (!mounted) return;
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<ChatSession>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final sessions = _savedSessions;
        return SafeArea(
          child: sessions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.assistantNoHistory),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(
                        session.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        session.preview.isEmpty
                            ? _formatSessionDate(session.updatedAt)
                            : '${session.preview}\n${_formatSessionDate(session.updatedAt)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(session),
                    );
                  },
                ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _currentSession = selected);
    _scrollToBottom();
  }

  String _formatSessionDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: l10n.assistantHistoryTooltip,
                onPressed: _showHistorySelector,
              ),
              IconButton(
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: l10n.newChatTooltip,
                onPressed: _startNewChat,
              ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: AssistantEmptyState(
                          title: l10n.assistantEmptyTitle,
                          firstPrompt: l10n.assistantPromptHeartRate,
                          secondPrompt: l10n.assistantPromptActivity,
                          disclaimer: l10n.assistantGeneralDisclaimer,
                          compact: keyboardOpen,
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: AssistantStyles.messagesPadding,
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == _messages.length) {
                      return AssistantTypingIndicator(
                        label: l10n.assistantThinking,
                      );
                    }
                    return ChatMessageBubble(message: _messages[index]);
                  },
                ),
        ),
        AssistantInputBar(
          controller: _inputController,
          hintText: l10n.assistantInputHint,
          isLoading: _isLoading,
          onSend: _sendMessage,
        ),
      ],
    );
  }
}
