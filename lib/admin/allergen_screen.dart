// c:\Users\progr\AndroidStudioProjects\meal_mapper\lib\admin\allergen_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../http_service.dart'; // Assuming http_service.dart is in lib
import '../components/allergen_card.dart'; // Original card for display
import '../components/allergen_modify_card.dart'; // Card for modifying
import '../components/allergen_add_card.dart'; // Card for adding

class AllergenScreen extends StatefulWidget {
  const AllergenScreen({Key? key}) : super(key: key);

  @override
  _AllergenScreenState createState() => _AllergenScreenState();
}

class _AllergenScreenState extends State<AllergenScreen> {
  final HttpService _httpService = HttpService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // List<Map<String, dynamic>> _allergens = []; // Not strictly needed if _filteredAllergens is always primary
  List<Map<String, dynamic>> _filteredAllergens = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllergens();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllergens({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final endpoint = query.isEmpty ? 'allergens' : 'allergens/$query';
      final response = await _httpService.get(endpoint);

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> details = response.data['details'];
        setState(() {
          _filteredAllergens = List<Map<String, dynamic>>.from(details);
        });
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to load allergens';
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
      _fetchAllergens(query: _searchController.text.trim());
    });
  }

  void _handleAddAllergen() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Allergen'),
          contentPadding: const EdgeInsets.all(0), // AllergenAddCard handles padding
          content: AllergenAddCard(
            onAllergenAdded: (newAllergen) {
              _fetchAllergens(query: _searchController.text.trim()); // Refresh list
            },
          ),
        );
      },
    );
    // if (result == true) { // This check is useful if AllergenAddCard pops with a value
    //   _fetchAllergens(query: _searchController.text.trim());
    // }
  }

  void _handleUpdateAllergen(Map<String, dynamic> allergenToUpdate) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Allergen: ${allergenToUpdate['name']}'),
          contentPadding: const EdgeInsets.all(0),
          content: AllergenModifyCard(
            allergen: allergenToUpdate,
            onAllergenUpdated: (updatedAllergen) {
              _fetchAllergens(query: _searchController.text.trim()); // Refresh list
            },
          ),
        );
      },
    );
    // if (result == true) { // This check is useful if AllergenModifyCard pops with a value
    //   _fetchAllergens(query: _searchController.text.trim());
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
                labelText: 'Search Allergens',
                hintText: 'e.g., Peanuts, Dairy...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchAllergens(); // Fetch all when search is cleared
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
                : _filteredAllergens.isEmpty
                ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No allergens found. Try adding some!'
                    : 'No allergens found matching "${_searchController.text}".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              itemCount: _filteredAllergens.length,
              itemBuilder: (context, index) {
                final allergen = _filteredAllergens[index];
                final List<dynamic> ingredientsRaw = allergen['associated_ingredients'] ?? [];
                final List<String> ingredients = ingredientsRaw.map((ing) => ing['name'] as String).toList();

                return AllergenCard(
                  name: allergen['name'] ?? 'Unknown Allergen',
                  description: allergen['description'] ?? 'No description available.',
                  associatedIngredients: ingredients,
                  onUpdate: () => _handleUpdateAllergen(allergen),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddAllergen,
        icon: const Icon(Icons.add),
        label: const Text('Add Allergen'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
