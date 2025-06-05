// c:\Users\progr\AndroidStudioProjects\meal_mapper\lib\components\admin_challenge_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class AdminChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final int rewardPoints;
  final String difficulty;
  final String deadline; // Assuming deadline is a String in ISO format
  final int challengeId; // Not displayed, but needed for updates
  final VoidCallback onUpdate;

  const AdminChallengeCard({
    Key? key,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.difficulty,
    required this.deadline,
    required this.challengeId,
    required this.onUpdate,
  }) : super(key: key);

  String _formatDeadline(String deadlineString) {
    try {
      final DateTime parsedDate = DateTime.parse(deadlineString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(parsedDate);
    } catch (e) {
      return deadlineString; // Return original if parsing fails
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade400;
      case 'medium':
        return Colors.orange.shade400;
      case 'hard':
        return Colors.red.shade400;
      case 'expert':
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.sentiment_satisfied_alt;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_very_dissatisfied;
      case 'expert':
        return Icons.star;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade50,
              Colors.teal.shade100.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    icon: Icons.star_border_purple500_outlined,
                    label: '$rewardPoints Points',
                    color: Colors.amber.shade700,
                  ),
                  _buildInfoChip(
                    icon: _getDifficultyIcon(difficulty),
                    label: difficulty.toUpperCase(),
                    color: _getDifficultyColor(difficulty),
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.grey.shade700, size: 20),
                  const SizedBox(width: 8.0),
                  Text(
                    'Deadline: ${_formatDeadline(deadline)}',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note_outlined, size: 20),
                  label: const Text('Update Challenge'),
                  onPressed: onUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color, bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
