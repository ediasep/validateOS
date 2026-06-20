import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/problem.dart';
import '../models/problem_evidence.dart';
import '../models/solution.dart';
import '../models/validation.dart';
import '../services/gemini_service.dart';
import '../services/tool_handler.dart';
import 'auth_provider.dart';
import 'problem_provider.dart';
import 'problem_evidence_provider.dart';
import 'solution_provider.dart';
import 'validation_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

class ChatMessage {
  final String role; // 'user', 'assistant', 'system'
  final String text;
  final ToolConfirmation? toolConfirmation;

  ChatMessage({
    required this.role,
    required this.text,
    this.toolConfirmation,
  });
}

class ToolConfirmation {
  final String toolName;
  final Map<String, dynamic> args;
  final bool isPending;

  ToolConfirmation({
    required this.toolName,
    required this.args,
    this.isPending = true,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ToolConfirmation? pendingConfirmation;
  final String? initialPrompt;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.pendingConfirmation,
    this.initialPrompt,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    ToolConfirmation? pendingConfirmation,
    bool clearPending = false,
    String? initialPrompt,
    bool clearInitialPrompt = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      pendingConfirmation:
          clearPending ? null : (pendingConfirmation ?? this.pendingConfirmation),
      initialPrompt:
          clearInitialPrompt ? null : (initialPrompt ?? this.initialPrompt),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  List<Map<String, dynamic>> _contents = [];

  ChatNotifier(this._ref) : super(ChatState());

  void setInitialPrompt(String prompt) {
    state = state.copyWith(initialPrompt: prompt);
  }

  Future<void> sendMessage(String text) async {
    final messages = [...state.messages, ChatMessage(role: 'user', text: text)];
    state = state.copyWith(messages: messages, isLoading: true, clearInitialPrompt: true);

    _contents.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ]
    });

    final systemPrompt = await _buildSystemPrompt();
    final gemini = _ref.read(geminiServiceProvider);

    final response = await gemini.sendMessage(
      systemPrompt: systemPrompt,
      contents: _contents,
    );

    if (response.functionCall != null) {
      final fc = response.functionCall!;
      final confirmMsg = _buildConfirmationMessage(fc.name, fc.args);
      final newMessages = [
        ...state.messages,
        if (response.text != null)
          ChatMessage(role: 'assistant', text: response.text!),
        ChatMessage(
          role: 'assistant',
          text: confirmMsg,
          toolConfirmation:
              ToolConfirmation(toolName: fc.name, args: fc.args),
        ),
      ];
      state = state.copyWith(
        messages: newMessages,
        isLoading: false,
        pendingConfirmation:
            ToolConfirmation(toolName: fc.name, args: fc.args),
      );
    } else {
      final responseText = response.text ?? 'No response from AI.';
      _contents.add({
        'role': 'model',
        'parts': [
          {'text': responseText}
        ]
      });
      final newMessages = [
        ...state.messages,
        ChatMessage(role: 'assistant', text: responseText),
      ];
      state = state.copyWith(messages: newMessages, isLoading: false);
    }
  }

  Future<void> confirmToolCall() async {
    final pending = state.pendingConfirmation;
    if (pending == null) return;

    state = state.copyWith(isLoading: true, clearPending: true);

    final client = _ref.read(supabaseClientProvider);
    final handler = ToolHandler(client);
    final result = await handler.executeToolCall(pending.toolName, pending.args);

    _contents.add({
      'role': 'model',
      'parts': [
        {
          'functionCall': {'name': pending.toolName, 'args': pending.args}
        }
      ]
    });
    _contents.add({
      'role': 'function',
      'parts': [
        {
          'functionResponse': {
            'name': pending.toolName,
            'response': {'result': result}
          }
        }
      ]
    });

    // Invalidate relevant providers
    _invalidateDataProviders();

    final systemPrompt = await _buildSystemPrompt();
    final gemini = _ref.read(geminiServiceProvider);
    final response = await gemini.sendMessage(
      systemPrompt: systemPrompt,
      contents: _contents,
    );

    final responseText = response.text ?? 'Done.';
    _contents.add({
      'role': 'model',
      'parts': [
        {'text': responseText}
      ]
    });

    final newMessages = [
      ...state.messages,
      ChatMessage(role: 'assistant', text: responseText),
    ];
    state = state.copyWith(messages: newMessages, isLoading: false);
  }

  Future<void> cancelToolCall() async {
    final pending = state.pendingConfirmation;
    if (pending == null) return;

    state = state.copyWith(clearPending: true);

    _contents.add({
      'role': 'model',
      'parts': [
        {
          'functionCall': {'name': pending.toolName, 'args': pending.args}
        }
      ]
    });
    _contents.add({
      'role': 'function',
      'parts': [
        {
          'functionResponse': {
            'name': pending.toolName,
            'response': {'result': 'User declined this action.'}
          }
        }
      ]
    });

    final newMessages = [
      ...state.messages,
      ChatMessage(role: 'system', text: 'Action cancelled.'),
    ];
    state = state.copyWith(messages: newMessages, isLoading: false);
  }

  void clearChat() {
    _contents = [];
    state = ChatState();
  }

  void _invalidateDataProviders() {
    _ref.invalidate(problemsProvider);
    _ref.invalidate(solutionsProvider);
    _ref.invalidate(allValidationsProvider);
    _ref.invalidate(allEvidenceProvider);
  }

  Future<String> _buildSystemPrompt() async {
    List<Problem> problems = [];
    List<ProblemEvidence> evidence = [];
    List<Solution> solutions = [];
    List<Validation> validations = [];

    try {
      final repo = _ref.read(problemRepositoryProvider);
      problems = await repo.fetchAll();
    } catch (_) {}
    try {
      final repo = _ref.read(problemEvidenceRepositoryProvider);
      evidence = await repo.fetchAll();
    } catch (_) {}
    try {
      final repo = _ref.read(solutionRepositoryProvider);
      solutions = await repo.fetchAll();
    } catch (_) {}
    try {
      final repo = _ref.read(validationRepositoryProvider);
      validations = await repo.fetchAll();
    } catch (_) {}

    final problemsJson = jsonEncode(problems.map((p) {
          return {
            'id': p.id,
            'statement': p.statement,
            'target_audience': p.targetAudience,
            'pain_score': p.painScore,
            'status': p.status,
            'source': p.source,
          };
        }).toList());

    final evidenceJson = jsonEncode(evidence.map((e) {
          return {
            'id': e.id,
            'problem_id': e.problemId,
            'platform': e.platform,
            'quote': e.quote,
            'url': e.url,
            'found_via': e.foundVia,
          };
        }).toList());

    final solutionsJson = jsonEncode(solutions.map((s) {
          return {
            'id': s.id,
            'problem_id': s.problemId,
            'statement': s.statement,
            'feasibility_score': s.feasibilityScore,
            'excitement_score': s.excitementScore,
            'status': s.status,
          };
        }).toList());

    final validationsJson = jsonEncode(validations.map((v) {
          return {
            'id': v.id,
            'solution_id': v.solutionId,
            'method': v.method,
            'hypothesis': v.hypothesis,
            'result': v.result,
          };
        }).toList());

    return '''You are a lean product discovery coach embedded in ProblemFit, an app for solo developers using a simplified Problem → Solution → Validation framework.

You help the user:
1. Capture and assess real problems with objective pain signals (not vague hunches)
2. Find external evidence that a problem is real — review site complaints, forum threads, social media posts — using web search when helpful
3. Avoid jumping to the first solution — encourage 2+ candidate solutions per problem
4. Insist on validation evidence before a solution moves to "Building"
5. Identify which problems are worth pursuing based on pain score AND supporting evidence

You have access to the user's current data:

PROBLEMS (sorted by pain score desc):
$problemsJson

PROBLEM EVIDENCE:
$evidenceJson

SOLUTIONS (sorted by feasibility x excitement desc):
$solutionsJson

VALIDATIONS:
$validationsJson

Rules:
- Be direct and concise — this is a mobile chat, not an essay.
- A pain score under 7 is a weak signal — tell the user honestly if a problem doesn't seem worth pursuing.
- A problem with a high pain score but zero evidence is still just an opinion — encourage finding evidence before calling it "Worth Pursuing."
- If a problem has only one solution, gently push for a second candidate before they commit.
- Never encourage moving a solution to "Building" status without at least one passed validation.
- Use plain, jargon-free language. Stick to Problem, Solution, Validation.

You have web search access. When the user asks you to find evidence for a problem, use web search to find real quotes. When you find a relevant quote:
- Always cite the actual platform and include the URL if available
- Never fabricate a quote or URL — if search doesn't find something concrete, say so honestly
- Present what you found to the user first, then offer to save it via the create_problem_evidence tool

You have write access via tools. When the user asks you to log a problem, create a solution, log a validation, or save evidence — use the appropriate tool. Explain what you're about to create and why, then call the tool. The app will show a confirmation card before saving.

Before calling create_problem, make sure the statement describes a real problem for a specific audience.
Before calling create_solution, you must have a problem_id.
Before calling create_problem_evidence, you must have a problem_id and a real quote.
Use update_problem_status or update_solution_status when the user indicates a decision has been made.''';
  }

  String _buildConfirmationMessage(String toolName, Map<String, dynamic> args) {
    switch (toolName) {
      case 'create_problem':
        return 'I\'d like to log this problem:\n"${args['statement']}"\nTarget: ${args['target_audience']}\nConfirm?';
      case 'create_solution':
        return 'I\'d like to create this solution:\n"${args['statement']}"\nConfirm?';
      case 'create_validation':
        return 'I\'d like to log this validation:\nMethod: ${args['method']}\nHypothesis: "${args['hypothesis']}"\nConfirm?';
      case 'create_problem_evidence':
        return 'I\'d like to save this evidence:\n[${args['platform']}] "${args['quote']}"\nConfirm?';
      case 'update_problem_status':
        return 'Update problem status to "${args['status']}"?\nConfirm?';
      case 'update_solution_status':
        return 'Update solution status to "${args['status']}"?\nConfirm?';
      default:
        return 'Execute $toolName?\nConfirm?';
    }
  }
}
