import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters

class NutrientChallengeCard extends StatefulWidget {
  final String nutrientName; // e.g., "Protein", "Calories"
  final Function(String nutrientName, Map<String, dynamic> requirements)
  onRequirementsChanged; // Callback to parent
  final double? initialRequiredValue;
  final bool initialIsRequiredSelected;
  final double? initialMinValue;
  final bool initialIsMinSelected;
  final double? initialMaxValue;
  final bool initialIsMaxSelected;

  const NutrientChallengeCard({
    Key? key,
    required this.nutrientName,
    required this.onRequirementsChanged,
    this.initialRequiredValue,
    this.initialIsRequiredSelected = false,
    this.initialMinValue,
    this.initialIsMinSelected = false,
    this.initialMaxValue,
    this.initialIsMaxSelected = false,
  }) : super(key: key);

  @override
  _NutrientChallengeCardState createState() => _NutrientChallengeCardState();
}

class _NutrientChallengeCardState extends State<NutrientChallengeCard> {
  final TextEditingController _requiredController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  bool _isRequiredSelected = false;
  bool _isMinSelected = false;
  bool _isMaxSelected = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and selection states from initial values
    _requiredController.text = widget.initialRequiredValue?.toString() ?? '';
    _isRequiredSelected = widget.initialIsRequiredSelected;
    _minController.text = widget.initialMinValue?.toString() ?? '';
    _isMinSelected = widget.initialIsMinSelected;
    _maxController.text = widget.initialMaxValue?.toString() ?? '';
    _isMaxSelected = widget.initialIsMaxSelected;

    // Add listeners to text controllers to notify parent on change
    _requiredController.addListener(_notifyParent);
    _minController.addListener(_notifyParent);
    _maxController.addListener(_notifyParent);
  }

  @override
  void dispose() {
    _requiredController.removeListener(_notifyParent);
    _minController.removeListener(_notifyParent);
    _maxController.removeListener(_notifyParent);
    _requiredController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    // Collect selected requirements and their values
    final Map<String, dynamic> requirements = {};
    final String baseName = widget.nutrientName.toLowerCase().replaceAll(' ', '_');

    if (_isRequiredSelected && _requiredController.text.isNotEmpty) {
      requirements['required_$baseName'] = double.tryParse(_requiredController.text) ?? 0;
    }
    if (_isMinSelected && _minController.text.isNotEmpty) {
      requirements['min_${baseName}_per_serving'] = double.tryParse(_minController.text) ?? 0;
    }
    if (_isMaxSelected && _maxController.text.isNotEmpty) {
      requirements['max_${baseName}_per_serving'] = double.tryParse(_maxController.text) ?? 0;
    }

    // Call the parent's callback with the nutrient name and its selected requirements
    widget.onRequirementsChanged(widget.nutrientName, requirements);
  }

  Widget _buildRequirementField({
    required String label,
    required TextEditingController controller,
    required bool isSelected,
    required ValueChanged<bool?> onSelected,
  }) {
    return Row(
      children: [
        Checkbox(
          value: isSelected,
          onChanged: onSelected,
          activeColor: Colors.teal,
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: isSelected, // Only enable if checkbox is selected
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allow digits and one decimal point
            ],
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
            validator: (value) {
              if (isSelected && (value == null || value.isEmpty)) {
                return '$label is required if selected';
              }
              if (isSelected && double.tryParse(value!) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nutrientName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.teal.shade700),
            ),
            const SizedBox(height: 12),
            _buildRequirementField(
              label: 'Required',
              controller: _requiredController,
              isSelected: _isRequiredSelected,
              onSelected: (bool? value) {
                setState(() {
                  _isRequiredSelected = value ?? false;
                  if (!_isRequiredSelected) _requiredController.clear(); // Clear if deselected
                });
                _notifyParent();
              },
            ),
            const SizedBox(height: 8),
            _buildRequirementField(
              label: 'Min per Serving',
              controller: _minController,
              isSelected: _isMinSelected,
              onSelected: (bool? value) {
                setState(() {
                  _isMinSelected = value ?? false;
                  if (!_isMinSelected) _minController.clear(); // Clear if deselected
                });
                _notifyParent();
              },
            ),
            const SizedBox(height: 8),
            _buildRequirementField(
              label: 'Max per Serving',
              controller: _maxController,
              isSelected: _isMaxSelected,
              onSelected: (bool? value) {
                setState(() {
                  _isMaxSelected = value ?? false;
                  if (!_isMaxSelected) _maxController.clear(); // Clear if deselected
                });
                _notifyParent();
              },
            ),
          ],
        ),
      ),
    );
  }
}
