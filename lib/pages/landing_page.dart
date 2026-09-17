import 'package:flutter/material.dart';

import 'login_page.dart';
import 'register_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({
    super.key,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  static const List<_LandingSlide> _slides = [
    _LandingSlide(
      icon: Icons.water_drop_rounded,
      title: 'Track Your Sodium Intake',
      subtitle:
          'Keep track of your daily sodium intake and see how much remains in your target.',
    ),
    _LandingSlide(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Scan Food Barcodes',
      subtitle:
          'Scan packaged foods to check sodium information before adding them to your food log.',
    ),
    _LandingSlide(
      icon: Icons.favorite_rounded,
      title: 'Monitor Blood Pressure',
      subtitle:
          'Record your blood pressure and review your readings and trends over time.',
    ),
  ];

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    await _pageController.nextPage(
      duration: const Duration(
        milliseconds: 250,
      ),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skipToLastPage() async {
    await _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(
        milliseconds: 250,
      ),
      curve: Curves.easeInOut,
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    if (!_isLastPage)
                      TextButton(
                        onPressed: _skipToLastPage,
                        child: const Text(
                          'Skip',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (
                  context,
                  index,
                ) {
                  final slide = _slides[index];

                  return LayoutBuilder(
                    builder: (
                      context,
                      constraints,
                    ) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 24,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 116,
                                height: 116,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 58,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Text(
                                slide.subtitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Semantics(
              label: 'Page ${_currentPage + 1} of ${_slides.length}',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) {
                    final selected = _currentPage == index;

                    return AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 200,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      width: selected ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            selected ? colors.primary : colors.outlineVariant,
                        borderRadius: BorderRadius.circular(
                          999,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                24,
                22,
                22,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 200,
                ),
                child: _isLastPage
                    ? Column(
                        key: const ValueKey(
                          'account-actions',
                        ),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openLogin,
                            icon: const Icon(
                              Icons.login_rounded,
                            ),
                            label: const Text(
                              'Log In',
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          OutlinedButton.icon(
                            onPressed: _openRegister,
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                            ),
                            label: const Text(
                              'Create Account',
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        key: const ValueKey(
                          'next-action',
                        ),
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _nextPage,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                          ),
                          label: const Text(
                            'Next',
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingSlide {
  const _LandingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
