// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bool _isEditing = false;

  // Mock user data
  final Map<String, dynamic> _userData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'username': 'johndoe',
    'age': 28,
    'gender': 'Male',
    'height': 175.0,
    'weight': 70.0,
    'activity_level': 'Moderate',
    'goal': 'Maintain',
    'dietary_pref': 'None',
    'allergies': ['Nuts', 'Shellfish'],
    'medical_conditions': ['None'],
    'meal_times': {
      'breakfast': '08:00',
      'lunch': '13:00',
      'dinner': '19:00',
    },
    'address': '123 Main St, Anytown, USA',
    'points': 750,
    'achievements': 8,
    'completed_challenges': 12,
    'longest_streak': 14,
  };

  // Mock nutrition data
  final List<Map<String, dynamic>> _nutritionHistory = [
    {'date': 'Mon', 'calories': 2100, 'target': 2200},
    {'date': 'Tue', 'calories': 2300, 'target': 2200},
    {'date': 'Wed', 'calories': 1950, 'target': 2200},
    {'date': 'Thu', 'calories': 90, 'target': 2200},
    {'date': 'Fri', 'calories': 2050, 'target': 2200},
    {'date': 'Sat', 'calories': 2250, 'target': 2200},
    {'date': 'Sun', 'calories': 2150, 'target': 2200},
  ];

  final List<Map<String, dynamic>> _macroData = [
    {'name': 'Protein', 'value': 28, 'target': 30, 'color': Colors.blue},
    {'name': 'Carbs', 'value': 52, 'target': 50, 'color': Colors.green},
    {'name': 'Fat', 'value': 20, 'target': 20, 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildStatsCards(),
            const SizedBox(height: 20),
            _buildNutritionSection(),
            const SizedBox(height: 20),
            _buildPersonalInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.teal,
              child: Text(
                _userData['name'].split(' ').map((e) => e[0]).join(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userData['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_userData['username']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 0),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Implement edit profile
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Points', _userData['points'].toString(), Icons.stars, Colors.amber),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Achievements', _userData['achievements'].toString(), Icons.emoji_events, Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Challenges', _userData['completed_challenges'].toString(), Icons.flag, Colors.green),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nutrition Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to detailed nutrition page
                  },
                  child: const Text('See Details'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'This Week\'s Calories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 180,
              child: _buildCaloriesChart(),
            ),
            const Divider(height: 32),
            const Text(
              'Today\'s Macros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: _buildMacrosChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesChart() {
    // Calculate maxY dynamically based on the highest calories value
    double maxY = _nutritionHistory.map((e) => e['calories'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 500;

    return SizedBox(
      height: 200, // Ensure enough height for the chart
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY, // Use dynamic maxY
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${_nutritionHistory[groupIndex]['calories']} kcal',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < _nutritionHistory.length) {
                    return Text(
                      _nutritionHistory[index]['date'],
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('0');
                  if (value == maxY / 2) return Text('${(maxY / 2).toInt()}');
                  if (value == maxY) return Text('${maxY.toInt()}');
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: maxY / 4, // Adjust interval for better readability
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 3,
              );
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: _nutritionHistory.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> data = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data['calories'].toDouble(),
                  gradient: LinearGradient(
                    colors: data['calories'] > data['target']
                        ? [Colors.teal, Colors.tealAccent]
                        : [Colors.red, Colors.redAccent],
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMacrosChart() {
    return Wrap(
      spacing: 16, // Space between items horizontally
      runSpacing: 16, // Space between items vertically
      children: _macroData.map((macro) {
        double percentage = (macro['value'] / macro['target']) * 100;
        return SizedBox(
          width: 100, // Ensure each item has a fixed width
          child: Column(
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        height: 80,
                        width: 80,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(macro['color']),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${macro['value']}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                macro['name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${macro['value']}% of ${macro['target']}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  onPressed: () {
                    // TODO: Implement edit personal info
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Age', _userData['age'].toString()),
            _buildInfoRow('Gender', _userData['gender']),
            _buildInfoRow('Height', '${_userData['height']} cm'),
            _buildInfoRow('Weight', '${_userData['weight']} kg'),
            _buildInfoRow('Activity Level', _userData['activity_level']),
            _buildInfoRow('Goal', _userData['goal']),
            _buildInfoRow('Dietary Preference', _userData['dietary_pref']),
            _buildInfoRow('Allergies', _userData['allergies'].join(', ')),
            _buildInfoRow('Medical Conditions', _userData['medical_conditions'].join(', ')),
            _buildInfoRow('Breakfast Time', _userData['meal_times']['breakfast']),
            _buildInfoRow('Lunch Time', _userData['meal_times']['lunch']),
            _buildInfoRow('Dinner Time', _userData['meal_times']['dinner']),
            _buildInfoRow('Address', _userData['address']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}