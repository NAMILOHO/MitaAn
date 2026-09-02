import 'package:flutter/material.dart';

import '../core/enums/type_annonce.dart';

class AttributesInputField extends StatefulWidget {
  final TypeAnnonce typeAnnonce;
  final Map<String, String> attributs;
  final ValueChanged<Map<String, String>> onChanged;

  const AttributesInputField({
    super.key,
    required this.typeAnnonce,
    required this.attributs,
    required this.onChanged,
  });

  @override
  State<AttributesInputField> createState() => _AttributesInputFieldState();
}

class _AttributesInputFieldState extends State<AttributesInputField> {
  static const Color primary = Color(0xFF1D9E75);
  final _keyController = TextEditingController();

  void _addAttribute(String key) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return;

    final updated = Map<String, String>.from(widget.attributs);
    updated.putIfAbsent(normalizedKey, () => '');
    widget.onChanged(updated);
  }

  void _setValue(String key, String value) {
    final updated = Map<String, String>.from(widget.attributs);
    updated[key] = value;
    widget.onChanged(updated);
  }

  void _removeAttribute(String key) {
    final updated = Map<String, String>.from(widget.attributs)..remove(key);
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions =
        TypeAnnonceExt.suggestedFields[widget.typeAnnonce] ?? const <String>[];
    final remainingSuggestions =
        suggestions.where((s) => !widget.attributs.containsKey(s)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (remainingSuggestions.isNotEmpty) ...[
          const Text(
            'Suggestions',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: remainingSuggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.add, size: 14, color: primary),
                    onPressed: () => _addAttribute(s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        ...widget.attributs.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('attribute-${e.key}'),
                    initialValue: e.value,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Valeur',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (v) => _setValue(e.key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                  onPressed: () => _removeAttribute(e.key),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _keyController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Nom du champ personnalisé',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (value) {
                  _addAttribute(value);
                  _keyController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: primary),
              onPressed: () {
                _addAttribute(_keyController.text);
                _keyController.clear();
              },
            ),
          ],
        ),
      ],
    );
  }
}
