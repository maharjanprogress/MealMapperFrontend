import 'package:flutter/material.dart';
import 'dart:async';
import '../http_service.dart'; // Assuming http_service.dart is in lib

class AllergenAddCard extends StatefulWidget {
  final Function(Map<String, dynamic> newAllergen) onAllergenAdded;

  const AllergenAddCard({
    Key? key,
    required this.onAllergenAdded,
  }) : super(key: key);

  @override
  _AllergenAddCardState createState() => _AllergenAddCardState();
}

class _AllergenAddCardState extends State<AllergenAddCard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
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
    _ingredientSearchController.addListener(_onIngredientSearchChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _createAllergen() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    final Map<String, dynamic> newAllergenData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'ingredients': _selectedAssociatedIngredients, // Send list of names
    };

    try {
      final response = await _httpService.post(
        'allergens',
        data: newAllergenData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) { // 201 Created is typical
        // Assuming the backend returns the full new object with ID in 'details'
        final Map<String, dynamic> responseData = response.data['details'] ?? {};
        // Ensure responseData has necessary fields, potentially using local data if backend doesn't return full object
        responseData['name'] = _nameController.text;
        responseData['description'] = _descriptionController.text;
        responseData['associated_ingredients'] = _selectedAssociatedIngredients.map((name) => {'name': name}).toList();

        widget.onAllergenAdded(responseData);
        if (mounted) Navigator.of(context).pop(true); // Indicate success
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_nameController.text} added successfully!'), backgroundColor: Colors.green),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add allergen: ${response.data['message'] ?? 'Unknown error'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding allergen: $e'), backgroundColor: Colors.red),
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Allergen Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_important_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the allergen name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                        : const Icon(Icons.add_circle_outline),
                    label: Text(_isSaving ? 'Adding...' : 'Add Allergen'),
                    onPressed: _isSaving ? null : _createAllergen,
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