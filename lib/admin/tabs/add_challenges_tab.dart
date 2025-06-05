import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:intl/intl.dart'; // For date formatting
import '../../http_service.dart';
import '../../components/nutrient_challenge_card.dart';

class AddChallengesTab extends StatefulWidget {
  const AddChallengesTab({Key? key}) : super(key: key);

  @override
  _AddChallengesTabState createState() => _AddChallengesTabState();
}

class _AddChallengesTabState extends State<AddChallengesTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rewardPointsController = TextEditingController();

  String? _selectedDifficulty;
  DateTime? _selectedDeadline;

  final List<String> _difficultyOptions = ['easy', 'medium', 'hard', 'expert'];

  // State for the main "Set Nutrient Challenge" expansion panel
  bool _isNutrientChallengeExpanded = false;

  // State for individual nutrient panels (whether they are selected/expanded)
  final Map<String, bool> _nutrientPanelSelected = {
    'Protein': false,
    'Calories': false,
    'Carbs': false,
    'Fat': false,
    'Sugar': false,
    'Sodium': false,
  };

  // Map to hold the requirements data from each NutrientChallengeCard
  final Map<String, Map<String, dynamic>> _nutrientRequirements = {};

  bool _isSaving = false;
  final HttpService _httpService = HttpService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardPointsController.dispose();
    super.dispose();
  }

  // Callback from NutrientChallengeCard when its requirements change
  void _onNutrientRequirementsChanged(String nutrientName, Map<String, dynamic> requirements) {
    _nutrientRequirements[nutrientName] = requirements;
    // No need to call setState here, as the card itself manages its state
    // and we only need the final values on form submission.
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Collect all nutrient requirements that have selected fields
    final Map<String, dynamic> requirementsPayload = {};
    _nutrientRequirements.forEach((nutrientName, requirements) {
      requirementsPayload.addAll(requirements); // Add all selected fields from this nutrient
    });

    // Construct the full request body
    final Map<String, dynamic> requestBody = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'reward_points': int.tryParse(_rewardPointsController.text) ?? 0,
      'deadline': _selectedDeadline?.toIso8601String(), // Format deadline
      'difficulty': _selectedDifficulty,
      'requirements': requirementsPayload, // Include collected requirements
    };

    // Remove null values or empty requirements map if necessary based on API
    requestBody.removeWhere((key, value) => value == null);
    if (requestBody['requirements'] != null && (requestBody['requirements'] as Map).isEmpty) {
      requestBody.remove('requirements');
    }

    setState(() => _isSaving = true);

    try {
      final response = await _httpService.post(
        'challenges', // Endpoint for adding challenges
        data: requestBody,
      );

      if (response.statusCode == 201 && response.data['code'] == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Challenge added successfully!'), backgroundColor: Colors.green),
          );
          _resetForm(); // Clear form on success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Failed to add challenge'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding challenge: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _rewardPointsController.clear();
    setState(() {
      _selectedDifficulty = null;
      _selectedDeadline = null;
      _isNutrientChallengeExpanded = false;
      _nutrientPanelSelected.updateAll((key, value) => false);
      _nutrientRequirements.clear();
      // Note: Clearing controllers within NutrientChallengeCard requires accessing their state,
      // which is complex. Resetting the form key and state variables is simpler.
      // If needed, you could add a reset method to NutrientChallengeCard and call it here.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Challenge Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rewardPointsController,
                decoration: InputDecoration(
                  labelText: 'Reward Points',
                  prefixIcon: const Icon(Icons.star_border_purple500_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Only allow digits
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reward points';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number of points';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: InputDecoration(
                  labelText: 'Difficulty',
                  prefixIcon: const Icon(Icons.bar_chart_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _difficultyOptions.map((String difficulty) {
                  return DropdownMenuItem<String>(
                    value: difficulty,
                    child: Text(difficulty.capitalize()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDifficulty = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select difficulty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDeadline(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Deadline',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _selectedDeadline == null
                        ? 'Select Date and Time'
                        : DateFormat('yyyy-MM-dd HH:mm').format(_selectedDeadline!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDeadline == null ? Colors.grey[700] : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // "Set Nutrient Challenge" Expansion Panel
              ExpansionPanelList(
                elevation: 1,
                expandedHeaderPadding: EdgeInsets.zero,
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _isNutrientChallengeExpanded = !_isNutrientChallengeExpanded;
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text(
                          'Set Nutrient Challenge',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.teal.shade700),
                        ),
                        leading: Icon(Icons.fitness_center_outlined,
                            color: Colors.teal.shade700),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: _nutrientPanelSelected.keys.map((nutrientName) {
                          return Column(
                            children: [
                              // Selectable Header for each Nutrient
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _nutrientPanelSelected[nutrientName] = !_nutrientPanelSelected[nutrientName]!;
                                    // If deselected, clear its requirements
                                    if (!_nutrientPanelSelected[nutrientName]!) {
                                      _nutrientRequirements.remove(nutrientName);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _nutrientPanelSelected[nutrientName],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _nutrientPanelSelected[nutrientName] = value ?? false;
                                            if (!_nutrientPanelSelected[nutrientName]!) {
                                              _nutrientRequirements.remove(nutrientName);
                                            }
                                          });
                                        },
                                        activeColor: Colors.teal,
                                      ),
                                      Expanded(
                                        child: Text(
                                          nutrientName,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: _nutrientPanelSelected[nutrientName]!
                                                ? Colors.teal.shade700
                                                : Colors.black87,
                                            fontWeight: _nutrientPanelSelected[nutrientName]! ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        _nutrientPanelSelected[nutrientName]! ? Icons.expand_less : Icons.expand_more,
                                        color: Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // NutrientChallengeCard expands only if selected
                              if (_nutrientPanelSelected[nutrientName]!)
                                NutrientChallengeCard(
                                  nutrientName: nutrientName,
                                  onRequirementsChanged: _onNutrientRequirementsChanged,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    isExpanded: _isNutrientChallengeExpanded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(_isSaving ? 'Creating...' : 'Create Challenge'),
                  onPressed: _isSaving ? null : _createChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
