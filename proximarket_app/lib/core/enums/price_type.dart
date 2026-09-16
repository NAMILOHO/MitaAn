enum PriceType { fixed, startingAt, negotiable, free, onQuote, contactSeller }

extension PriceTypeExt on PriceType {
  String get label {
    switch (this) {
      case PriceType.fixed:
        return 'Prix fixe';
      case PriceType.startingAt:
        return 'À partir de';
      case PriceType.negotiable:
        return 'Négociable';
      case PriceType.free:
        return 'Gratuit';
      case PriceType.onQuote:
        return 'Sur devis';
      case PriceType.contactSeller:
        return 'Contacter le vendeur';
    }
  }

  /// true si le champ numérique `prix` doit être affiché/saisi
  bool get needsAmount =>
      this == PriceType.fixed ||
      this == PriceType.startingAt ||
      this == PriceType.negotiable;

  String get firestoreKey => name;

  static PriceType fromString(String? value) {
    return PriceType.values.firstWhere(
      (p) => p.name == value,
      orElse: () => PriceType.fixed,
    );
  }

  /// Formatte le prix pour affichage sur l'affiche/carte
  String format(double amount, {String unite = ''}) {
    final uniteSuffix =
        (unite.isNotEmpty && unite != 'forfait') ? ' / $unite' : '';
    switch (this) {
      case PriceType.fixed:
        return '${amount.toStringAsFixed(0)} FCFA$uniteSuffix';
      case PriceType.startingAt:
        return 'À partir de ${amount.toStringAsFixed(0)} FCFA';
      case PriceType.negotiable:
        return '${amount.toStringAsFixed(0)} FCFA — négociable';
      case PriceType.free:
        return 'Gratuit';
      case PriceType.onQuote:
        return 'Sur devis';
      case PriceType.contactSeller:
        return 'Contacter le vendeur';
    }
  }
}
