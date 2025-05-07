import 'package:flutter/material.dart';
import '../http_service.dart';

class FoodSearchDialog extends StatefulWidget {
  final Function(String name, String mealType, double servingSize) onConfirm;

  const FoodSearchDialog({Key? key, required this.onConfirm}) : super(key: key);

  @override
  _FoodSearchDialogState createState() => _FoodSearchDialogState();
}

class _FoodSearchDialogState extends State<FoodSearchDialog> {
  final HttpService _httpService = HttpService();
  String searchQuery = '';
  List<Map<String, dynamic>> foodResults = [];
  Map<String, dynamic>? selectedFood;
  bool isLoading = false;
  final _mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
  String selectedMealType = 'Breakfast';
  final TextEditingController _searchController = TextEditingController();
  bool _showResults = true;

  Future<void> fetchFoods(String query) async {
    print('Search query: $query'); // Debug print

    // Clear results if query is empty
    if (query.isEmpty) {
      setState(() {
        foodResults = [];
        isLoading = false;
      });
      print('Query empty, clearing results'); // Debug print
      return;
    }

    setState(() => isLoading = true);

    try {
      print('Sending request for: $query'); // Debug print
      final response = await _httpService.get('foods/$query');
      print('Response status code: ${response.statusCode}'); // Debug print
      print('Response data: ${response.data}'); // Debug print

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200) {
          setState(() {
            foodResults = List<Map<String, dynamic>>.from(data['details']);
            print('Results found: ${foodResults.length}'); // Debug print
          });
        } else {
          print('API error code: ${data['code']}'); // Debug print
          setState(() {
            foodResults = [];
          });
        }
      } else {
        print('HTTP error: ${response.statusCode}'); // Debug print
        setState(() {
          foodResults = [];
        });
      }
    } catch (e) {
      print('Exception caught: $e'); // Debug print
      setState(() {
        foodResults = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search Food',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Food Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  print('TextField value changed: $value'); // Debug print
                  setState(() {
                    searchQuery = value;
                    _showResults = true;
                  });
                  fetchFoods(value.trim()); // Added trim() to remove any whitespace
                },
              ),
              const SizedBox(height: 16),
              if (_showResults) // Only show results if _showResults is true
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : foodResults.isEmpty
                      ? const Center(
                    child: Text('Type to search for foods...'),
                  )
                      : ListView.builder(
                    itemCount: foodResults.length,
                    itemBuilder: (context, index) {
                      final food = foodResults[index];
                      final isSelected = selectedFood?['name'] == food['name'];
                      return Card(
                        color: isSelected ? Colors.teal.shade50 : null,
                        child: ListTile(
                          title: Text(food['name']),
                          subtitle: Text('${food['serving_size']}g per serving'),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.teal)
                              : null,
                          onTap: () {
                            setState(() {
                              selectedFood = food;
                              _searchController.text = food['name'];
                              _showResults = false; // Hide results after selection
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (!_showResults && selectedFood != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedMealType,
                  items: _mealTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMealType = value!;
                      selectedFood!['meal_type'] = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Serving Size (grams)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixText: 'gm',
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: selectedFood!['serving_size'].toString(),
                  ),
                  onChanged: (value) {
                    selectedFood!['serving_size'] = double.tryParse(value) ?? selectedFood!['serving_size'];
                  },
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selectedFood == null
                        ? null
                        : () {
                            widget.onConfirm(
                              selectedFood!['name'],
                              selectedFood!['meal_type'] ?? selectedMealType,
                              selectedFood!['serving_size'].toDouble(),
                            );
                            Navigator.of(context).pop();
                          },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}