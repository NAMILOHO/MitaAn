import 'package:flutter/material.dart';

import '../../core/enums/announcement_category.dart';
import '../../services/announcement_parser_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/publish_step_indicator.dart';

class QuickPublishScreen extends StatefulWidget {
  const QuickPublishScreen({super.key});

  @override
  State<QuickPublishScreen> createState() => _QuickPublishScreenState();
}

class _QuickPublishScreenState extends State<QuickPublishScreen> {
  final _descController = TextEditingController();
  final _focusNode = FocusNode();
  AnnouncementCategory? _selectedCategory;

  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _descController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  bool get _canContinue => _descController.text.trim().isNotEmpty;

  void _continue() {
    final text = _descController.text.trim();
    final draft = AnnouncementParserService.parse(text);

    // La sélection manuelle de catégorie a priorité sur la détection automatique.
    final category =
        _selectedCategory ?? draft.suggestedCategory ?? AnnouncementCategory.autre;

    // TODO(écran suivant): naviguer vers ParsedPreviewScreen(draft: draft, category: category, rawText: text)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Catégorie détectée : ${category.label} — écran suivant à venir',
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            const PublishStepIndicator(currentStep: 0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nouvelle annonce ✨', style: AppTheme.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Décrivez ce que vous proposez,\nMitaAn s\'occupe du reste.',
                      style: AppTheme.body.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    _buildDescriptionField(),
                    const SizedBox(height: 28),
                    const Text(
                      'Ou choisissez une catégorie',
                      style: AppTheme.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Facultatif — MitaAn peut la détecter automatiquement',
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: 14),
                    _buildCategoryGrid(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: _focusNode.hasFocus ? AppTheme.primary : AppTheme.border,
          width: _focusNode.hasFocus ? 1.5 : 1,
        ),
        boxShadow: AppTheme.shadowSubtle,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qu\'avez-vous à proposer ?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              focusNode: _focusNode,
              maxLines: 6,
              minLines: 5,
              maxLength: _maxChars,
              textCapitalization: TextCapitalization.sentences,
              style: AppTheme.bodyL.copyWith(height: 1.5),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ex : Appartement 3 pièces à louer à Cocody '
                    'Angré, 250 000 FCFA/mois, 2 chambres, 2 salles '
                    'de bain et parking.',
                hintStyle: AppTheme.body.copyWith(
                  color: AppTheme.textTertiary,
                  height: 1.5,
                ),
                border: InputBorder.none,
                counterStyle: AppTheme.caption,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: AnnouncementCategory.values.length,
      itemBuilder: (context, i) {
        final cat = AnnouncementCategory.values[i];
        final selected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = selected ? null : cat),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cat.bgColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: selected ? cat.color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(cat.icon, color: cat.color, size: 24)),
                    if (selected)
                      Positioned(
                        top: 3,
                        right: 3,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: cat.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cat.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cat.color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: ElevatedButton(
        onPressed: _canContinue ? _continue : null,
        style: AppTheme.primaryButton,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Continuer'),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
