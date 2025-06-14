import 'package:flutter/material.dart';
import '../../http_service.dart';
import '../../components/medical_guideline_item_form.dart';

class AddMedicalConditionTab extends StatefulWidget {
  final VoidCallback onMedicalConditionSaved;
  final VoidCallback onCancel;

  const AddMedicalConditionTab({
    Key? key,
    required this.onMedicalConditionSaved,
    required this.onCancel,
  }) : super(key: key);

  @override
  _AddMedicalConditionTabState createState() => _AddMedicalConditionTabState();
}

class _AddMedicalConditionTabState extends State<AddMedicalConditionTab> {
  final _formKey = GlobalKey<FormState>(); // For the main condition name
  late TextEditingController _conditionNameController;
  List<MedicalGuidelineItemFormData> _guidelineFormsData = [];
  List<GlobalKey<FormState>> _guidelineItemFormKeys = [];

  bool _isSaving = false;
  final HttpService _httpService = HttpService();

  @override
  void initState() {
    super.initState();
    _conditionNameController = TextEditingController();
    _conditionNameController.addListener(() {
      // Update condition name for all guideline forms
      // This ensures that if the user types the condition name *after* adding some guideline forms,
      // those forms get the updated name.
      if (mounted) {
        setState(() {
          for (var formData in _guidelineFormsData) {
            formData.conditionName = _conditionNameController.text;
          }
        });
      }
    });
    // Start with one empty guideline form
    _addGuidelineForm();
  }

  @override
  void dispose() {
    _conditionNameController.dispose();
    super.dispose();
  }

  void _addGuidelineForm() {
    setState(() {
      _guidelineFormsData.add(MedicalGuidelineItemFormData(
        conditionName: _conditionNameController.text, // Use current name
        description: '', // Start with an empty description
      ));
      _guidelineItemFormKeys.add(GlobalKey<FormState>());
    });
  }

  void _removeGuidelineForm(int index) {
    // Only allow removal if there's more than one form
    if (_guidelineFormsData.length > 1) {
      setState(() {
        _guidelineFormsData.removeAt(index);
        _guidelineItemFormKeys.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Must have at least one guideline detail.')),
      );
    }
  }

  Future<void> _addMedicalCondition() async {
    // Validate the main condition name
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Validate all individual guideline item forms
    bool allItemsValid = true;
    for (var itemFormKey in _guidelineItemFormKeys) {
      if (!(itemFormKey.currentState?.validate() ?? false)) {
        allItemsValid = false;
        break;
      }
    }

    if (!allItemsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct errors in guideline details.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Ensure all formData objects have the latest condition name
    final String currentConditionName = _conditionNameController.text.trim();
    for (var formData in _guidelineFormsData) {
      formData.conditionName = currentConditionName;
    }

    final List<Map<String, dynamic>> detailsPayload = _guidelineFormsData.map((formData) {
      // For new items, guideline_id and delete flag are not needed.
      // The toJson method in MedicalGuidelineItemFormData should ideally handle this,
      // but we can explicitly remove them here if necessary or ensure toJson does.
      var json = formData.toJson();
      json.remove('guideline_id'); // Ensure no guideline_id for new items
      json.remove('delete');     // Ensure no delete flag for new items
      return json;
    }).toList();

    if (detailsPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one guideline detail.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final Map<String, dynamic> requestBody = {
      'details': detailsPayload,
    };

    setState(() => _isSaving = true);
    try {
      final response = await _httpService.post(
        'update_add_in_bulk/medical_condition_guidelines', // Using the bulk endpoint
        data: requestBody,
      );

      // For bulk operations, a 200 OK with details of created/updated/deleted is common
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final responseDetails = response.data['details'];
        List<dynamic> createdItems = responseDetails?['created'] as List<dynamic>? ?? [];
        List<dynamic> errorItems = responseDetails?['errors'] as List<dynamic>? ?? [];
        int createdCount = createdItems.length;
        int errorCount = errorItems.length;

        String summaryMessage = "Operation processed. ";
        if (createdCount > 0) summaryMessage += "$createdCount guideline(s) marked for creation. ";
        if (errorCount > 0) summaryMessage += "$errorCount error(s).";
        if (createdCount == 0 && errorCount == 0) summaryMessage = response.data['message'] ?? "No changes processed.";

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(summaryMessage),
              backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
            ),
          );
          if (errorCount == 0) {
            widget.onMedicalConditionSaved(); // Notify parent to refresh and switch view
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Failed to add medical condition. Status: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding medical condition: $e'), backgroundColor: Colors.red),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey, // Key for the overall form (mainly for condition name)
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
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _guidelineFormsData.length,
                itemBuilder: (context, index) {
                  return MedicalGuidelineItemForm(
                    // Use a unique key that changes if the item is truly different,
                    // or if its position in a list of dynamic items matters.
                    // For new items, an index-based key is usually fine.
                    key: ValueKey('new_guideline_form_$index'),
                    formKey: _guidelineItemFormKeys[index], // Pass the specific key for this item form
                    initialData: _guidelineFormsData[index],
                    httpService: _httpService,
                    onChanged: (updatedData) {
                      // This callback updates the central list of form data.
                      // No setState needed here if MedicalGuidelineItemForm handles its own internal state
                      // and only calls this when data is considered "final" for that field.
                      // However, if parent needs to react to any change, setState might be needed.
                      if (mounted) {
                        _guidelineFormsData[index] = updatedData;
                      }
                    },
                    // Allow removal if more than one form exists
                    onDelete: _guidelineFormsData.length > 1 ? () => _removeGuidelineForm(index) : null,
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
                    label: Text(_isSaving ? 'Adding...' : 'Add Condition'),
                    onPressed: _isSaving ? null : _addMedicalCondition,
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
