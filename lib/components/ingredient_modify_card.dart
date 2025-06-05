import 'package:flutter/material.dart';
import 'dart:async';
import '../http_service.dart'; // Assuming http_service.dart is in lib

class IngredientModifyCard extends StatefulWidget {
  final Map<String, dynamic> ingredient;
  final Function(Map<String, dynamic> updatedIngredient) onIngredientUpdated;

  const IngredientModifyCard({
    Key? key,
    required this.ingredient,
    required this.onIngredientUpdated,
  }) : super(key: key);

  @override
  _IngredientModifyCardState createState() => _IngredientModifyCardState();
}

class _IngredientModifyCardState extends State<IngredientModifyCard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _allergenSearchController = TextEditingController();

  Timer? _allergenSearchDebouncer;
  bool _isLoadingAllergens = false;
  List<Map<String, dynamic>> _dynamicAllergenOptions = [];
  List<String> _selectedAssociatedAllergens = [];

  bool _isSaving = false;
  final HttpService _httpService = HttpService();

  @override
  void initState() {
    super.initState();

    // Initialize selected allergens from the existing ingredient data
    final List<dynamic> allergensRaw = widget.ingredient['associated_allergens'] ?? [];
    _selectedAssociatedAllergens = allergensRaw.map((allergen) => allergen['name'] as String).toList();

    _allergenSearchController.addListener(_onAllergenSearchChanged);
  }

  @override
  void dispose() {
    _allergenSearchController.removeListener(_onAllergenSearchChanged);
    _allergenSearchController.dispose();
    _allergenSearchDebouncer?.cancel();
    super.dispose();
  }

  void _onAllergenSearchChanged() {
    if (_allergenSearchDebouncer?.isActive ?? false) _allergenSearchDebouncer!.cancel();
    _allergenSearchDebouncer = Timer(const Duration(milliseconds: 500), () {
      final query = _allergenSearchController.text.trim();
      if (query.isNotEmpty) {
        _fetchAllergens(query);
      } else {
        setState(() {
          _dynamicAllergenOptions = [];
          _isLoadingAllergens = false;
        });
      }
    });
  }

  Future<void> _fetchAllergens(String query) async {
    setState(() => _isLoadingAllergens = true);
    try {
      final response = await _httpService.get('allergens/$query'); // Endpoint for allergens
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final details = List<Map<String, dynamic>>.from(response.data['details']);
        setState(() {
          // Filter out allergens already selected
          _dynamicAllergenOptions = details.where((allergen) {
            return !_selectedAssociatedAllergens.contains(allergen['name']);
          }).toList();
        });
      } else {
        setState(() { _dynamicAllergenOptions = []; });
        // Optionally show a snackbar for fetch errors
      }
    } catch (e) {
      setState(() { _dynamicAllergenOptions = []; });
      // Optionally show a snackbar for fetch errors
    } finally {
      if (mounted) setState(() => _isLoadingAllergens = false);
    }
  }

  void _addAllergen(String allergenName) {
    if (!_selectedAssociatedAllergens.contains(allergenName)) {
      setState(() {
        _selectedAssociatedAllergens.add(allergenName);
        _allergenSearchController.clear(); // Clear search after adding
        _dynamicAllergenOptions = []; // Clear suggestions
      });
    }
  }

  void _removeAllergen(String allergenName) {
    setState(() {
      _selectedAssociatedAllergens.remove(allergenName);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    final Map<String, dynamic> updatedData = {
      'allergens': _selectedAssociatedAllergens, // Send list of names
    };

    try {
      final response = await _httpService.put(
        'ingredients/${widget.ingredient['id']}', // Endpoint for updating ingredient
        data: updatedData,
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        // Assuming the backend returns the updated ingredient object in 'details'
        final Map<String, dynamic> responseData = response.data['details'] ?? {};
        // Ensure the responseData includes the id and name if not returned by backend
        responseData['id'] = widget.ingredient['id'];
        responseData['name'] = widget.ingredient['name']; // Keep original name if not returned
        responseData['associated_allergens'] = _selectedAssociatedAllergens.map((name) => {'name': name}).toList(); // Use local allergens if not returned

        widget.onIngredientUpdated(responseData);
        if (mounted) Navigator.of(context).pop(true); // Indicate success
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.ingredient['name']} updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ingredient: ${response.data['message'] ?? 'Unknown error'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating ingredient: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container( // Wrap in Container to control size in AlertDialog
      width: double.maxFinite, // Allow dialog to be wide
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'Associated Allergens',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green.shade700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _allergenSearchController,
                decoration: InputDecoration(
                  labelText: 'Search Allergens',
                  hintText: 'e.g., Dairy, Peanuts',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _allergenSearchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _allergenSearchController.clear();
                      _dynamicAllergenOptions = []; // Clear suggestions immediately
                    },
                  )
                      : null,
                ),
              ),
              if (_isLoadingAllergens)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_allergenSearchController.text.isNotEmpty && _dynamicAllergenOptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Center(child: Text('No allergens found matching search.')),
                )
              else if (_dynamicAllergenOptions.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxHeight: 150), // Limit height of suggestions
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(top: 8.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _dynamicAllergenOptions.length,
                      itemBuilder: (context, index) {
                        final allergen = _dynamicAllergenOptions[index];
                        return ListTile(
                          title: Text(allergen['name']),
                          onTap: () => _addAllergen(allergen['name']),
                          dense: true,
                        );
                      },
                    ),
                  ),
              const SizedBox(height: 16),
              Text(
                'Selected Allergens:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _selectedAssociatedAllergens.map((allergenName) {
                  return Chip(
                    label: Text(allergenName),
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                    onDeleted: () => _removeAllergen(allergenName),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: TextStyle(color: Colors.green.shade700, fontSize: 13),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: _isSaving
                        ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.save_alt_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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