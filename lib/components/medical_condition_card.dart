import 'package:flutter/material.dart';

class MedicalConditionCard extends StatelessWidget {
  final String name;
  final List<String> descriptions;
  final VoidCallback onUpdate; // Callback for the update button

  const MedicalConditionCard({
    Key? key,
    required this.name,
    required this.descriptions,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // Use Expanded to prevent overflow if name is long
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Handle long names
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                  tooltip: 'Update Medical Condition',
                  onPressed: onUpdate,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (descriptions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guidelines:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true, // Important for nested ListViews
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this list
                    itemCount: descriptions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.teal.shade400),
                            const SizedBox(width: 8),
                            Expanded( // Ensure description text wraps
                              child: Text(
                                descriptions[index],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )
            else
              Text(
                'No guidelines available.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}