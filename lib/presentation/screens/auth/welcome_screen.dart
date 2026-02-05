import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/presentation/widgets/entrance_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_WelcomeStep> _steps = const [
    _WelcomeStep(
      icon: Icons.shield_rounded,
      title: 'Welcome to FileFortress',
      description:
          'Your private photos, videos, and documents are protected with strong encryption.',
    ),
    _WelcomeStep(
      icon: Icons.lock_rounded,
      title: 'Choose your security',
      description:
          'Pick a login method that fits you: PIN, Password, or Pattern.',
    ),
    _WelcomeStep(
      icon: Icons.verified_user_rounded,
      title: 'Stay in control',
      description: 'Unlock quickly and keep your vault secure across sessions.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'onboarding_seen', value: 'true');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.setupAuth);
  }

  void _nextPage() {
    if (_currentPage >= _steps.length - 1) {
      _finishOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: AppTheme.transitionDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 680;
            final topSpacing =
                isCompact ? AppTheme.largeSpacing : AppTheme.extraLargeSpacing;
            final iconSize = isCompact ? 56.0 : 72.0;
            final titleStyle = AppTheme.displayMedium.copyWith(
              fontSize: isCompact ? 28 : 34,
              color: colorScheme.onBackground,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
                vertical: AppTheme.largeSpacing,
              ),
              child: Column(
                children: [
                  SizedBox(height: topSpacing),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeInScale(
                              duration: AppTheme.transitionDuration,
                              child: Container(
                                padding: const EdgeInsets.all(
                                    AppTheme.mediumSpacing),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.primary.withOpacity(0.15),
                                      colorScheme.primary.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  step.icon,
                                  size: iconSize,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.largeSpacing),
                            FadeInUp(
                              delayMs: 80,
                              child: Text(
                                step.title,
                                style: titleStyle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppTheme.standardSpacing),
                            FadeInUp(
                              delayMs: 140,
                              child: Text(
                                step.description,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.largeSpacing),
                  _buildIndicators(colorScheme),
                  const SizedBox(height: AppTheme.largeSpacing),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: const Text('Skip'),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _nextPage,
                          icon: Icon(_currentPage >= _steps.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded),
                          label: Text(
                            _currentPage >= _steps.length - 1
                                ? 'Get Started'
                                : 'Next',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIndicators(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _steps.length,
        (index) => AnimatedContainer(
          duration: AppTheme.microAnimationDuration,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 8,
          width: _currentPage == index ? 20 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep {
  final IconData icon;
  final String title;
  final String description;

  const _WelcomeStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
