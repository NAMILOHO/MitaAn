import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← Import ajouté

import '../utils/app_colors.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.location_on,
      title: 'Services près de vous',
      description: 'MitaAn connecte les professionnels locaux\navec les clients de leur quartier.',
      color: const Color(0xFF1D9E75),
    ),
    _OnboardingData(
      icon: Icons.store,
      title: 'Vendez facilement',
      description: 'Publiez vos produits et services en quelques\nsecondes et touchez des clients locaux.',
      color: const Color(0xFF1976D2),
    ),
    _OnboardingData(
      icon: Icons.chat_bubble_outline,
      title: 'Contactez directement',
      description: 'Discutez via la messagerie intégrée\nou contactez par WhatsApp en un clic.',
      color: const Color(0xFF388E3C),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Bouton passer
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => _goToLogin(),
                child: const Text(
                  'Passer',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // Indicateurs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Boutons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _goToRegister();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Suivant' : 'Commencer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lien connexion
                  GestureDetector(
                    onTap: _goToLogin,
                    child: RichText(
                      text: const TextSpan(
                        text: 'Déjà un compte ? ',
                        style: TextStyle(color: AppColors.grey),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 76,
              color: data.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.greyDark,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ====================== MÉTHODES MISES À JOUR ======================
  void _goToRegister() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}