import 'package:flutter/material.dart';

class ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final double? progress; // For active challenges
  final int? daysLeft; // For active challenges
  final String? difficulty; // For available challenges
  final int points;
  final String? duration; // For available challenges
  final String? completedOn; // For completed challenges
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const ChallengeCard.active({
    Key? key,
    required this.title,
    required this.description,
    required this.progress,
    required this.daysLeft,
    required this.points,
    this.onTap,
  })  : difficulty = null,
        duration = null,
        completedOn = null,
        onJoin = null,
        super(key: key);

  const ChallengeCard.available({
    Key? key,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.points,
    required this.duration,
    this.onJoin,
  })  : progress = null,
        daysLeft = null,
        completedOn = null,
        onTap = null,
        super(key: key);

  const ChallengeCard.completed({
    Key? key,
    required this.title,
    required this.description,
    required this.completedOn,
    required this.points,
    this.onTap,
  })  : progress = null,
        daysLeft = null,
        difficulty = null,
        duration = null,
        onJoin = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              if (progress != null && daysLeft != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Days Left: $daysLeft',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      '$points Points',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.teal,
                ),
              ] else if (difficulty != null && duration != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Difficulty: $difficulty',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      '$points Points',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Duration: $duration',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onJoin,
                    child: const Text('Join'),
                  ),
                ),
              ] else if (completedOn != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed On: $completedOn',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '$points Points',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}