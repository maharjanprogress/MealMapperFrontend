import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../http_service.dart'; // Assuming HttpService is in lib

class MedicalGuidelineItemFormData {
  String? guidelineId;
  String conditionName;
  String? parameterTargetType;
  String? guidelineTypeDisplay;
  String? guidelineTypeValue;
  String? parameterTarget;
  String? thresholdValue;
  String? thresholdUnit;
  String? severity;
  String description;
  bool isDeleted;

  MedicalGuidelineItemFormData({
    this.guidelineId,
    required this.conditionName,
    this.parameterTargetType,
    this.guidelineTypeDisplay,
    this.guidelineTypeValue,
    this.parameterTarget,
    this.thresholdValue,
    this.thresholdUnit,
    this.severity,
    required this.description,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'condition_name': conditionName,
      'description': description,
      'delete': isDeleted,
    };
    if (guidelineId != null && guidelineId!.isNotEmpty) {
      data['guideline_id'] = int.tryParse(guidelineId!);
    }
    if (guidelineTypeValue != null) data['guideline_type'] = guidelineTypeValue;
    if (parameterTarget != null) data['parameter_target'] = parameterTarget;
    if (parameterTargetType != null) data['parameter_target_type'] = parameterTargetType;
    if (thresholdValue != null && thresholdValue!.isNotEmpty) data['threshold_value'] = double.tryParse(thresholdValue!);
    if (thresholdUnit != null) data['threshold_unit'] = thresholdUnit;
    if (severity != null) data['severity'] = severity;
    return data;
  }
}

class MedicalGuidelineItemForm extends StatefulWidget {
  final MedicalGuidelineItemFormData initialData;
  final ValueChanged<MedicalGuidelineItemFormData> onChanged;
  final VoidCallback? onDelete;
  final HttpService httpService;
  final Key? formKey;

  const MedicalGuidelineItemForm({
    super.key,
    required this.initialData,
    required this.onChanged,
    this.onDelete,
    required this.httpService,
    this.formKey,
  });

  @override
  _MedicalGuidelineItemFormState createState() => _MedicalGuidelineItemFormState();
}

class _MedicalGuidelineItemFormState extends State<MedicalGuidelineItemForm> {
  late MedicalGuidelineItemFormData _formData;

  final List<String> _parameterTargetTypeOptions = [
    "ALLERGEN", "INGREDIENT", "NUTRIENT", "FOOD_CATEGORY", "FOOD_ITEM", "FOOD_TAG"
  ];
  List<String> _guidelineTypeDisplayOptions = [];
  List<String> _parameterTargetOptions = [];
  List<String> _thresholdUnitOptions = [];
  List<String> _severityOptions = [];

  bool _showThresholdFields = false;
  bool _isLoadingParameterTarget = false;

  late TextEditingController _descriptionController;
  late TextEditingController _thresholdValueController;

  @override
  void initState() {
    super.initState();
    _formData = widget.initialData;
    _descriptionController = TextEditingController(text: _formData.description);
    _thresholdValueController = TextEditingController(text: _formData.thresholdValue);

    _descriptionController.addListener(() {
      _formData.description = _descriptionController.text;
      widget.onChanged(_formData);
    });
    _thresholdValueController.addListener(() {
      _formData.thresholdValue = _thresholdValueController.text;
      widget.onChanged(_formData);
    });

    if (_formData.parameterTargetType != null) {
      _initializeFormFromInitialData();
    }
  }

  Future<void> _initializeFormFromInitialData() async {
    if (!mounted || _formData.parameterTargetType == null) return;

    // 1. Set Parameter Target Type and update its direct dependents (Guideline Type options)
    _guidelineTypeDisplayOptions = _getGuidelineTypeOptions(_formData.parameterTargetType!);

    // 2. Attempt to set Guideline Type Display & Value from initialData or auto-select
    if (widget.initialData.guidelineTypeDisplay != null && _guidelineTypeDisplayOptions.contains(widget.initialData.guidelineTypeDisplay)) {
      _formData.guidelineTypeDisplay = widget.initialData.guidelineTypeDisplay;
    } else if (_guidelineTypeDisplayOptions.length == 1) { // Auto-select if only one option
      _formData.guidelineTypeDisplay = _guidelineTypeDisplayOptions.first;
    }
    _formData.guidelineTypeValue = _getGuidelineTypeValue(_formData.parameterTargetType!, _formData.guidelineTypeDisplay);

    // 3. Fetch Parameter Target options. This method will also try to set _formData.parameterTarget
    // from widget.initialData.parameterTarget if it's valid among the fetched options.
    await _fetchParameterTargetOptions(_formData.parameterTargetType!, initialTargetValueToSet: widget.initialData.parameterTarget);

    // 4. Now that Parameter Target Type, Guideline Type, and Parameter Target are set (or attempted),
    //    update threshold and severity fields based on the now-set _formData.
    _updateThresholdAndSeverityFieldsFromFormData(isInitialization: true);

    if (mounted) {
      setState(() {});
    }
  }


  @override
  void didUpdateWidget(covariant MedicalGuidelineItemForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData.conditionName != _formData.conditionName) {
      setState(() {
        _formData.conditionName = widget.initialData.conditionName;
      });
    }
    // If the entire initialData object reference changes, it might indicate a full refresh.
    // Be cautious here to avoid overwriting user edits unintentionally.
    // This is a common place for bugs if not handled carefully.
    // For now, we only explicitly handle conditionName.
    // If other fields of initialData can change and should force a re-init,
    // more complex comparison logic would be needed.
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _thresholdValueController.dispose();
    super.dispose();
  }

  void _onParameterTargetTypeChanged(String? newValue, {bool isInitialization = false}) {
    // Prevent redundant calls if the value hasn't changed, unless it's part of initialization
    if (newValue == null || (newValue == _formData.parameterTargetType && !isInitialization)) return;

    setState(() {
      _formData.parameterTargetType = newValue;
      // Reset dependent fields
      _formData.guidelineTypeDisplay = null;
      _formData.guidelineTypeValue = null;
      _formData.parameterTarget = null;
      _formData.severity = null;
      _formData.thresholdValue = null;
      _formData.thresholdUnit = null;
      _thresholdValueController.clear();
      _showThresholdFields = false;
      _parameterTargetOptions = []; // Clear old parameter target options immediately

      _guidelineTypeDisplayOptions = _getGuidelineTypeOptions(newValue);
      // Auto-select guidelineTypeDisplay if only one option (e.g., for ALLERGEN)
      if (_guidelineTypeDisplayOptions.length == 1) {
        _formData.guidelineTypeDisplay = _guidelineTypeDisplayOptions.first;
        _formData.guidelineTypeValue = _getGuidelineTypeValue(newValue, _formData.guidelineTypeDisplay);
      }

      // Fetch new parameter target options. The `then` block will handle post-fetch logic.
      _fetchParameterTargetOptions(newValue).then((_) {
        if (!mounted) return;
        // If guidelineType was auto-selected, we might need to update dependent fields again
        // especially if parameterTarget got set during fetch.
        if (_formData.guidelineTypeDisplay != null) {
          // This ensures threshold and severity are re-evaluated after parameterTarget is potentially set
          _updateThresholdAndSeverityFieldsFromFormData(isInitialization: false); // Not strictly init, but re-evaluation
        }
        // This setState is crucial if _fetchParameterTargetOptions or subsequent logic changes state
        // that affects the UI directly (e.g. selected parameterTarget).
        if (mounted) {
          setState(() {});
        }
      });
      // Update severity options based on the potentially auto-selected guideline type
      _severityOptions = _getSeverityOptions(newValue, _formData.guidelineTypeValue);

      if (!isInitialization) widget.onChanged(_formData);
    });
  }

  void _onGuidelineTypeChanged(String? newDisplayValue, {bool isInitialization = false}) {
    if (newDisplayValue == null || _formData.parameterTargetType == null || (newDisplayValue == _formData.guidelineTypeDisplay && !isInitialization)) return;

    setState(() {
      _formData.guidelineTypeDisplay = newDisplayValue;
      _formData.guidelineTypeValue = _getGuidelineTypeValue(_formData.parameterTargetType!, newDisplayValue);

      // Reset fields dependent on guideline type
      _formData.severity = null;
      _formData.thresholdValue = null;
      _formData.thresholdUnit = null;
      _thresholdValueController.clear();

      _updateThresholdAndSeverityFieldsFromFormData(isInitialization: isInitialization);

      if (!isInitialization) widget.onChanged(_formData);
    });
  }

  void _updateThresholdAndSeverityFieldsFromFormData({required bool isInitialization}) {
    // This function assumes _formData.parameterTargetType and _formData.guidelineTypeValue are set.
    // It also uses _formData.parameterTarget.

    if (_formData.parameterTargetType == "NUTRIENT" && _formData.guidelineTypeValue != "MONITOR_NUTRIENT") {
      _showThresholdFields = true;
      _thresholdUnitOptions = _getThresholdUnitOptions(_formData.parameterTarget);
      if (isInitialization && widget.initialData.thresholdUnit != null && _thresholdUnitOptions.contains(widget.initialData.thresholdUnit)) {
        _formData.thresholdUnit = widget.initialData.thresholdUnit;
      } else if (!_thresholdUnitOptions.contains(_formData.thresholdUnit)) {
        // If current unit is no longer valid, clear it
        _formData.thresholdUnit = null;
      }
    } else {
      _showThresholdFields = false;
      _thresholdUnitOptions = [];
      _formData.thresholdUnit = null; // Clear unit if fields are hidden
      _formData.thresholdValue = null; // Clear value if fields are hidden
      _thresholdValueController.clear();
    }

    _severityOptions = _getSeverityOptions(_formData.parameterTargetType, _formData.guidelineTypeValue);
    if (isInitialization && widget.initialData.severity != null && _severityOptions.contains(widget.initialData.severity)) {
      _formData.severity = widget.initialData.severity;
    } else if (!_severityOptions.contains(_formData.severity)) {
      // If current severity is no longer valid, clear it
      _formData.severity = null;
    }
  }

  void _onParameterTargetChanged(String? newValue) {
    if (newValue == _formData.parameterTarget) return; // No change
    setState(() {
      _formData.parameterTarget = newValue;
      if (_formData.parameterTargetType == "NUTRIENT" && _showThresholdFields) {
        _formData.thresholdUnit = null; // Reset unit when target changes, user must reselect
        _thresholdUnitOptions = _getThresholdUnitOptions(newValue);
      }
      widget.onChanged(_formData);
    });
  }

  List<String> _getGuidelineTypeOptions(String parameterTargetType) {
    switch (parameterTargetType) {
      case "ALLERGEN": return ["Avoid Allergen"];
      case "INGREDIENT": return ["Avoid Ingredient", "Prefer Ingredient"];
      case "NUTRIENT": return ["Limit Nutrient", "Prefer Nutrient", "Increase Nutrient", "Decrease Nutrient", "Monitor Nutrient"];
      case "FOOD_CATEGORY": return ["Avoid Food Category", "Prefer Food Category"];
      case "FOOD_ITEM": return ["Avoid Food Item", "Prefer Food Item"];
      case "FOOD_TAG": return ["Avoid Food with Tag", "Prefer Food with Tag"];
      default: return [];
    }
  }

  String? _getGuidelineTypeValue(String parameterTargetType, String? displayValue) {
    if (displayValue == null) return null;
    switch (parameterTargetType) {
      case "ALLERGEN": return "AVOID_ALLERGEN_NAME";
      case "INGREDIENT":
        return displayValue == "Avoid Ingredient" ? "AVOID_INGREDIENT_NAME" : "PREFER_INGREDIENT_NAME";
      case "NUTRIENT":
        if (displayValue == "Limit Nutrient") return "LIMIT_NUTRIENT";
        if (displayValue == "Prefer Nutrient") return "PREFER_NUTRIENT";
        if (displayValue == "Increase Nutrient") return "INCREASE_NUTRIENT";
        if (displayValue == "Decrease Nutrient") return "DECREASE_NUTRIENT";
        if (displayValue == "Monitor Nutrient") return "MONITOR_NUTRIENT";
        return null;
      case "FOOD_CATEGORY":
        return displayValue == "Avoid Food Category" ? "AVOID_FOOD_CATEGORY" : "PREFER_FOOD_CATEGORY";
      case "FOOD_ITEM":
        return displayValue == "Avoid Food Item" ? "AVOID_FOOD_ITEM" : "PREFER_FOOD_ITEM";
      case "FOOD_TAG":
        return displayValue == "Avoid Food with Tag" ? "AVOID_FOOD_TAG" : "PREFER_FOOD_TAG";
      default: return null;
    }
  }

  Future<void> _fetchParameterTargetOptions(String parameterTargetType, {String? initialTargetValueToSet}) async {
    if (!mounted) return;
    setState(() => _isLoadingParameterTarget = true);
    List<String> options = [];
    try {
      String endpoint;
      // Assuming all these endpoints return a list of objects with a 'name' field,
      // or a list of strings for NUTRIENT.
      bool isNameBased = true; // Default assumption
      bool isNutrientList = false;

      switch (parameterTargetType) {
        case "ALLERGEN": endpoint = 'allergens'; break;
        case "INGREDIENT": endpoint = 'ingredients'; break;
        case "NUTRIENT":
          isNameBased = false; // Nutrients are a static list of strings
          isNutrientList = true;
          options = ["Calories", "Protein", "Carbohydrates", "Fat", "Saturated Fat", "Trans Fat", "Cholesterol", "Sodium", "Sugar", "Added Sugars", "Fiber", "Soluble Fiber", "Insoluble Fiber", "Potassium", "Calcium", "Iron", "Vitamin A", "Vitamin C", "Vitamin D", "Vitamin E", "Vitamin K", "Vitamin B6", "Vitamin B12", "Folate", "Magnesium", "Zinc", "Omega-3 Fatty Acids", "Omega-6 Fatty Acids", "Caffeine", "Alcohol"];
          if (mounted) setState(() => _isLoadingParameterTarget = false);
          // Set state with options and handle initialTargetValueToSet directly for static lists
          if (mounted) {
            setState(() {
              _parameterTargetOptions = options;
              if (initialTargetValueToSet != null && options.contains(initialTargetValueToSet)) {
                _formData.parameterTarget = initialTargetValueToSet;
              } else if (_formData.parameterTarget != null && !options.contains(_formData.parameterTarget)) {
                _formData.parameterTarget = null;
              }
            });
          }
          return; // Return early for static list
        case "FOOD_CATEGORY": endpoint = 'food_categories'; break; // Assuming returns list of strings or objects with 'name'
        case "FOOD_ITEM": endpoint = 'foods'; break;
        case "FOOD_TAG": endpoint = 'food_tags'; break; // Assuming returns list of strings or objects with 'name'
        default:
          if (mounted) setState(() => _isLoadingParameterTarget = false);
          return;
      }

      final response = await widget.httpService.get(endpoint);

      if (mounted && response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> details = response.data['details'] ?? [];
        if (details.isNotEmpty && details.first is String) { // Check if it's a list of strings
          options = List<String>.from(details.map((item) => item.toString()).where((name) => name.isNotEmpty));
        } else if (isNameBased) { // Assume list of objects with 'name'
          options = details.map((item) => item['name']?.toString() ?? '').where((name) => name.isNotEmpty).toList();
        }
      } else if (mounted) {
        print("Failed to load options for $parameterTargetType: ${response.data?['message'] ?? response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        print("Error fetching parameter target options for $parameterTargetType: $e");
      }
    }
    if (mounted) {
      setState(() {
        _parameterTargetOptions = options;
        _isLoadingParameterTarget = false;

        if (initialTargetValueToSet != null && options.contains(initialTargetValueToSet)) {
          _formData.parameterTarget = initialTargetValueToSet;
        } else if (_formData.parameterTarget != null && !options.contains(_formData.parameterTarget)) {
          _formData.parameterTarget = null;
        }
      });
    }
  }

  List<String> _getThresholdUnitOptions(String? selectedNutrient) {
    if (_formData.parameterTargetType == "NUTRIENT") {
      if (selectedNutrient == "Calories") {
        return ["calories/day", "calories/serving"];
      } else {
        return ["g/day", "mg/day", "mcg/day", "IU/day", "g/serving", "mg/serving", "mcg/serving", "% of total daily calories"];
      }
    }
    return [];
  }

  List<String> _getSeverityOptions(String? parameterTargetType, String? guidelineTypeValue) {
    if (parameterTargetType == null || guidelineTypeValue == null) return [];
    switch (parameterTargetType) {
      case "ALLERGEN": return ["Strict Avoid", "Avoid"];
      case "INGREDIENT":
        return guidelineTypeValue == "AVOID_INGREDIENT_NAME" ? ["Strict Avoid", "Avoid", "Limit"] : ["Recommended", "Encouraged"];
      case "NUTRIENT":
        if (guidelineTypeValue == "LIMIT_NUTRIENT" || guidelineTypeValue == "DECREASE_NUTRIENT") return ["Strict Limit", "Limit", "Moderate"];
        if (guidelineTypeValue == "PREFER_NUTRIENT" || guidelineTypeValue == "INCREASE_NUTRIENT") return ["Recommended", "Encouraged", "Ensure Adequacy"];
        if (guidelineTypeValue == "MONITOR_NUTRIENT") return ["Monitor"];
        return [];
      case "FOOD_CATEGORY":
        return guidelineTypeValue == "AVOID_FOOD_CATEGORY" ? ["Strict Avoid", "Avoid", "Limit"] : ["Recommended", "Encouraged"];
      case "FOOD_ITEM":
        return guidelineTypeValue == "AVOID_FOOD_ITEM" ? ["Strict Avoid", "Avoid", "Limit"] : ["Recommended", "Encouraged"];
      case "FOOD_TAG":
        return guidelineTypeValue == "AVOID_FOOD_TAG" ? ["Strict Avoid", "Avoid", "Limit"] : ["Recommended", "Encouraged"];
      default: return [];
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        key: ValueKey("$label-$value-${items.hashCode}"),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
        ),
        value: items.contains(value) ? value : null, // Ensure value is in items or set to null
        items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString()))).toList(),
        onChanged: isLoading ? null : onChanged,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: widget.formKey ?? GlobalKey<FormState>(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.onDelete != null)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete this guideline',
                  ),
                ),
              _buildDropdown<String>(
                label: "Parameter Target Type",
                value: _formData.parameterTargetType,
                items: _parameterTargetTypeOptions,
                onChanged: (val) => _onParameterTargetTypeChanged(val),
                validator: (val) => val == null ? 'Please select a type' : null,
              ),
              if (_formData.parameterTargetType != null) ...[
                _buildDropdown<String>(
                  label: "Guideline Type",
                  value: _formData.guidelineTypeDisplay,
                  items: _guidelineTypeDisplayOptions,
                  onChanged: (val) => _onGuidelineTypeChanged(val),
                  validator: (val) => val == null ? 'Please select a guideline type' : null,
                ),
                _buildDropdown<String>(
                  label: "Parameter Target",
                  value: _formData.parameterTarget,
                  items: _parameterTargetOptions,
                  onChanged: (val) {
                    _onParameterTargetChanged(val);
                  },
                  validator: (val) => val == null ? 'Please select a target' : null,
                  isLoading: _isLoadingParameterTarget,
                ),
              ],
              if (_showThresholdFields) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                      controller: _thresholdValueController,
                      decoration: InputDecoration(
                        labelText: 'Threshold Value',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      validator: (val) {
                        if (_showThresholdFields && (val == null || val.isEmpty)) {
                          return 'Please enter a threshold value';
                        }
                        return null;
                      }
                  ),
                ),
                _buildDropdown<String>(
                    label: "Threshold Unit",
                    value: _formData.thresholdUnit,
                    items: _thresholdUnitOptions,
                    onChanged: (val) => setState(() {
                      _formData.thresholdUnit = val;
                      widget.onChanged(_formData);
                    }),
                    validator: (val) {
                      if (_showThresholdFields && val == null) {
                        return 'Please select a unit';
                      }
                      return null;
                    }
                ),
              ],
              if (_formData.guidelineTypeValue != null)
                _buildDropdown<String>(
                  label: "Severity",
                  value: _formData.severity,
                  items: _severityOptions,
                  onChanged: (val) => setState(() {
                    _formData.severity = val;
                    widget.onChanged(_formData);
                  }),
                  validator: (val) => val == null ? 'Please select a severity' : null,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (val) => (val == null || val.isEmpty) ? 'Please enter a description' : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
