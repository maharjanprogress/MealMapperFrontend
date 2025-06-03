// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_service.dart';
import 'see_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // final bool _isEditing = false; //todo: if any error occurs then uncomment this

  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _nutritionHistory = [];
  List<Map<String, dynamic>> _macroData = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final username = prefs.getString('username');
      final email = prefs.getString('email');
      final httpService = HttpService();
      final response = await httpService.get('profile/$userId'); // Replace with actual user ID
      final data = response.data;

      if (data['code'] == 200) {
        final details = data['details'];

        // Initialize user data
        _userData = {
          'name': username, // Add these from auth data
          'email': email, // Add these from auth data
          'username': username, // Add these from auth data
          'age': details['personal_info']['age'],
          'gender': details['personal_info']['gender'] == 1 ? 'Male' : 'Female',
          'height': details['personal_info']['height_cm'],
          'weight': details['personal_info']['weight_kg'],
          'activity_level': _getActivityLevel(details['personal_info']['activity_level']),
          'goal': _getGoal(details['personal_info']['goal']),
          'dietary_pref': details['personal_info']['dietary_pref'],
          'allergies': List<String>.from(details['personal_info']['allergies']),
          'medical_conditions': List<String>.from(details['personal_info']['medical_conditions']),
          'meal_times': details['personal_info']['meal_times'],
          'address': details['personal_info']['address'],
          'points': details['achievements']['season_points'],
          'completed_challenges': details['achievements']['completed_challenges'],
        };

        // Initialize nutrition history
        final weeklyCalories = details['weekly_calories'] as Map<String, dynamic>;
        _nutritionHistory = weeklyCalories.entries.map((entry) {
          return {
            'date': _formatDate(entry.key),
            'calories': entry.value,
            'target': 2200.0, // Add your target calculation here
          };
        }).toList();

        // Initialize macro data
        final macros = details['today_macros'];
        double totalMacros = macros['protein'] + macros['carbs'] + macros['fat'];
        _macroData = [
          {'name': 'Protein', 'value': _calculatePercentage(macros['protein'],totalMacros), 'target': 100, 'color': Colors.blue},
          {'name': 'Carbs', 'value': _calculatePercentage(macros['carbs'],totalMacros), 'target': 100, 'color': Colors.green},
          {'name': 'Fat', 'value': _calculatePercentage(macros['fat'],totalMacros), 'target': 100, 'color': Colors.orange},
        ];
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekDays[date.weekday - 1]; // weekday is 1-7 where 1 is Monday
  }

  String _getActivityLevel(int level) {
    switch (level) {
      case -1: return 'Sedentary';
      case 0: return 'Moderate';
      case 1: return 'Active';
      default: return 'Not Set';
    }
  }

  String _getGoal(int goal) {
    switch (goal) {
      case -1: return 'Lose Weight';
      case 0: return 'Maintain';
      case 1: return 'Gain Weight';
      default: return 'Not Set';
    }
  }

  int _calculatePercentage(double value,double totalMacros) {
    // Get total of all macros from today_macros

    // Calculate percentage
    if (totalMacros == 0) return 0;
    return ((value / totalMacros) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.teal,
          ),
        ),
      );
    }

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SeeDetailsScreen()),
                    );
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
    double maxY = _nutritionHistory.map((e) => e['calories'] as double).reduce((a, b) => a > b ? a : b)+ 500;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${_nutritionHistory[groupIndex]['calories'].toStringAsFixed(1)} kcal',
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
                  if (value == maxY / 2) return Text('${(maxY / 2).toStringAsFixed(0)}');
                  if (value == maxY) return Text('${maxY.toStringAsFixed(0)}');
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
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: _nutritionHistory.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> data = entry.value;
            double calories = data['calories'] as double;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: calories,
                  gradient: LinearGradient(
                    colors: calories > data['target']
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