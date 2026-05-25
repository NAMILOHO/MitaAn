import 'package:flutter/material.dart';

class CountryCode {
  final String flag;
  final String name;
  final String dial;

  const CountryCode({
    required this.flag,
    required this.name,
    required this.dial,
  });
}

const List<CountryCode> kCountryCodes = [
  CountryCode(flag: '🇨🇮', name: 'Côte d\'Ivoire', dial: '+225'),
  CountryCode(flag: '🇲🇱', name: 'Mali', dial: '+223'),
  CountryCode(flag: '🇸🇳', name: 'Sénégal', dial: '+221'),
  CountryCode(flag: '🇧🇫', name: 'Burkina Faso', dial: '+226'),
  CountryCode(flag: '🇬🇳', name: 'Guinée', dial: '+224'),
  CountryCode(flag: '🇳🇬', name: 'Nigeria', dial: '+234'),
  CountryCode(flag: '🇬🇭', name: 'Ghana', dial: '+233'),
];

class PhoneCountryPicker extends StatelessWidget {
  final CountryCode selected;
  final ValueChanged<CountryCode> onChanged;

  const PhoneCountryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text(
              selected.dial,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: kCountryCodes.length,
        itemBuilder: (context, i) {
          final country = kCountryCodes[i];
          return ListTile(
            leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
            title: Text(country.name),
            trailing: Text(
              country.dial,
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.pop(context);
              onChanged(country);
            },
          );
        },
      ),
    );
  }
}
