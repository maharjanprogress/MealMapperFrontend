import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _breakfastTimeController = TextEditingController();
  final _lunchTimeController = TextEditingController();
  final _dinnerTimeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedActivityLevel;
  String? _selectedGoal;
  String? _selectedDietaryPreference;

  bool _isChanged = false;
  bool _isLoading = false;

  final List<String> _activityLevelOptions = ['Not Active', 'Moderate', 'Very Active'];
  final List<String> _goalOptions = ['Go Slim', 'Maintain', 'Gain Weight'];
  final List<String> _dietaryPreferenceOptions = [
    'Any',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Carnivore',
    'Keto',
    'Omnivore'
  ];

  List<bool> _expandedPanels = [false, false, false, false, false];
  Map<String, dynamic> _changedData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('userEmail') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      _breakfastTimeController.text = '08:00';
      _lunchTimeController.text = '13:00';
      _dinnerTimeController.text = '19:00';
      _selectedActivityLevel = 'Moderate';
      _selectedGoal = 'Maintain';
      _selectedDietaryPreference = 'Any';
    });
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _isChanged = true;
      _changedData[key] = value;
    });
  }
  bool _validatePasswords() {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both password fields are required')),
      );
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return false;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return false;
    }
    return true;
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty) {
        if (!_validatePasswords()) return;
        _changedData['password'] = _passwordController.text;
      }

      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      try {
        final response = await HttpService().put(
          'update_profile/$userId',
          data: _changedData,
        );
        if (response.data['code'] == 200) {
          // Update SharedPreferences
          if (_changedData.containsKey('account_email')) {
            await prefs.setString('userEmail', _changedData['account_email']);
          }
          if (_changedData.containsKey('account_username')) {
            await prefs.setString('username', _changedData['account_username']);
          }

          // Clear password fields
          _passwordController.clear();
          _confirmPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );

          // Navigate back only after SharedPreferences are updated
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          throw Exception(response.data['message'] ?? 'Failed to update profile');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ExpansionPanelList(
              elevation: 2,
              expandedHeaderPadding: const EdgeInsets.all(8),
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  _expandedPanels[index] = !_expandedPanels[index];

                  // If panel has changes, keep it expanded
                  if (_changedData.keys.any((key) => key.startsWith(_getSectionPrefix(index)))) {
                    _expandedPanels[index] = true;
                  }
                });
              },
              children: [
                _buildExpansionPanel(
                  index: 0,
                  title: 'Account Information',
                  subtitle: 'Email, Username',
                  icon: Icons.person,
                  content: Column(
                    children: [
                      _buildTextField(
                        'Email',
                        _emailController,
                        Icons.email,
                            (value) => _onFieldChanged('account_email', value),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Username',
                        _usernameController,
                        Icons.person,
                            (value) => _onFieldChanged('account_username', value),
                      ),
                    ],
                  ),
                ),
                _buildExpansionPanel(
                  index: 1,
                  title: 'Health Information',
                  subtitle: 'Activity Level, Goals',
                  icon: Icons.fitness_center,
                  content: Column(
                    children: [
                      _buildDropdown(
                        'Activity Level',
                        _selectedActivityLevel,
                        _activityLevelOptions,
                            (value) => _onFieldChanged('health_activity_level', value),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        'Goal',
                        _selectedGoal,
                        _goalOptions,
                            (value) => _onFieldChanged('health_goal', value),
                      ),
                    ],
                  ),
                ),
                _buildExpansionPanel(
                  index: 2,
                  title: 'Meal Preferences',
                  subtitle: 'Meal Times, Dietary Preferences',
                  icon: Icons.restaurant_menu,
                  content: Column(
                    children: [
                      _buildDropdown(
                        'Dietary Preference',
                        _selectedDietaryPreference,
                        _dietaryPreferenceOptions,
                            (value) => _onFieldChanged('meal_dietary_pref', value),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeField(
                        'Breakfast Time',
                        _breakfastTimeController,
                        Icons.free_breakfast,
                            (value) => _onFieldChanged('meal_breakfast_time', value),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeField(
                        'Lunch Time',
                        _lunchTimeController,
                        Icons.lunch_dining,
                            (value) => _onFieldChanged('meal_lunch_time', value),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeField(
                        'Dinner Time',
                        _dinnerTimeController,
                        Icons.dinner_dining,
                            (value) => _onFieldChanged('meal_dinner_time', value),
                      ),
                    ],
                  ),
                ),
                // Add this after your existing expansion panels
                _buildExpansionPanel(
                  index: 3,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  icon: Icons.lock,
                  content: Column(
                    children: [
                      _buildPasswordField(
                        'New Password',
                        _passwordController,
                            (value) => _onFieldChanged('password', value),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        'Confirm Password',
                        _confirmPasswordController,
                            (value) => setState(() => _isChanged = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _isChanged ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: _updateProfile,
          label: const Text('Update'),
          icon: const Icon(Icons.save),
          backgroundColor: Colors.teal,
        ),
      ),
    );
  }

  ExpansionPanel _buildExpansionPanel({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget content,
  }) {
    bool hasChanges = _changedData.keys.any((key) =>
        key.startsWith(_getSectionPrefix(index)));

    return ExpansionPanel(
      headerBuilder: (context, isExpanded) {
        return ListTile(
          leading: Icon(icon,
            color: hasChanges ? Colors.teal : Colors.grey,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: hasChanges ? Colors.teal : Colors.black,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: hasChanges
              ? const Icon(Icons.check_circle, color: Colors.teal)
              : null,
        );
      },
      body: Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: content,
        ),
      ),
      isExpanded: _expandedPanels[index],
      canTapOnHeader: true,
    );
  }

  String _getSectionPrefix(int index) {
    switch (index) {
      case 0:
        return 'account_';
      case 1:
        return 'health_';
      case 2:
        return 'meal_';
      default:
        return '';
    }
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      ValueChanged<String> onChanged,
      ) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged,
    );
  }


  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      ValueChanged<String> onChanged,
      ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown(
      String label,
      String? value,
      List<String> options,
      ValueChanged<String?> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTimeField(
      String label,
      TextEditingController controller,
      IconData icon,
      ValueChanged<String> onChanged,
      ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(controller.text.split(':')[0]),
            minute: int.parse(controller.text.split(':')[1]),
          ),
        );
        if (pickedTime != null) {
          final formattedTime =
              '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
          controller.text = formattedTime;
          onChanged(formattedTime);
        }
      },
    );
  }
}