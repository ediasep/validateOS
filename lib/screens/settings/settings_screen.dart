import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/gemini_service.dart';
import '../../theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isApiKeyVisible = false;
  bool _hasApiKey = false;
  final _gemini = GeminiService();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await _gemini.getApiKey();
    if (key != null && key.isNotEmpty) {
      setState(() {
        _hasApiKey = true;
        _apiKeyController.text = key;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      await _gemini.removeApiKey();
      setState(() => _hasApiKey = false);
    } else {
      await _gemini.setApiKey(key);
      setState(() => _hasApiKey = true);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved')),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear All Data',
          style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will permanently delete all your problems, solutions, validations, and evidence. This cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser!.id;
      await client.from('validations').delete().eq('user_id', userId);
      await client.from('solutions').delete().eq('user_id', userId);
      await client.from('problem_evidence').delete().eq('user_id', userId);
      await client.from('problems').delete().eq('user_id', userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signOut();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Google Gemini API Key',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apiKeyController,
            obscureText: !_isApiKeyVisible,
            decoration: InputDecoration(
              hintText: 'Paste your Gemini API key',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isApiKeyVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _isApiKeyVisible = !_isApiKeyVisible),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, size: 20),
                    onPressed: _saveApiKey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                launchUrl(Uri.parse('https://aistudio.google.com/apikey')),
            child: Text(
              'Get your API key at aistudio.google.com/apikey',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.accent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          if (!_hasApiKey) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Text(
                'AI features (chat, problem/solution review) are disabled until you add an API key.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          ListTile(
            leading:
                const Icon(Icons.logout, color: AppColors.textSecondary),
            title: Text(
              'Sign Out',
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
            onTap: _signOut,
          ),
          ListTile(
            leading:
                const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              'Clear All Data',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
            onTap: _clearAllData,
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'ProblemFit v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
