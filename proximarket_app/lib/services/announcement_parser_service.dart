import '../core/enums/announcement_category.dart';

/// Résultat de la structuration automatique d'une description libre.
/// Rule-based pour l'instant — interface stable pour brancher une vraie IA plus tard
/// sans changer les appelants (voir §5 du brief refonte).
class ParsedAnnouncementDraft {
  final String suggestedTitle;
  final AnnouncementCategory? suggestedCategory;
  final double? suggestedPrice;
  final String? suggestedCity;
  final Map<String, String> suggestedAttributes;

  const ParsedAnnouncementDraft({
    required this.suggestedTitle,
    this.suggestedCategory,
    this.suggestedPrice,
    this.suggestedCity,
    this.suggestedAttributes = const {},
  });
}

class AnnouncementParserService {
  AnnouncementParserService._();

  static const List<String> _knownCities = [
    'Cocody',
    'Yopougon',
    'Angré',
    'Marcory',
    'Treichville',
    'Plateau',
    'Abobo',
    'Adjamé',
    'Koumassi',
    'Port-Bouët',
    'Bingerville',
    'Bouaké',
    'Yamoussoukro',
    'San Pédro',
    'Korhogo',
    'Daloa',
  ];

  static const Map<AnnouncementCategory, List<String>> _categoryKeywords = {
    AnnouncementCategory.immobilier: [
      'appartement',
      'maison',
      'terrain',
      'villa',
      'studio',
      'louer',
      'location',
      'chambre',
      'salon',
      'duplex',
      'immeuble',
      'bureau à louer',
    ],
    AnnouncementCategory.vehicule: [
      'voiture',
      'moto',
      'véhicule',
      'camion',
      'scooter',
      'auto',
      'occasion',
    ],
    AnnouncementCategory.agriculture: [
      'poulet',
      'élevage',
      'ferme',
      'agricole',
      'poisson',
      'culture',
      'récolte',
      'bétail',
      'volaille',
    ],
    AnnouncementCategory.emploi: [
      'recrute',
      'emploi',
      'poste',
      'cdi',
      'cdd',
      'stage',
      'recherche employé',
    ],
    AnnouncementCategory.evenement: [
      'événement',
      'mariage',
      'anniversaire',
      'concert',
      'soirée',
      'fête',
    ],
    AnnouncementCategory.service: [
      'coiffure',
      'ménage',
      'cours',
      'répétition',
      'livraison',
      'réparation',
      'plomberie',
      'électricité',
      'coaching',
      'consultation',
    ],
    AnnouncementCategory.produit: [
      'téléphone',
      'vêtement',
      'meuble',
      'électroménager',
      'ordinateur',
      'à vendre',
    ],
  };

  static ParsedAnnouncementDraft parse(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return const ParsedAnnouncementDraft(suggestedTitle: '');
    }

    final lower = text.toLowerCase();

    // Titre : première phrase, ou 80 premiers caractères.
    final firstSentence = text.split(RegExp(r'[.\n]')).first.trim();
    final title = firstSentence.length > 80
        ? '${firstSentence.substring(0, 80)}…'
        : firstSentence;

    // Catégorie : scoring par mots-clés.
    AnnouncementCategory? bestCategory;
    int bestScore = 0;
    for (final entry in _categoryKeywords.entries) {
      final score = entry.value.where((kw) => lower.contains(kw)).length;
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }

    // Prix : nombre suivi de FCFA / F CFA / francs.
    double? price;
    final priceMatch = RegExp(
      r'(\d[\d\s.]{2,})\s*(fcfa|f\s?cfa|francs?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (priceMatch != null) {
      final digits = priceMatch.group(1)!.replaceAll(RegExp(r'[\s.]'), '');
      price = double.tryParse(digits);
    }

    // Ville : recherche dans la liste connue.
    String? city;
    for (final c in _knownCities) {
      if (lower.contains(c.toLowerCase())) {
        city = c;
        break;
      }
    }

    // Attributs simples : "N chambres", "N salles de bain", "N pièces".
    final attributes = <String, String>{};
    final roomsMatch =
        RegExp(r'(\d+)\s*(chambres?|pièces?)', caseSensitive: false)
            .firstMatch(text);
    if (roomsMatch != null) {
      attributes['Chambres'] = roomsMatch.group(1)!;
    }
    final bathMatch =
        RegExp(r'(\d+)\s*salles?\s*de\s*bain', caseSensitive: false)
            .firstMatch(text);
    if (bathMatch != null) {
      attributes['Salles de bain'] = bathMatch.group(1)!;
    }
    if (lower.contains('parking')) {
      attributes['Parking'] = 'Oui';
    }
    if (lower.contains('meublé')) {
      attributes['Meublé'] = 'Oui';
    }

    return ParsedAnnouncementDraft(
      suggestedTitle: title,
      suggestedCategory: bestCategory,
      suggestedPrice: price,
      suggestedCity: city,
      suggestedAttributes: attributes,
    );
  }
}
