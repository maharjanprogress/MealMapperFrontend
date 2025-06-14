import 'package:flutter/material.dart';
import '../../http_service.dart';
import '../../components/medical_guideline_item_form.dart';

class UpdateMedicalConditionTab extends StatefulWidget {
  final Map<String, dynamic> initialMedicalCondition; // Contains 'name' to fetch details
  final VoidCallback onMedicalConditionUpdated;
  final VoidCallback onCancel;

  const UpdateMedicalConditionTab({
    Key? key,
    required this.initialMedicalCondition,
    required this.onMedicalConditionUpdated,
    required this.onCancel,
  }) : super(key: key);

  @override
  _UpdateMedicalConditionTabState createState() => _UpdateMedicalConditionTabState();
}

class _UpdateMedicalConditionTabState extends State<UpdateMedicalConditionTab> {
  final _formKey = GlobalKey<FormState>(); // For the main condition name
  late TextEditingController _conditionNameController;
  List<MedicalGuidelineItemFormData> _guidelineFormsData = [];
  List<GlobalKey<FormState>> _guidelineItemFormKeys = [];

  bool _isSaving = false;
  bool _isLoadingDetails = true;
  String _errorMessage = '';
  final HttpService _httpService = HttpService();

  @override
  void initState() {
    super.initState();
    _conditionNameController = TextEditingController(text: widget.initialMedicalCondition['name'] ?? '');
    _conditionNameController.addListener(() {
      if (mounted) {
        setState(() {
          for (var formData in _guidelineFormsData) {
            formData.conditionName = _conditionNameController.text;
          }
        });
      }
    });
    _fetchGuidelineDetails();
  }

  @override
  void dispose() {
    _conditionNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchGuidelineDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDetails = true;
      _errorMessage = '';
    });
    try {
      final conditionName = _conditionNameController.text; // Use the controller's current text
      if (conditionName.isEmpty) {
        // This case should ideally be prevented by how UpdateMedicalConditionTab is invoked
        _errorMessage = "Condition name is missing for fetching details.";
        if (mounted) setState(() => _isLoadingDetails = false);
        return;
      }
      final response = await _httpService.get('medical_condition_guidelines/condition/$conditionName');

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> details = response.data['details'] ?? [];
        _guidelineFormsData = details.map((item) {
          // Helper to derive display value from backend value
          String? deriveGuidelineTypeDisplay(String? backendValue, String? paramType) {
            if (backendValue == null || paramType == null) return null;

            switch (paramType) {
              case "ALLERGEN":
                if (backendValue == "AVOID_ALLERGEN_NAME") return "Avoid Allergen";
                break;
              case "INGREDIENT":
                if (backendValue == "AVOID_INGREDIENT_NAME") return "Avoid Ingredient";
                if (backendValue == "PREFER_INGREDIENT_NAME") return "Prefer Ingredient";
                break;
              case "NUTRIENT":
                if (backendValue == "LIMIT_NUTRIENT") return "Limit Nutrient";
                if (backendValue == "PREFER_NUTRIENT") return "Prefer Nutrient";
                if (backendValue == "INCREASE_NUTRIENT") return "Increase Nutrient";
                if (backendValue == "DECREASE_NUTRIENT") return "Decrease Nutrient";
                if (backendValue == "MONITOR_NUTRIENT") return "Monitor Nutrient";
                break;
              case "FOOD_CATEGORY":
                if (backendValue == "AVOID_FOOD_CATEGORY") return "Avoid Food Category";
                if (backendValue == "PREFER_FOOD_CATEGORY") return "Prefer Food Category";
                break;
              case "FOOD_ITEM":
                if (backendValue == "AVOID_FOOD_ITEM") return "Avoid Food Item";
                if (backendValue == "PREFER_FOOD_ITEM") return "Prefer Food Item";
                break;
              case "FOOD_TAG":
                if (backendValue == "AVOID_FOOD_TAG") return "Avoid Food with Tag";
                if (backendValue == "PREFER_FOOD_TAG") return "Prefer Food with Tag";
                break;
            }
            // Fallback if no match, could be the backend value itself if it's meant to be displayed
            // or null if it strictly needs mapping.
            // Fallback if no match, could be the backend value itself if it's meant to be displayed
            // or null if it strictly needs mapping.
            return null; // Fallback
          }

          return MedicalGuidelineItemFormData(
            guidelineId: item['guideline_id']?.toString(),
            conditionName: item['condition_name'] ?? _conditionNameController.text,
            parameterTargetType: item['parameter_target_type'],
            guidelineTypeValue: item['guideline_type'],
            // Use the derived display value. If null, MedicalGuidelineItemForm might try to auto-select or show empty.
            guidelineTypeDisplay: deriveGuidelineTypeDisplay(item['guideline_type'], item['parameter_target_type']),
            parameterTarget: item['parameter_target'],
            thresholdValue: item['threshold_value']?.toString(),
            thresholdUnit: item['threshold_unit'],
            severity: item['severity'],
            description: item['description'] ?? '',
            isDeleted: false, // Initially not deleted
          );
        }).toList();
        _guidelineItemFormKeys = List.generate(_guidelineFormsData.length, (_) => GlobalKey<FormState>());
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to load guideline details.';
      }
    } catch (e) {
      if (!mounted) return;
      _errorMessage = 'Error fetching details: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  void _addGuidelineForm() {
    setState(() {
      _guidelineFormsData.add(MedicalGuidelineItemFormData(
        conditionName: _conditionNameController.text,
        description: '',
        isDeleted: false, // New items are not deleted
      ));
      _guidelineItemFormKeys.add(GlobalKey<FormState>());
    });
  }

  void _deleteGuidelineForm(int index) {
    setState(() {
      // If the item has a guidelineId, it's an existing item, so mark for deletion.
      // If not, it's a newly added item (not yet saved), so remove it from the list.
      if (_guidelineFormsData[index].guidelineId != null && _guidelineFormsData[index].guidelineId!.isNotEmpty) {
        _guidelineFormsData[index].isDeleted = true;
        // Optionally, trigger a visual change or re-render if needed
      } else {
        _guidelineFormsData.removeAt(index);
        _guidelineItemFormKeys.removeAt(index);
      }
    });
  }

  Future<void> _updateMedicalCondition() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    bool allItemsValid = true;
    for (var itemFormKey in _guidelineItemFormKeys) {
      // Only validate forms that are not marked for deletion
      int itemIndex = _guidelineItemFormKeys.indexOf(itemFormKey);
      if (!_guidelineFormsData[itemIndex].isDeleted) {
        if (!(itemFormKey.currentState?.validate() ?? false)) {
          allItemsValid = false;
          break;
        }
      }
    }

    if (!allItemsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct errors in guideline details.'), backgroundColor: Colors.red),
      );
      return;
    }

    final String currentConditionName = _conditionNameController.text.trim();
    for (var formData in _guidelineFormsData) {
      formData.conditionName = currentConditionName;
    }

    final List<Map<String, dynamic>> detailsPayload = _guidelineFormsData
        .map((formData) => formData.toJson())
        .toList();

    if (detailsPayload.where((item) => item['delete'] == false).isEmpty && detailsPayload.any((item) => item['delete'] == true)) {
      // All existing items are marked for deletion, and no new items are added.
      // This scenario might need special handling or confirmation.
      // For now, proceed with the bulk request.
    } else if (detailsPayload.where((item) => item['delete'] == false).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add or keep at least one guideline detail.'), backgroundColor: Colors.orange),
      );
      return;
    }


    final Map<String, dynamic> requestBody = {
      'details': detailsPayload,
    };

    setState(() => _isSaving = true);
    try {
      final response = await _httpService.post(
        'update_add_in_bulk/medical_condition_guidelines',
        data: requestBody,
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final responseDetails = response.data['details'];
        List<dynamic> createdItems = responseDetails?['created'] as List<dynamic>? ?? [];
        List<dynamic> updatedItems = responseDetails?['updated'] as List<dynamic>? ?? [];
        List<dynamic> deletedItems = responseDetails?['deleted'] as List<dynamic>? ?? [];
        List<dynamic> errorItems = responseDetails?['errors'] as List<dynamic>? ?? [];
        int errorCount = errorItems.length; // Define errorCount here

        String summaryMessage = "Operation processed. ";
        if (createdItems.isNotEmpty) summaryMessage += "${createdItems.length} created. ";
        if (updatedItems.isNotEmpty) summaryMessage += "${updatedItems.length} updated. ";
        if (deletedItems.isNotEmpty) summaryMessage += "${deletedItems.length} deleted. ";
        if (errorItems.isNotEmpty) summaryMessage += "${errorItems.length} error(s).";
        if (createdItems.isEmpty && updatedItems.isEmpty && deletedItems.isEmpty && errorItems.isEmpty) {
          summaryMessage = response.data['message'] ?? "No changes processed.";
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(summaryMessage),
              backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          if (errorCount == 0) {
            widget.onMedicalConditionUpdated();
          } else {
            // Optionally, re-fetch to show the current state after partial success/failure
            _fetchGuidelineDetails();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Failed to process guidelines. Status: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating medical condition: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }
    // Show error message if fetching failed and there's no data to display
    if (_errorMessage.isNotEmpty && _guidelineFormsData.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _fetchGuidelineDetails, child: const Text("Retry"))
              ],
            ),
          )
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _conditionNameController,
                decoration: InputDecoration(
                  labelText: 'Condition Name',
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a condition name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Guideline Details:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
              if (_errorMessage.isNotEmpty && _guidelineFormsData.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.orange)),
                ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _guidelineFormsData.length,
                itemBuilder: (context, index) {
                  final bool isMarkedForDeletion = _guidelineFormsData[index].isDeleted;
                  // Do not build form for items that were newly added and then "deleted" before saving
                  if (_guidelineFormsData[index].guidelineId == null && isMarkedForDeletion) {
                    return const SizedBox.shrink();
                  }

                  return Opacity(
                    opacity: isMarkedForDeletion ? 0.5 : 1.0,
                    child: MedicalGuidelineItemForm(
                      key: ValueKey(_guidelineFormsData[index].guidelineId ?? 'existing_or_new_guideline_$index'),
                      formKey: _guidelineItemFormKeys[index],
                      initialData: _guidelineFormsData[index],
                      httpService: _httpService,
                      onChanged: (updatedData) {
                        if (mounted) {
                          _guidelineFormsData[index] = updatedData;
                        }
                      },
                      onDelete: !isMarkedForDeletion // Only allow delete if not already marked
                          ? () => _deleteGuidelineForm(index)
                          : null, // Disable delete button if already marked
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Guideline Detail'),
                    onPressed: _addGuidelineForm,
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: _isSaving
                        ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.save_alt_outlined),
                    label: Text(_isSaving ? 'Updating...' : 'Update Condition'),
                    onPressed: _isSaving ? null : _updateMedicalCondition,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
