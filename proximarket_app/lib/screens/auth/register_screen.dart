import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/phone_country_picker.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  CountryCode _selectedCountry = kCountryCodes.first;

  static const Color _primary = Color(0xFF1D9E75);
  static const Color _primaryDark = Color(0xFF085041);
  static const Color _bg = Color(0xFFF8FAF9);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _success = Color(0xFF16A34A);

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── FORCE DU MOT DE PASSE ──
  int get _passwordStrength {
    final v = _passwordController.text;
    int score = 0;
    if (v.length >= 6) score++;
    if (v.length >= 10) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    return score.clamp(0, 4);
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return 'Faible';
      case 2:
        return 'Moyen';
      case 3:
        return 'Bon';
      default:
        return 'Excellent';
    }
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return _danger;
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return _primary;
      default:
        return _success;
    }
  }

  // ====================== INSCRIPTION (logique préservée) ======================
  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      setState(() => _showTermsError = true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    setState(() => _isLoading = true);

    final success = await authProvider.signUp(
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : '${_selectedCountry.dial.replaceAll('+', '')}${_phoneController.text.trim()}@mitaan.app',
      password: _passwordController.text.trim(),
      nom: _nomController.text.trim(),
      phone: '${_selectedCountry.dial}${_phoneController.text.trim()}',
      isPro: false,
      categorie: '',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Erreur lors de l\'inscription',
          ),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Erreur Google'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
  // ================================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── FLÈCHE RETOUR ──
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // ── ILLUSTRATION ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2C2A3D), Color(0xFF5A4A6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              size: 30,
                              color: _primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── TITRE ──
                const Center(
                  child: Text(
                    'Créez votre compte',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Rejoignez la communauté MitaAn pour\ncommencer à vendre ou acheter localement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _textGrey,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // ── PRÉNOM ET NOM ──
                _fieldLabel('Prénom et nom'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _nomController,
                  hint: 'Ex: Coulibaly Kangui',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ce champ est requis' : null,
                ),
                const SizedBox(height: 18),

                // ── TÉLÉPHONE ──
                _fieldLabel('Numéro de téléphone'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhoneCountryPicker(
                      selected: _selectedCountry,
                      onChanged: (country) =>
                          setState(() => _selectedCountry = country),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildField(
                        controller: _phoneController,
                        hint: '07 •• •• •• ••',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) => (value == null || value.length < 8)
                            ? 'Numéro invalide'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── E-MAIL (FACULTATIF) ──
                Row(
                  children: [
                    _fieldLabel('Adresse e-mail'),
                    const SizedBox(width: 6),
                    Text(
                      '(facultatif)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _textGrey.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildField(
                  controller: _emailController,
                  hint: 'votre@email.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── MOT DE PASSE ──
                _fieldLabel('Mot de passe'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_passwordVisible,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: _textGrey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mot de passe requis';
                    }
                    if (value.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // ── INDICATEUR DE FORCE ──
                if (_passwordController.text.isNotEmpty) ...[
                  Row(
                    children: List.generate(4, (i) {
                      final active = i < _passwordStrength;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: active
                                ? _strengthColor
                                : _border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _passwordStrength >= 3
                            ? Icons.shield_rounded
                            : Icons.info_outline_rounded,
                        size: 13,
                        color: _strengthColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sécurité du mot de passe : $_strengthLabel',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _strengthColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    'Au moins 6 caractères, avec chiffres et majuscules.',
                    style: TextStyle(fontSize: 11.5, color: _textGrey),
                  ),
                const SizedBox(height: 20),

                // ── CASE À COCHER CGU ──
                GestureDetector(
                  onTap: () => setState(() {
                    _acceptedTerms = !_acceptedTerms;
                    if (_acceptedTerms) _showTermsError = false;
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _acceptedTerms ? _primary : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _acceptedTerms
                                ? _primary
                                : (_showTermsError ? _danger : _border),
                            width: 1.4,
                          ),
                        ),
                        child: _acceptedTerms
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12.5, color: _textGrey, height: 1.4),
                            children: const [
                              TextSpan(text: 'J\'accepte les '),
                              TextSpan(
                                text: 'conditions d\'utilisation',
                                style: TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' et la '),
                              TextSpan(
                                text: 'politique de confidentialité',
                                style: TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showTermsError) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Veuillez accepter les conditions pour continuer',
                    style: TextStyle(fontSize: 11.5, color: _danger),
                  ),
                ],
                const SizedBox(height: 24),

                // ── BOUTON CRÉER MON COMPTE ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _primary.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Créer mon compte',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 22),

                // ── SÉPARATEUR ──
                Row(
                  children: [
                    Expanded(child: Divider(color: _border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OU CONTINUER AVEC',
                        style: TextStyle(
                          color: _textGrey.withValues(alpha: 0.7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: _border)),
                  ],
                ),
                const SizedBox(height: 22),

                // ── BOUTON GOOGLE ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _registerWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _border, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF3F4F6),
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // ── LIEN CONNEXION ──
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Vous avez déjà un compte ? ',
                        style: TextStyle(color: _textGrey, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 12,
                        color: _textGrey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Connexion sécurisée',
                        style: TextStyle(
                          color: _textGrey.withValues(alpha: 0.5),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14.5, color: _textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textGrey.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: _textGrey, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _danger, width: 1.2),
        ),
      ),
    );
  }
}