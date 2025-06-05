import 'package:flutter/material.dart';

class IngredientCard extends StatelessWidget {
  final String name;
  final List<String> associatedAllergens;
  final VoidCallback onUpdate;

  const IngredientCard({
    Key? key,
    required this.name,
    required this.associatedAllergens,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.kitchen_outlined, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (associatedAllergens.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              Text(
                'Associated Allergens:',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 6.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: associatedAllergens.map((allergen) {
                  return Chip(
                    label: Text(allergen),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: TextStyle(color: Colors.green.shade700, fontSize: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Update'),
                onPressed: onUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}