import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'http_service.dart';
import 'package:intl/intl.dart';

class SeeDetailsScreen extends StatefulWidget {
  const SeeDetailsScreen({Key? key}) : super(key: key);

  @override
  State<SeeDetailsScreen> createState() => _SeeDetailsScreenState();
}

class _SeeDetailsScreenState extends State<SeeDetailsScreen> {
  bool _isLoading = true;
  Map<DateTime, List<Map<String, dynamic>>> _foodEvents = {};
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int _monthsBack = 0;
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchFoodData();
  }

  Future<void> _fetchFoodData([int? monthsBack]) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      // Use provided monthsBack or current _monthsBack
      final months = monthsBack ?? _monthsBack;
      print('Fetching data for userId: $userId, months back: $months');

      final response = await HttpService().get('scanned_details/$userId/$months');
      print('API Response: ${response.data}');

      if (response.data['code'] == 200) {
        final details = List<Map<String, dynamic>>.from(response.data['details']);
        print('Details: $details');

        _foodEvents = {};
        for (var dayData in details) {
          try {
            final date = DateTime.parse(dayData['date']);
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final foodItems = List<Map<String, dynamic>>.from(dayData['food_details']);
            _foodEvents[normalizedDate] = foodItems;
          } catch (e) {
            print('Error processing date ${dayData['date']}: $e');
          }
        }
        print('Processed food events: $_foodEvents');
      }
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Food History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildCalendar(),
          const Divider(height: 1),
          Expanded(
            child: _buildFoodList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now(),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: CalendarFormat.month,
      eventLoader: (day) {
        final events = _foodEvents[DateTime(day.year, day.month, day.day)] ?? [];
        print('Checking events for $day: ${events.length}');
        return events;
      },
      calendarStyle: CalendarStyle(
        markerDecoration: const BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.teal.shade200,
          shape: BoxShape.circle,
        ),
      ),
      onPageChanged: (focusedDay) {
        // Calculate months difference
        final now = DateTime.now();
        final monthsDiff = (now.year - focusedDay.year) * 12 +
            (now.month - focusedDay.month);
        _monthsBack = monthsDiff;
        _focusedDay = focusedDay;
        _fetchFoodData(monthsDiff);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
    );
  }

  Widget _buildFoodList() {
    final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final foodItems = _foodEvents[selectedDate] ?? [];

    if (foodItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_food, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isSameDay(_selectedDay, DateTime.now())
                  ? 'No food data recorded today'
                  : 'No food data recorded on ${DateFormat('MMM dd, yyyy').format(_selectedDay)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        final food = foodItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getMealTypeColor(food['meal_type']),
              child: Text(
                food['meal_type'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(food['name']),
            subtitle: Text(
              '${food['category']} • ${_timeFormat.format(DateFormat('HH:mm').parse(food['scanned_at']))}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${food['calories'].toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${food['servings']} serving${food['servings'] > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            onTap: () => _showFoodDetails(food),
          ),
        );
      },
    );
  }

  void _showFoodDetails(Map<String, dynamic> food) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              food['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutrientRow('Calories', '${food['calories']} kcal'),
            _buildNutrientRow('Protein', '${food['protein']}g'),
            _buildNutrientRow('Carbs', '${food['carbs']}g'),
            _buildNutrientRow('Fat', '${food['fat']}g'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category: ${food['category']}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Meal: ${food['meal_type'].toString().toUpperCase()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}