import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _primary = Color(0xFF1D9E75);
  static const Color _primaryDark = Color(0xFF085041);
  static const Color _bg = Color(0xFFF8FAF9);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Découvrez ce qui\nvous entoure',
      description:
          'Trouvez facilement des produits, services, logements, véhicules et opportunités près de vous.',
      icon: Icons.explore_rounded,
      gradientColors: const [Color(0xFF2D3436), Color(0xFF485563)],
    ),
    _OnboardingData(
      title: 'Publiez ce que\nvous voulez',
      description:
          'Vendez, proposez, louez ou partagez une annonce en quelques secondes seulement.',
      icon: Icons.add_photo_alternate_rounded,
      gradientColors: const [Color(0xFFE8F5F0), Color(0xFFD4EDE4)],
      isLight: true,
      accentTitle: 'vous voulez',
    ),
    _OnboardingData(
      title: 'Connectez-vous\nfacilement',
      description:
          'Contactez directement les personnes qui proposent ce que vous recherchez, sans intermédiaires.',
      icon: Icons.handshake_rounded,
      gradientColors: const [Color(0xFFDCC6A8), Color(0xFFC9A876)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }

  void _goToRegister() async {
    await _finishOnboarding();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToLogin() async {
    await _finishOnboarding();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onContinue() {
    if (_isLastPage) {
      _goToRegister();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── BOUTON PASSER ──
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 4),
                child: TextButton(
                  onPressed: _goToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: _textGrey,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Passer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            // ── PAGES ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // ── INDICATEURS + CTA ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? _primary
                              : _primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLastPage ? 'Commencer' : 'Continuer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MITAAN — MARKETPLACE LOCALE CI',
                    style: TextStyle(
                      color: _textGrey.withValues(alpha: 0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ILLUSTRATION ──
          // 👉 Point d'extension : remplace ce Container par
          // Image.asset('assets/images/onboarding_X.jpg') si tu ajoutes
          // les vraies photos du design Visily dans les assets.
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: data.isLight ? 0.9 : 0.15,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      size: 46,
                      color: data.isLight ? _primary : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── TITRE ──
          _buildTitle(data),

          const SizedBox(height: 12),

          // ── DESCRIPTION ──
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 14,
              color: _textGrey,
              height: 1.55,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTitle(_OnboardingData data) {
    if (data.accentTitle == null) {
      return Text(
        data.title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: _textDark,
          height: 1.25,
        ),
      );
    }

    // Titre avec un mot accentué en vert (écran 2 du design)
    final parts = data.title.split('\n');
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: _textDark,
          height: 1.25,
        ),
        children: [
          TextSpan(text: '${parts.first}\n'),
          TextSpan(
            text: parts.length > 1 ? parts[1] : '',
            style: const TextStyle(color: _primaryDark),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isLight;
  final String? accentTitle;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    this.isLight = false,
    this.accentTitle,
  });
}