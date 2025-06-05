import 'package:flutter/material.dart';
import 'dart:async';
import '../http_service.dart'; // Assuming http_service.dart is in lib
import '../components/ingredient_card.dart'; // Import the ingredient card
import '../components/ingredient_modify_card.dart'; // Card for modifying
import '../components/ingredient_add_card.dart'; // Card for adding

class IngredientScreen extends StatefulWidget {
  const IngredientScreen({Key? key}) : super(key: key);

  @override
  _IngredientScreenState createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  final HttpService _httpService = HttpService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _filteredIngredients = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchIngredients(); // Fetch all ingredients on init
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchIngredients({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // If query is empty, fetch all. Otherwise, search.
      // The API might expect "ingredients/" for all, or "ingredients"
      // Adjust endpoint as per your API spec for fetching all.
      final endpoint = query.isEmpty ? 'ingredients' : 'ingredients/$query';
      final response = await _httpService.get(endpoint);

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> details = response.data['details'];
        setState(() {
          _filteredIngredients = List<Map<String, dynamic>>.from(details);
        });
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to load ingredients';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
    } finally {
      if (mounted) { // Ensure widget is still mounted before calling setState
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchIngredients(query: _searchController.text.trim());
    });
  }

  void _handleAddIngredient() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Ingredient'),
          contentPadding: const EdgeInsets.all(0), // IngredientAddCard handles padding
          content: IngredientAddCard(
            onIngredientAdded: (newIngredient) {
              _fetchIngredients(query: _searchController.text.trim()); // Refresh list
            },
          ),
        );
      },
    );
  }

  void _handleUpdateIngredient(Map<String, dynamic> ingredientToUpdate) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update ${ingredientToUpdate['name']}'),
          contentPadding: const EdgeInsets.all(0),
          content: IngredientModifyCard(
            ingredient: ingredientToUpdate,
            onIngredientUpdated: (updatedIngredient) {
              _fetchIngredients(query: _searchController.text.trim()); // Refresh list
            },
          ),
        );
      },
    );
    // if (result == true) { // This check is useful if IngredientModifyCard pops with a value
    //   _fetchIngredients(query: _searchController.text.trim());
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Ingredients',
                hintText: 'e.g., Salmon, Salt...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchIngredients(); // Fetch all when search is cleared
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
                : _filteredIngredients.isEmpty
                ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No ingredients found. Try adding some!'
                    : 'No ingredients found matching "${_searchController.text}".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              itemCount: _filteredIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = _filteredIngredients[index];
                final List<dynamic> allergensRaw = ingredient['associated_allergens'] ?? [];
                final List<String> allergens = allergensRaw.map((allergen) => allergen['name'] as String).toList();

                return IngredientCard(
                  name: ingredient['name'] ?? 'Unknown Ingredient',
                  associatedAllergens: allergens,
                  onUpdate: () => _handleUpdateIngredient(ingredient),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddIngredient,
        icon: const Icon(Icons.add),
        label: const Text('Add Ingredient'),
        backgroundColor: Colors.green, // Using green for ingredients
        foregroundColor: Colors.white,
      ),
    );
  }
}