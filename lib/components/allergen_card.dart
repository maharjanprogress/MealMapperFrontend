import 'package:flutter/material.dart';

class AllergenCard extends StatelessWidget {
  final String name;
  final String description;
  final List<String> associatedIngredients;
  final VoidCallback onUpdate;

  const AllergenCard({
    Key? key,
    required this.name,
    required this.description,
    required this.associatedIngredients,
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
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
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
            const SizedBox(height: 12.0),
            Text(
              description,
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            if (associatedIngredients.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              Text(
                'Associated Ingredients:',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 6.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: associatedIngredients.map((ingredient) {
                  return Chip(
                    label: Text(ingredient),
                    backgroundColor: Colors.teal.shade50,
                    labelStyle: TextStyle(color: Colors.teal.shade700, fontSize: 13),
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
                  backgroundColor: Colors.teal.shade600,
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
