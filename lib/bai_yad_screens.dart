import 'package:flutter/material.dart';

const _surface = Color(0xFF0B0D10);
const _green = Color(0xFF3A9D78);
const _brightGreen = Color(0xFF4EDE98);
const _muted = Color(0xFF94A3B8);

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.destinationBuilder,
  });

  /// Builds the next screen with the profile name, without coupling this
  /// screen to a specific destination widget.
  final Widget Function(String name) destinationBuilder;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController(text: 'Juan dela Cruz');

  String get _initials {
    final parts = _nameController.text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length > 1 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _continue({bool anonymous = false}) {
    final name = anonymous || _nameController.text.trim().isEmpty
        ? 'Anonymous'
        : _nameController.text.trim();
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => widget.destinationBuilder(name),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SetupPill(),
            const SizedBox(height: 18),
            const Text(
              'What should we\ncall you?',
              style: TextStyle(
                fontSize: 29,
                height: 1.17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: Color(0xFFF3F4F6),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'BAI-yad customizes your smart insights locally. Your name never leaves this phone.',
              style: TextStyle(fontSize: 13, height: 1.6, color: _muted),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.10),
                    AnimatedBuilder(
                      animation: _nameController,
                      builder: (context, _) => _Avatar(initials: _initials),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.08),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR FULL OR FIRST NAME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _muted,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'REQUIRED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _brightGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Container(
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: TextField(
                        key: const Key('profileNameInput'),
                        controller: _nameController,
                        maxLength: 32,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'e.g. Alex Morgan',
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            key: const Key('clearNameButton'),
                            tooltip: 'Clear name',
                            onPressed: _nameController.clear,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 19,
                              color: _muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: const Key('getStartedButton'),
                onPressed: () => _continue(),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                label: const Text('Get Started'),
                style: FilledButton.styleFrom(
                  backgroundColor: _brightGreen,
                  foregroundColor: const Color(0xFF07130E),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            TextButton(
              key: const Key('skipButton'),
              onPressed: () => _continue(anonymous: true),
              child: const Center(
                child: Text(
                  'Skip for now, stay Anonymous',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SetupPill extends StatelessWidget {
  const _SetupPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _green.withValues(alpha: 0.12),
      border: Border.all(color: _green.withValues(alpha: 0.28)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: _brightGreen),
        SizedBox(width: 7),
        Text(
          'QUICK SETUP',
          style: TextStyle(
            fontSize: 10,
            color: _brightGreen,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    height: 104,
    padding: const EdgeInsets.all(2),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [_green, Color(0xFF14221C)]),
    ),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _surface,
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: _brightGreen,
          ),
        ),
      ),
    ),
  );
}
