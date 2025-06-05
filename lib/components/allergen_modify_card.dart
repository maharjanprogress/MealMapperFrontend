import 'package:flutter/material.dart';
import 'dart:async';
import '../http_service.dart'; // Assuming http_service.dart is in lib

class AllergenModifyCard extends StatefulWidget {
  final Map<String, dynamic> allergen;
  final Function(Map<String, dynamic> updatedAllergen) onAllergenUpdated;

  const AllergenModifyCard({
    Key? key,
    required this.allergen,
    required this.onAllergenUpdated,
  }) : super(key: key);

  @override
  _AllergenModifyCardState createState() => _AllergenModifyCardState();
}

class _AllergenModifyCardState extends State<AllergenModifyCard> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  final TextEditingController _ingredientSearchController = TextEditingController();

  Timer? _ingredientSearchDebouncer;
  bool _isLoadingIngredients = false;
  List<Map<String, dynamic>> _dynamicIngredientOptions = [];
  List<String> _selectedAssociatedIngredients = [];

  bool _isSaving = false;
  final HttpService _httpService = HttpService();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.allergen['description'] ?? '');

    // Initialize selected ingredients from the existing allergen data
    final List<dynamic> ingredientsRaw = widget.allergen['associated_ingredients'] ?? [];
    _selectedAssociatedIngredients = ingredientsRaw.map((ing) => ing['name'] as String).toList();

    _ingredientSearchController.addListener(_onIngredientSearchChanged);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _ingredientSearchController.removeListener(_onIngredientSearchChanged);
    _ingredientSearchController.dispose();
    _ingredientSearchDebouncer?.cancel();
    super.dispose();
  }

  void _onIngredientSearchChanged() {
    if (_ingredientSearchDebouncer?.isActive ?? false) _ingredientSearchDebouncer!.cancel();
    _ingredientSearchDebouncer = Timer(const Duration(milliseconds: 500), () {
      final query = _ingredientSearchController.text.trim();
      if (query.isNotEmpty) {
        _fetchIngredients(query);
      } else {
        setState(() {
          _dynamicIngredientOptions = [];
          _isLoadingIngredients = false;
        });
      }
    });
  }

  Future<void> _fetchIngredients(String query) async {
    setState(() => _isLoadingIngredients = true);
    try {
      final response = await _httpService.get('ingredients/$query');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final details = List<Map<String, dynamic>>.from(response.data['details']);
        setState(() {
          // Filter out ingredients already selected
          _dynamicIngredientOptions = details.where((ingredient) {
            return !_selectedAssociatedIngredients.contains(ingredient['name']);
          }).toList();
        });
      } else {
        setState(() { _dynamicIngredientOptions = []; });
        // Optionally show a snackbar for fetch errors
      }
    } catch (e) {
      setState(() { _dynamicIngredientOptions = []; });
      // Optionally show a snackbar for fetch errors
    } finally {
      if (mounted) setState(() => _isLoadingIngredients = false);
    }
  }

  void _addIngredient(String ingredientName) {
    if (!_selectedAssociatedIngredients.contains(ingredientName)) {
      setState(() {
        _selectedAssociatedIngredients.add(ingredientName);
        _ingredientSearchController.clear(); // Clear search after adding
        _dynamicIngredientOptions = []; // Clear suggestions
      });
    }
  }

  void _removeIngredient(String ingredientName) {
    setState(() {
      _selectedAssociatedIngredients.remove(ingredientName);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    final Map<String, dynamic> updatedData = {
      'description': _descriptionController.text,
      'ingredients': _selectedAssociatedIngredients, // Send list of names
    };

    try {
      final response = await _httpService.put(
        'allergens/${widget.allergen['id']}',
        data: updatedData,
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        // Assuming the backend returns the updated allergen object in 'details'
        final Map<String, dynamic> responseData = response.data['details'] ?? {};
        // Ensure the responseData includes the id and name if not returned by backend
        responseData['id'] = widget.allergen['id'];
        responseData['name'] = widget.allergen['name']; // Keep original name if not returned
        responseData['description'] = _descriptionController.text; // Use local description if not returned
        responseData['associated_ingredients'] = _selectedAssociatedIngredients.map((name) => {'name': name}).toList(); // Use local ingredients if not returned

        widget.onAllergenUpdated(responseData);
        if (mounted) Navigator.of(context).pop(true); // Indicate success
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.allergen['name']} updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update allergen: ${response.data['message'] ?? 'Unknown error'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating allergen: $e'), backgroundColor: Colors.red),
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
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
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
              Text(
                'Associated Ingredients',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.teal.shade700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ingredientSearchController,
                decoration: InputDecoration(
                  labelText: 'Search Ingredients',
                  hintText: 'e.g., Milk, Peanut',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _ingredientSearchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _ingredientSearchController.clear();
                      _dynamicIngredientOptions = []; // Clear suggestions immediately
                    },
                  )
                      : null,
                ),
              ),
              if (_isLoadingIngredients)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_ingredientSearchController.text.isNotEmpty && _dynamicIngredientOptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Center(child: Text('No ingredients found matching search.')),
                )
              else if (_dynamicIngredientOptions.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxHeight: 150), // Limit height of suggestions
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(top: 8.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _dynamicIngredientOptions.length,
                      itemBuilder: (context, index) {
                        final ingredient = _dynamicIngredientOptions[index];
                        return ListTile(
                          title: Text(ingredient['name']),
                          onTap: () => _addIngredient(ingredient['name']),
                          dense: true,
                        );
                      },
                    ),
                  ),
              const SizedBox(height: 16),
              Text(
                'Selected Ingredients:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _selectedAssociatedIngredients.map((ingredientName) {
                  return Chip(
                    label: Text(ingredientName),
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                    onDeleted: () => _removeIngredient(ingredientName),
                    backgroundColor: Colors.teal.shade50,
                    labelStyle: TextStyle(color: Colors.teal.shade700, fontSize: 13),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
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