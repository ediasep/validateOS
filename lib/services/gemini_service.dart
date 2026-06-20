import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  final FlutterSecureStorage _storage;

  GeminiService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getApiKey() async {
    return _storage.read(key: 'gemini_api_key');
  }

  Future<void> setApiKey(String key) async {
    await _storage.write(key: 'gemini_api_key', value: key);
  }

  Future<void> removeApiKey() async {
    await _storage.delete(key: 'gemini_api_key');
  }

  static final List<Map<String, dynamic>> _functionDeclarations = [
    {
      'name': 'create_problem',
      'description':
          'Log a new problem. Must be a real problem for a specific audience.',
      'parameters': {
        'type': 'object',
        'properties': {
          'statement': {'type': 'string'},
          'target_audience': {'type': 'string'},
          'source': {
            'type': 'string',
            'enum': ['Interview', 'Observation', 'Research', 'Assumption']
          },
          'time_spent_score': {'type': 'integer', 'minimum': 1, 'maximum': 5},
          'complaint_frequency_score': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 5
          },
          'pays_for_alternative': {'type': 'boolean'},
          'willingness_to_pay_score': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 5
          },
          'notes': {'type': 'string'}
        },
        'required': [
          'statement',
          'target_audience',
          'source',
          'time_spent_score',
          'complaint_frequency_score',
          'pays_for_alternative',
          'willingness_to_pay_score'
        ]
      }
    },
    {
      'name': 'create_solution',
      'description':
          'Create a solution linked to a problem. Must be concrete and buildable.',
      'parameters': {
        'type': 'object',
        'properties': {
          'problem_id': {'type': 'string'},
          'statement': {'type': 'string'},
          'feasibility_score': {'type': 'integer', 'minimum': 1, 'maximum': 5},
          'excitement_score': {'type': 'integer', 'minimum': 1, 'maximum': 5},
          'notes': {'type': 'string'}
        },
        'required': [
          'problem_id',
          'statement',
          'feasibility_score',
          'excitement_score'
        ]
      }
    },
    {
      'name': 'create_validation',
      'description': 'Log a validation attempt for a solution.',
      'parameters': {
        'type': 'object',
        'properties': {
          'solution_id': {'type': 'string'},
          'method': {
            'type': 'string',
            'enum': [
              'Customer Interview',
              'Fake Door',
              'Prototype',
              'Survey',
              'Concierge',
              'Pre-sale'
            ]
          },
          'hypothesis': {'type': 'string'},
          'success_signal': {'type': 'string'},
          'result': {
            'type': 'string',
            'enum': ['Not Run Yet', 'Passed', 'Failed', 'Inconclusive']
          },
          'evidence': {'type': 'string'}
        },
        'required': ['solution_id', 'method', 'hypothesis', 'success_signal']
      }
    },
    {
      'name': 'create_problem_evidence',
      'description':
          'Save external evidence confirming a problem is real. Quote must be real.',
      'parameters': {
        'type': 'object',
        'properties': {
          'problem_id': {'type': 'string'},
          'platform': {
            'type': 'string',
            'enum': [
              'Trustpilot',
              'G2',
              'Reddit',
              'Twitter/X',
              'App Store Review',
              'Google Play Review',
              'Forum',
              'Other'
            ]
          },
          'quote': {'type': 'string'},
          'url': {'type': 'string'},
          'found_via': {
            'type': 'string',
            'enum': ['Manual', 'AI Search']
          }
        },
        'required': ['problem_id', 'platform', 'quote', 'found_via']
      }
    },
    {
      'name': 'update_problem_status',
      'description': "Update a problem's status.",
      'parameters': {
        'type': 'object',
        'properties': {
          'problem_id': {'type': 'string'},
          'status': {
            'type': 'string',
            'enum': ['Logged', 'Worth Pursuing', 'Not Worth It', 'Archived']
          }
        },
        'required': ['problem_id', 'status']
      }
    },
    {
      'name': 'update_solution_status',
      'description':
          "Update a solution's status. Cannot set to Building without a Passed validation.",
      'parameters': {
        'type': 'object',
        'properties': {
          'solution_id': {'type': 'string'},
          'status': {
            'type': 'string',
            'enum': [
              'Idea',
              'Chosen',
              'Validating',
              'Validated',
              'Killed',
              'Building'
            ]
          }
        },
        'required': ['solution_id', 'status']
      }
    },
  ];

  static final List<Map<String, dynamic>> _tools = [
    {'functionDeclarations': _functionDeclarations},
    {'googleSearch': {}},
  ];

  static const _writeFunctionNames = {
    'create_problem',
    'create_solution',
    'create_validation',
    'create_problem_evidence',
    'update_problem_status',
    'update_solution_status',
  };

  Future<GeminiResponse> sendMessage({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponse(
        text: 'No Gemini API key configured. Go to Settings to add one.',
        functionCall: null,
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': contents,
          'tools': _tools,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error']?['message'] ?? 'Unknown API error';
        return GeminiResponse(
          text: 'AI error: $errorMessage',
          functionCall: null,
        );
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        final blockReason = data['promptFeedback']?['blockReason'];
        if (blockReason != null) {
          return GeminiResponse(
            text: "The AI couldn't respond to that. Try rephrasing.",
            functionCall: null,
          );
        }
        return GeminiResponse(
          text: 'No response from AI. Try again.',
          functionCall: null,
        );
      }

      final candidate = candidates[0];
      final finishReason = candidate['finishReason'] as String?;
      if (finishReason == 'SAFETY') {
        return GeminiResponse(
          text: "The AI couldn't respond to that. Try rephrasing.",
          functionCall: null,
        );
      }

      final parts = candidate['content']?['parts'] as List? ?? [];
      String? textResult;
      GeminiFunctionCall? functionCallResult;

      for (final part in parts) {
        if (part.containsKey('text')) {
          textResult = (textResult ?? '') + (part['text'] as String);
        }
        if (part.containsKey('functionCall')) {
          final fc = part['functionCall'] as Map<String, dynamic>;
          final name = fc['name'] as String;
          final args = (fc['args'] as Map<String, dynamic>?) ?? {};
          if (_writeFunctionNames.contains(name)) {
            functionCallResult = GeminiFunctionCall(name: name, args: args);
          }
        }
      }

      return GeminiResponse(
        text: textResult,
        functionCall: functionCallResult,
      );
    } catch (e) {
      return GeminiResponse(
        text: 'Network error: ${e.toString()}',
        functionCall: null,
      );
    }
  }

  Future<Map<String, dynamic>?> reviewProblem({
    required String statement,
    required String targetAudience,
    required String source,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    const systemPrompt = '''You are a lean product discovery coach for solo developers, using a simplified Problem-Solution-Validation framework.

Your job is to review a problem statement before it is saved.

A good problem statement must:
- Describe something a specific audience struggles with, not a vague generalization
- Be a real problem, not a feature request or solution in disguise
- Be specific enough that you could ask someone "tell me about the last time this happened to you"

Review the statement and respond with JSON only, no markdown:
{
  "verdict": "approved" | "needs_work" | "rejected",
  "score": 1-10,
  "issues": ["issue 1"],
  "suggestion": "improved version of the statement",
  "explanation": "2-3 sentence plain language explanation",
  "pain_signal_check": "comment on whether the audience and problem combination seems painful enough"
}''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'Problem statement: "$statement"\nTarget audience: "$targetAudience"\nSource: $source'
                }
              ]
            }
          ],
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final parts = data['candidates']?[0]?['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final text = parts[0]['text'] as String?;
      if (text == null) return null;

      final cleaned =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> reviewSolution({
    required String statement,
    required String problemStatement,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    const systemPrompt = '''You are a lean product discovery coach for solo developers.

Review this solution before it is saved.

A good solution must be:
- Concrete and buildable, not vague
- Clearly addressing the linked problem
- Scoped small enough to validate before fully building

Respond with JSON only, no markdown:
{
  "verdict": "approved" | "needs_work" | "rejected",
  "score": 1-10,
  "issues": ["issue 1"],
  "suggestion": "improved version",
  "explanation": "2-3 sentence plain explanation",
  "validation_idea": "one cheap way to test this before building it fully"
}''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'Linked problem: "$problemStatement"\nSolution statement: "$statement"'
                }
              ]
            }
          ],
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final parts = data['candidates']?[0]?['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final text = parts[0]['text'] as String?;
      if (text == null) return null;

      final cleaned =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

class GeminiResponse {
  final String? text;
  final GeminiFunctionCall? functionCall;

  GeminiResponse({this.text, this.functionCall});
}

class GeminiFunctionCall {
  final String name;
  final Map<String, dynamic> args;

  GeminiFunctionCall({required this.name, required this.args});
}
