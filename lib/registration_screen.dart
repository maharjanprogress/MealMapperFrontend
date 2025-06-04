// registration_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _addressController = TextEditingController();
  final HttpService _httpService = HttpService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedGender;
  String? _selectedActivityLevel;
  String? _selectedGoal;
  String? _selectedDietaryPreference;

  // Meal times
  final _breakfastTimeController = TextEditingController(text: '08:00');
  final _lunchTimeController = TextEditingController(text: '13:00');
  final _dinnerTimeController = TextEditingController(text: '19:00');

  // Dropdown options
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _activityLevelOptions = ['Not Active', 'Moderate', 'Very Active'];
  final List<String> _goalOptions = ['Go Slim', 'Maintain', 'Gain Weight'];
  final List<String> _dietaryPreferenceOptions = ['Any', 'Vegetarian', 'Vegan', 'Pescatarian','Carnivore', 'Keto', 'Omnivore'];

  List<String> _selectedAllergies = [];
  List<Map<String, dynamic>> _dynamicAllergyOptions = [];
  final _allergySearchController = TextEditingController();
  Timer? _allergySearchDebouncer;
  bool _isLoadingAllergies = false;

  List<String> _selectedMedicalConditions = [];
  List<Map<String, dynamic>> _dynamicMedicalConditionOptions = [];
  final _medicalConditionSearchController = TextEditingController();
  Timer? _medicalConditionSearchDebouncer;
  bool _isLoadingMedicalConditions = false;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _allergySearchController.addListener(_onAllergySearchChanged);
    _medicalConditionSearchController.addListener(_onMedicalConditionSearchChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.teal.shade50],
          ),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              // Validate the Account Information form
              if (_formKey.currentState!.validate()) {
                if (_passwordController.text != _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                setState(() {
                  _currentStep += 1;
                });
              }
            } else if (_currentStep == 1) {
              // Validate Personal Details form
              if (_ageController.text.isNotEmpty &&
                  _selectedGender != null &&
                  _heightController.text.isNotEmpty &&
                  _weightController.text.isNotEmpty &&
                  _addressController.text.isNotEmpty) {
                setState(() {
                  _currentStep += 1;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
              }
            } else if (_currentStep == 2) {
              // Validate Health Information form
              if (_selectedActivityLevel != null && _selectedGoal != null) {
                setState(() {
                  _currentStep += 1;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
              }
            } else {
              _submitForm();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: details.onStepContinue,
                      child: Text(
                        _currentStep == 3 ? 'Register' : 'Next',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          side: const BorderSide(color: Colors.teal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: details.onStepCancel,
                        child: const Text(
                          'Back',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Account Information'),
              content: _buildAccountInfoForm(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Personal Details'),
              content: _buildPersonalDetailsForm(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Health Information'),
              content: _buildHealthInformationForm(),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Meal Preferences'),
              content: _buildMealPreferencesForm(),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ageController,
          decoration: InputDecoration(
            labelText: 'Age',
            prefixIcon: const Icon(Icons.cake),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your age';
            }
            if (int.tryParse(value) == null || int.parse(value) <= 0) {
              return 'Please enter a valid age';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: const Icon(Icons.people),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _genderOptions.map((String gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your gender';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _heightController,
          decoration: InputDecoration(
            labelText: 'Height (cm)',
            prefixIcon: const Icon(Icons.height),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your height';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'Please enter a valid height';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _weightController,
          decoration: InputDecoration(
            labelText: 'Weight (kg)',
            prefixIcon: const Icon(Icons.line_weight),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your weight';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'Please enter a valid weight';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHealthInformationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedActivityLevel,
          decoration: InputDecoration(
            labelText: 'Activity Level',
            prefixIcon: const Icon(Icons.directions_run),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _activityLevelOptions.map((String level) {
            return DropdownMenuItem<String>(
              value: level,
              child: Text(level),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedActivityLevel = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your activity level';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGoal,
          decoration: InputDecoration(
            labelText: 'Goal',
            prefixIcon: const Icon(Icons.flag),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _goalOptions.map((String goal) {
            return DropdownMenuItem<String>(
              value: goal,
              child: Text(goal),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGoal = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your goal';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Medical Conditions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _medicalConditionSearchController,
          decoration: InputDecoration(
            labelText: 'Search Medical Conditions',
            hintText: 'e.g., Diabetes',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _medicalConditionSearchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _medicalConditionSearchController.clear();
                // _onMedicalConditionSearchChanged will be triggered by listener
              },
            )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        // Static "None" option
        FilterChip(
          label: const Text('None'),
          selected: _selectedMedicalConditions.contains('None'),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedMedicalConditions = ['None']; // Clears other selections and adds 'None'
              } else {
                _selectedMedicalConditions.remove('None');
              }
            });
          },
          selectedColor: Colors.teal.shade100,
          checkmarkColor: Colors.teal,
          labelStyle: TextStyle(color: _selectedMedicalConditions.contains('None') ? Colors.teal : Colors.black87),
        ),
        if (_isLoadingMedicalConditions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_medicalConditionSearchController.text.isNotEmpty && _dynamicMedicalConditionOptions.isEmpty && !_isLoadingMedicalConditions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Center(child: Text('No conditions found matching your search.')),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _dynamicMedicalConditionOptions.map((condition) {
              final conditionName = condition['name'] as String;
              final bool isSelected = _selectedMedicalConditions.contains(conditionName);
              return FilterChip(
                label: Text(conditionName),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedMedicalConditions.add(conditionName);
                      _selectedMedicalConditions.remove('None'); // Deselect 'None' if another condition is selected
                    } else {
                      _selectedMedicalConditions.remove(conditionName);
                    }
                  });
                },
                selectedColor: Colors.teal.shade100,
                checkmarkColor: Colors.teal,
                labelStyle: TextStyle(color: isSelected ? Colors.teal : Colors.black87),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildMealPreferencesForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedDietaryPreference,
          decoration: InputDecoration(
            labelText: 'Dietary Preference',
            prefixIcon: const Icon(Icons.restaurant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _dietaryPreferenceOptions.map((String preference) {
            return DropdownMenuItem<String>(
              value: preference,
              child: Text(preference),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedDietaryPreference = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your dietary preference';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Allergies',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _allergySearchController,
          decoration: InputDecoration(
            labelText: 'Search Allergies',
            hintText: 'e.g., Peanuts',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _allergySearchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _allergySearchController.clear();
                // _onAllergySearchChanged will be triggered by listener
              },
            )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingAllergies)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_allergySearchController.text.isNotEmpty && _dynamicAllergyOptions.isEmpty && !_isLoadingAllergies)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Center(child: Text('No allergies found matching your search.')),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _dynamicAllergyOptions.map((allergy) {
              final allergyName = allergy['name'] as String;
              final bool isSelected = _selectedAllergies.contains(allergyName);
              return FilterChip(
                label: Text(allergyName),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedAllergies.add(allergyName);
                    } else {
                      _selectedAllergies.remove(allergyName);
                    }
                  });
                },
                selectedColor: Colors.teal.shade100,
                checkmarkColor: Colors.teal,
                labelStyle: TextStyle(color: isSelected ? Colors.teal : Colors.black87),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        const Text(
          'Meal Times',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _breakfastTimeController,
                decoration: InputDecoration(
                  labelText: 'Breakfast',
                  prefixIcon: const Icon(Icons.free_breakfast),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.parse(_breakfastTimeController.text.split(':')[0]),
                      minute: int.parse(_breakfastTimeController.text.split(':')[1]),
                    ),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _breakfastTimeController.text =
                      '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _lunchTimeController,
                decoration: InputDecoration(
                  labelText: 'Lunch',
                  prefixIcon: const Icon(Icons.lunch_dining),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.parse(_lunchTimeController.text.split(':')[0]),
                      minute: int.parse(_lunchTimeController.text.split(':')[1]),
                    ),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _lunchTimeController.text =
                      '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _dinnerTimeController,
                decoration: InputDecoration(
                  labelText: 'Dinner',
                  prefixIcon: const Icon(Icons.dinner_dining),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.parse(_dinnerTimeController.text.split(':')[0]),
                      minute: int.parse(_dinnerTimeController.text.split(':')[1]),
                    ),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _dinnerTimeController.text =
                      '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onAllergySearchChanged() {
    if (_allergySearchDebouncer?.isActive ?? false) _allergySearchDebouncer!.cancel();
    _allergySearchDebouncer = Timer(const Duration(milliseconds: 500), () {
      final query = _allergySearchController.text.trim();
      if (query.isNotEmpty) {
        _fetchAllergies(query);
      } else {
        setState(() {
          _dynamicAllergyOptions = [];
          _isLoadingAllergies = false;
        });
      }
    });
  }

  Future<void> _fetchAllergies(String query) async {
    setState(() => _isLoadingAllergies = true);
    try {
      final response = await _httpService.get('allergens/$query');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final details = List<Map<String, dynamic>>.from(response.data['details']);
        setState(() {
          _dynamicAllergyOptions = details;
        });
      } else {
        setState(() { _dynamicAllergyOptions = []; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'] ?? 'Failed to load allergies')));
      }
    } catch (e) {
      setState(() { _dynamicAllergyOptions = []; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching allergies: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingAllergies = false);
    }
  }

  // Debounce and API call for Medical Conditions
  void _onMedicalConditionSearchChanged() {
    if (_medicalConditionSearchDebouncer?.isActive ?? false) _medicalConditionSearchDebouncer!.cancel();
    _medicalConditionSearchDebouncer = Timer(const Duration(milliseconds: 500), () {
      final query = _medicalConditionSearchController.text.trim();
      if (query.isNotEmpty) {
        _fetchMedicalConditions(query);
      } else {
        setState(() {
          _dynamicMedicalConditionOptions = [];
          _isLoadingMedicalConditions = false;
        });
      }
    });
  }

  Future<void> _fetchMedicalConditions(String query) async {
    setState(() => _isLoadingMedicalConditions = true);
    try {
      final response = await _httpService.get('medical_condition_guidelines/$query'); // As per your endpoint "ingredients/(typed words)"
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final details = List<Map<String, dynamic>>.from(response.data['details']);
        setState(() => _dynamicMedicalConditionOptions = details);
      } else {
        setState(() => _dynamicMedicalConditionOptions = []);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'] ?? 'Failed to load medical conditions')));
      }
    } catch (e) {
      setState(() => _dynamicMedicalConditionOptions = []);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching medical conditions: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingMedicalConditions = false);
    }
  }
  void _submitForm() async{
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Create a map of user data
      final userData = {
        'email': _emailController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'height_cm': double.parse(_heightController.text),
        'weight_kg': double.parse(_weightController.text),
        'activity_level': _selectedActivityLevel,
        'goal': _selectedGoal,
        'dietary_pref': _selectedDietaryPreference,
        'allergies': _selectedAllergies,
        'medical_conditions': _selectedMedicalConditions,
        'meal_times': {
          'breakfast': _breakfastTimeController.text,
          'lunch': _lunchTimeController.text,
          'dinner': _dinnerTimeController.text,
        },
        'address': _addressController.text,
      };

      try {
        // Send API request
        final response = await _httpService.post('/users', data: userData);

        if (response.data != null && response.data['code'] == 201) {
          final details = response.data['details'];

          // Store userId, username, and email in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', details['userId']);
          await prefs.setString('username', details['username']);
          await prefs.setString('userEmail', details['email']);

          // Navigate to the home screen
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        }
        else if(response.data != null && response.data['code'] == 206) {
          // Show error message if email already exists
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Email or username already exists')),
          );
          }
        }
        else {
          // Show error message if registration fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Registration failed')),
          );
          }
        }
      } catch (e) {
        // Handle any errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    _breakfastTimeController.dispose();
    _lunchTimeController.dispose();
    _dinnerTimeController.dispose();
    _allergySearchController.removeListener(_onAllergySearchChanged);
    _allergySearchController.dispose();
    _medicalConditionSearchController.removeListener(_onMedicalConditionSearchChanged);
    _medicalConditionSearchController.dispose();
    _allergySearchDebouncer?.cancel();
    _medicalConditionSearchDebouncer?.cancel();
    super.dispose();
  }
}