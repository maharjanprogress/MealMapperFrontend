import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../http_service.dart';
import 'nutrient_challenge_card.dart';

class ChallengeModifyForm extends StatefulWidget {
  final int challengeId;
  final Function onChallengeUpdated;

  const ChallengeModifyForm({
    Key? key,
    required this.challengeId,
    required this.onChallengeUpdated,
  }) : super(key: key);

  @override
  _ChallengeModifyFormState createState() => _ChallengeModifyFormState();
}

class _ChallengeModifyFormState extends State<ChallengeModifyForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rewardPointsController = TextEditingController();

  String? _selectedDifficulty;
  DateTime? _selectedDeadline;

  final List<String> _difficultyOptions = ['easy', 'medium', 'hard', 'expert'];
  bool _isNutrientChallengeExpanded = false;
  final Map<String, bool> _nutrientPanelSelected = {
    'Protein': false,
    'Calories': false,
    'Carbs': false,
    'Fat': false,
    'Sugar': false,
    'Sodium': false,
  };
  final Map<String, Map<String, dynamic>> _nutrientRequirements = {};
  // Store initial requirements to pass to NutrientChallengeCard
  Map<String, dynamic> _initialChallengeRequirements = {};

  bool _isLoadingData = true;
  bool _isSaving = false;
  String _errorMessage = '';
  final HttpService _httpService = HttpService();

  @override
  void initState() {
    super.initState();
    _fetchChallengeDetails();
  }

  Future<void> _fetchChallengeDetails() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = '';
    });
    try {
      final response = await _httpService.get('challenge/${widget.challengeId}');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final details = response.data['details'];
        _titleController.text = details['title'] ?? '';
        _descriptionController.text = details['description'] ?? '';
        _rewardPointsController.text = (details['reward_points'] ?? 0).toString();
        _selectedDifficulty = details['difficulty'];
        if (details['deadline'] != null) {
          _selectedDeadline = DateTime.tryParse(details['deadline']);
        }

        _initialChallengeRequirements = Map<String, dynamic>.from(details['requirements'] ?? {});
        // Pre-select nutrient panels based on fetched requirements
        _nutrientPanelSelected.forEach((nutrientKey, value) {
          final nutrientApiPrefix = nutrientKey.toLowerCase();
          if (_initialChallengeRequirements.keys.any((reqKey) => reqKey.contains(nutrientApiPrefix))) {
            _nutrientPanelSelected[nutrientKey] = true;
          }
        });
        // If any nutrient is selected, expand the main panel
        if (_nutrientPanelSelected.values.any((isSelected) => isSelected)) {
          _isNutrientChallengeExpanded = true;
        }


      } else {
        _errorMessage = response.data['message'] ?? 'Failed to load challenge details.';
      }
    } catch (e) {
      _errorMessage = 'Error fetching challenge: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardPointsController.dispose();
    super.dispose();
  }

  void _onNutrientRequirementsChanged(String nutrientName, Map<String, dynamic> requirements) {
    _nutrientRequirements[nutrientName] = requirements;
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past dates for viewing/editing
      lastDate: DateTime(2035),
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

  Future<void> _updateChallenge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> finalRequirementsPayload = {};

    // Iterate over all possible nutrients to build the final payload
    for (String nutrientName in _nutrientPanelSelected.keys) {
      bool isPanelSelected = _nutrientPanelSelected[nutrientName] ?? false;
      final String baseName = nutrientName.toLowerCase().replaceAll(' ', '_');

      if (isPanelSelected) {
        // If the panel is selected by the user:
        // Check if there are user-modified requirements from the card.
        if (_nutrientRequirements.containsKey(nutrientName) && _nutrientRequirements[nutrientName]!.isNotEmpty) {
          finalRequirementsPayload.addAll(_nutrientRequirements[nutrientName]!);
        } else if (_nutrientRequirements.containsKey(nutrientName) && _nutrientRequirements[nutrientName]!.isEmpty) {
          // User interacted and cleared all fields for this nutrient, send empty if API expects it or handle as needed
          // For now, if the map is empty, it means no specific requirement for this nutrient.
        }
        else {
          // Panel is selected, but user didn't interact with the card after load.
          // So, we re-add its initial values if they existed.
          if (_initialChallengeRequirements.containsKey('required_$baseName')) {
            finalRequirementsPayload['required_$baseName'] = _initialChallengeRequirements['required_$baseName'];
          }
          if (_initialChallengeRequirements.containsKey('min_${baseName}_per_serving')) {
            finalRequirementsPayload['min_${baseName}_per_serving'] = _initialChallengeRequirements['min_${baseName}_per_serving'];
          }
          if (_initialChallengeRequirements.containsKey('max_${baseName}_per_serving')) {
            finalRequirementsPayload['max_${baseName}_per_serving'] = _initialChallengeRequirements['max_${baseName}_per_serving'];
          }
        }
      }
    }


    final Map<String, dynamic> requestBody = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'reward_points': int.tryParse(_rewardPointsController.text) ?? 0,
      'deadline': _selectedDeadline?.toIso8601String(),
      'difficulty': _selectedDifficulty,
      'requirements': finalRequirementsPayload,
    };

    requestBody.removeWhere((key, value) => value == null);
    if (requestBody['requirements'] != null && (requestBody['requirements'] as Map).isEmpty) {
      requestBody.remove('requirements');
    }

    setState(() => _isSaving = true);

    try {
      final response = await _httpService.put(
        'challenge/${widget.challengeId}',
        data: requestBody,
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Challenge updated successfully!'), backgroundColor: Colors.green),
          );
          widget.onChallengeUpdated(); // Call callback to refresh list in parent
          Navigator.of(context).pop(); // Close the dialog
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Failed to update challenge'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating challenge: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  NutrientChallengeCard _buildNutrientCard(String nutrientName) {
    final String baseName = nutrientName.toLowerCase().replaceAll(' ', '_');
    return NutrientChallengeCard(
      nutrientName: nutrientName,
      onRequirementsChanged: _onNutrientRequirementsChanged,
      initialIsRequiredSelected: _initialChallengeRequirements.containsKey('required_$baseName'),
      initialRequiredValue: (_initialChallengeRequirements['required_$baseName'] as num?)?.toDouble(),
      initialIsMinSelected: _initialChallengeRequirements.containsKey('min_${baseName}_per_serving'),
      initialMinValue: (_initialChallengeRequirements['min_${baseName}_per_serving'] as num?)?.toDouble(),
      initialIsMaxSelected: _initialChallengeRequirements.containsKey('max_${baseName}_per_serving'),
      initialMaxValue: (_initialChallengeRequirements['max_${baseName}_per_serving'] as num?)?.toDouble(),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for AlertDialog content
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Challenge Title',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a title';
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
                if (value == null || value.isEmpty) return 'Please enter a description';
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter reward points';
                if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Please enter a valid number of points';
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
              onChanged: (String? newValue) => setState(() => _selectedDifficulty = newValue),
              validator: (value) => (value == null || value.isEmpty) ? 'Please select difficulty' : null,
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
                  _selectedDeadline == null ? 'Select Date and Time' : DateFormat('yyyy-MM-dd HH:mm').format(_selectedDeadline!),
                  style: TextStyle(fontSize: 16, color: _selectedDeadline == null ? Colors.grey[700] : Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ExpansionPanelList(
              elevation: 1,
              expandedHeaderPadding: EdgeInsets.zero,
              expansionCallback: (int index, bool isExpanded) {
                setState(() => _isNutrientChallengeExpanded = !_isNutrientChallengeExpanded);
              },
              children: [
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      title: Text('Set Nutrient Challenge', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.teal.shade700)),
                      leading: Icon(Icons.fitness_center_outlined, color: Colors.teal.shade700),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: _nutrientPanelSelected.keys.map((nutrientName) {
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => setState(() {
                                _nutrientPanelSelected[nutrientName] = !_nutrientPanelSelected[nutrientName]!;
                                if (!_nutrientPanelSelected[nutrientName]!) _nutrientRequirements.remove(nutrientName);
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _nutrientPanelSelected[nutrientName],
                                      onChanged: (bool? value) => setState(() {
                                        _nutrientPanelSelected[nutrientName] = value ?? false;
                                        if (!_nutrientPanelSelected[nutrientName]!) _nutrientRequirements.remove(nutrientName);
                                      }),
                                      activeColor: Colors.teal,
                                    ),
                                    Expanded(
                                      child: Text(
                                        nutrientName,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: _nutrientPanelSelected[nutrientName]! ? Colors.teal.shade700 : Colors.black87,
                                          fontWeight: _nutrientPanelSelected[nutrientName]! ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    Icon(_nutrientPanelSelected[nutrientName]! ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                            if (_nutrientPanelSelected[nutrientName]!) _buildNutrientCard(nutrientName),
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
            Row( // Removed MainAxisAlignment.end as Expanded will fill the space
              children: [
                Expanded(
                  flex: 3, // Roughly 30%
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12), // Horizontal padding managed by Expanded
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 7, // Roughly 70%
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_alt_outlined),
                    label: Text(_isSaving ? 'Updating...' : 'Update Challenge', textAlign: TextAlign.center),
                    onPressed: _isSaving ? null : _updateChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12), // Horizontal padding managed by Expanded
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      // Ensure the button tries to fill the expanded width if its content is small
                      // minimumSize: MaterialStateProperty.all(const Size(double.infinity, 0)), // Option 1
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}