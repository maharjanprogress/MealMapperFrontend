// challenges_screen.dart
import 'package:flutter/material.dart';
import 'components/challenge_card.dart';
import 'dart:convert';
import 'http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _availableChallenges = [];
  final HttpService _httpService = HttpService();

  List<Map<String, dynamic>> _activeChallenges = [];

  List<Map<String, dynamic>> _completedChallenges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch data for the default tab (ACTIVE) when the screen is first loaded
    _fetchActiveChallenges();

    // Add listener to load data when a tab is selected
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // Prevent multiple calls during animation
      switch (_tabController.index) {
        case 0:
          _fetchActiveChallenges();
          break;
        case 1:
          _fetchAvailableChallenges();
          break;
        case 2:
          _fetchCompletedChallenges();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableChallenges() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Retrieve userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID not found in SharedPreferences');
      }

      // Use HttpService to make the GET request
      final response = await _httpService.get('challenges/$userId');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 200) {
          setState(() {
            _availableChallenges = List<Map<String, dynamic>>.from(data['details']);
          });

        } else {
          throw Exception(data['message'] ?? 'Failed to fetch challenges');
        }
      } else {
        throw Exception('Failed to fetch challenges. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching challenges: $e');
      // Optionally, show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  Future<void> _fetchActiveChallenges() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Retrieve userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID not found in SharedPreferences');
      }

      // Use HttpService to make the GET request
      final response = await _httpService.get('accepted_challenges/$userId');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 200) {
          setState(() {
            _activeChallenges = List<Map<String, dynamic>>.from(data['details'].map((challenge) {
              return {
                'title': challenge['title'],
                'description': challenge['description'],
                'progress': challenge['progress'], // Keep progress as an integer (0-100)
                'daysLeft': challenge['daysLeft'],
                'points': challenge['points'],
                'deadline': challenge['deadline'],
              };
            }));
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch active challenges');
        }
      } else {
        throw Exception('Failed to fetch active challenges. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching active challenges: $e');
      // Optionally, show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _fetchCompletedChallenges() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Retrieve userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID not found in SharedPreferences');
      }

      // Use HttpService to make the GET request
      final response = await _httpService.get('completed_challenges/$userId');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['code'] == 200) {
          setState(() {
            _completedChallenges = List<Map<String, dynamic>>.from(data['details'].map((challenge) {
              return {
                'title': challenge['title'],
                'description': challenge['description'],
                'completedOn': challenge['completedOn'],
                'points': challenge['points'],
              };
            }));
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch completed challenges');
        }
      } else {
        throw Exception('Failed to fetch completed challenges. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching completed challenges: $e');
      // Optionally, show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white],
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.teal,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.teal,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'ACTIVE'),
                    Tab(text: 'AVAILABLE'),
                    Tab(text: 'COMPLETED'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(),
                    _buildAvailableTab(),
                    _buildCompletedTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    return _activeChallenges.isEmpty
        ? _buildEmptyState('No active challenges', 'Start a new challenge to see it here')
        : ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _activeChallenges.length,
      itemBuilder: (context, index) {
        final challenge = _activeChallenges[index];
        return ChallengeCard.active(
          title: challenge['title'],
          description: challenge['description'],
          progress: (challenge['progress'] as num).toDouble() / 100, // Convert progress to double
          daysLeft: challenge['daysLeft'],
          points: challenge['points'],
          onTap: () {
            // TODO: Navigate to challenge details
          },
        );
      },
    );
  }

  Widget _buildAvailableTab() {
    return _availableChallenges.isEmpty
        ? _buildEmptyState('No challenges available', 'Check back later for new challenges')
        : ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _availableChallenges.length,
      itemBuilder: (context, index) {
        final challenge = _availableChallenges[index];
        return ChallengeCard.available(
          title: challenge['title'],
          description: challenge['description'],
          difficulty: challenge['difficulty'],
          points: challenge['points'],
          duration: challenge['duration'],
          onJoin: () {
            // Show confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Join Challenge'),
                  content: Text('Are you sure you want to join "${challenge['title']}" challenge?'),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      child: Text('Join'),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        try {
                          // Retrieve userId from SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getInt('userId');

                          if (userId == null) {
                            throw Exception('User ID not found in SharedPreferences');
                          }

                          // Prepare the request body
                          final requestBody = {
                            "challengeId": challenge['id'],
                            "userId": userId,
                          };

                          // Send the POST request
                          final response = await _httpService.post(
                            'accepted_challenges', // Endpoint
                            data: requestBody,
                          );

                          if (response.statusCode == 200 || response.statusCode == 201) {
                            final responseData = response.data;

                            if (responseData['code'] == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(responseData['message']),
                                  backgroundColor: Colors.teal,
                                ),
                              );

                              // Optionally, handle the `details` object
                              final details = responseData['details'];
                              print('Accepted Challenge Details: $details');

                              // Fetch the data of the available challenges tab again
                              await _fetchAvailableChallenges();
                            } else {
                              throw Exception(responseData['message'] ?? 'Unexpected response');
                            }
                          } else {
                            throw Exception('Failed to join challenge. Status code: ${response.statusCode}');
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return _completedChallenges.isEmpty
        ? _buildEmptyState('No completed challenges', 'Complete challenges to see them here')
        : ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _completedChallenges.length,
      itemBuilder: (context, index) {
        final challenge = _completedChallenges[index];
        return ChallengeCard.completed(
          title: challenge['title'],
          description: challenge['description'],
          completedOn: challenge['completedOn'],
          points: challenge['points'],
          onTap: () {
            // TODO: Navigate to challenge details
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}