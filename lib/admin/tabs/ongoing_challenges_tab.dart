import 'package:flutter/material.dart';
import 'dart:async';
import '../../http_service.dart'; // Adjust path if necessary
import '../../components/admin_challenge_card.dart'; // Adjust path if necessary
// You might need to add intl package to your pubspec.yaml for DateFormat
import '../../components/challenge_modify_form.dart';

class OngoingChallengesTab extends StatefulWidget {
  const OngoingChallengesTab({Key? key}) : super(key: key);

  @override
  _OngoingChallengesTabState createState() => _OngoingChallengesTabState();
}

class _OngoingChallengesTabState extends State<OngoingChallengesTab> {
  final HttpService _httpService = HttpService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _ongoingChallenges = [];
  bool _isLoadingChallenges = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOngoingChallenges(); // Fetch initial list
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchOngoingChallenges({String query = ''}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingChallenges = true;
      _errorMessage = '';
    });

    try {
      // If query is empty, fetch all. Otherwise, search.
      // The API might expect "allOngoingChallenge/" for all.
      final endpoint = query.isEmpty ? 'allOngoingChallenge' : 'allOngoingChallenge/$query';
      final response = await _httpService.get(endpoint);

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> details = response.data['details'];
        setState(() {
          _ongoingChallenges = List<Map<String, dynamic>>.from(details);
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to load challenges';
          _ongoingChallenges = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _ongoingChallenges = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChallenges = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchOngoingChallenges(query: _searchController.text.trim());
    });
  }

  void _handleUpdateChallenge(Map<String, dynamic> challenge) async {
    final challengeId = challenge['id'] as int?;
    if (challengeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge ID is missing.'), backgroundColor: Colors.red),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Challenge: ${challenge['title'] ?? 'Challenge'}'),
          contentPadding: const EdgeInsets.all(0), // Form handles padding
          content: ChallengeModifyForm(
            challengeId: challengeId,
            onChallengeUpdated: () {
              _fetchOngoingChallenges(query: _searchController.text.trim()); // Refresh list
            },
          ),
        );
      },
    );
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
              labelText: 'Search Ongoing Challenges',
              hintText: 'Enter title or description keywords...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _fetchOngoingChallenges(); // Fetch all when search is cleared
                },
              )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _isLoadingChallenges
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
              : _ongoingChallenges.isEmpty
              ? Center(
            child: Text(
              _searchController.text.isEmpty
                  ? 'No ongoing challenges found.'
                  : 'No challenges found matching "${_searchController.text}".',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: Colors.grey[600]),
            ),
          )
              : ListView.builder(
            itemCount: _ongoingChallenges.length,
            itemBuilder: (context, index) {
              final challenge = _ongoingChallenges[index];
              return AdminChallengeCard(
                title: challenge['title'] ?? 'No Title',
                description: challenge['description'] ?? 'No Description',
                rewardPoints: challenge['reward_points'] ?? 0,
                difficulty: challenge['difficulty'] ?? 'Unknown',
                deadline: challenge['deadline'] ?? DateTime.now().toIso8601String(),
                challengeId: challenge['id'] ?? 0, // Ensure ID is passed
                onUpdate: () => _handleUpdateChallenge(challenge),
              );
            },
          ),
        ),
      ],
    );
  }
}