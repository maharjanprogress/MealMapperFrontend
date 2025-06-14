import 'package:flutter/material.dart';
import 'dart:async';
import '../../http_service.dart';
import '../../components/medical_condition_card.dart';

class ViewMedicalConditionsTab extends StatefulWidget {
  final Function(Map<String, dynamic> medicalCondition) onUpdatePressed;

  const ViewMedicalConditionsTab({
    Key? key,
    required this.onUpdatePressed,
  }) : super(key: key);

  @override
  _ViewMedicalConditionsTabState createState() => _ViewMedicalConditionsTabState();
}

class _ViewMedicalConditionsTabState extends State<ViewMedicalConditionsTab> {
  final HttpService _httpService = HttpService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _medicalConditions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMedicalConditions(); // Fetch initial list (or show empty state)
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchMedicalConditions({String query = ''}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _medicalConditions = []; // Clear previous results
    });

    try {
      // Adjust endpoint based on whether there's a query.
      // Assuming 'medical_condition_guidelines' without a query returns all,
      // or you might need a different endpoint for 'get all'.
      // Based on the example response, 'medical_condition_guidelines/{query}' seems to handle search.
      // Let's assume an empty query fetches all or the API handles it gracefully.
      final endpoint = query.isEmpty ? 'medical_condition_guidelines' : 'medical_condition_guidelines/$query';
      final response = await _httpService.get(endpoint);

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> details = response.data['details'];
        setState(() {
          _medicalConditions = List<Map<String, dynamic>>.from(details);
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to load medical conditions';
          _medicalConditions = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _medicalConditions = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchMedicalConditions(query: _searchController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Medical Conditions',
              hintText: 'e.g., Hypertension, Diabetes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _fetchMedicalConditions(); // Fetch all when search is cleared
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
              ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 16)),
              ))
              : _medicalConditions.isEmpty
              ? Center(
            child: Text(
              _searchController.text.isEmpty
                  ? 'No medical conditions found.'
                  : 'No medical conditions found matching "${_searchController.text}".',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: Colors.grey[600]),
            ),
          )
              : ListView.builder(
            itemCount: _medicalConditions.length,
            itemBuilder: (context, index) {
              final condition = _medicalConditions[index];
              // Ensure 'descriptions' is a List<String>
              final List<String> descriptions = (condition['descriptions'] as List<dynamic>?)
                  ?.map((desc) => desc.toString())
                  .toList() ?? [];
              final conditionNameForUpdate = condition['name'] ?? 'Unknown Condition';

              return MedicalConditionCard(
                name: conditionNameForUpdate,
                descriptions: descriptions,
                // Pass only the necessary data, primarily the name for fetching details
                onUpdate: () => widget.onUpdatePressed({'name': conditionNameForUpdate}),
              );
            },
          ),
        ),
      ],
    );
  }
}