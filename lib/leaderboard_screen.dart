// leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _leaderboardCategories = [
    'Global',
    'Weekly',
    'Monthly'
  ];

  // Mock leaderboard data
  // final List<Map<String, dynamic>> _globalLeaderboard = [
  //   {'rank': 1, 'username': 'fitfoodie', 'points': 9750, 'isCurrentUser': false},
  //   {'rank': 2, 'username': 'healthnut', 'points': 8920, 'isCurrentUser': false},
  //   {'rank': 3, 'username': 'nutrimaster', 'points': 8450, 'isCurrentUser': false},
  //   {'rank': 4, 'username': 'johndoe', 'points': 7840, 'isCurrentUser': true},
  //   {'rank': 5, 'username': 'veggielover', 'points': 7320, 'isCurrentUser': false},
  //   {'rank': 6, 'username': 'mealeater', 'points': 6950, 'isCurrentUser': false},
  //   {'rank': 7, 'username': 'kitchenchef', 'points': 6780, 'isCurrentUser': false},
  //   {'rank': 8, 'username': 'foodexplorer', 'points': 6540, 'isCurrentUser': false},
  //   {'rank': 9, 'username': 'healthyeats', 'points': 6210, 'isCurrentUser': false},
  //   {'rank': 10, 'username': 'balancediet', 'points': 5980, 'isCurrentUser': false},
  // ];
  //
  // final List<Map<String, dynamic>> _weeklyLeaderboard = [
  //   {'rank': 1, 'username': 'kitchenchef', 'points': 1250, 'isCurrentUser': false},
  //   {'rank': 2, 'username': 'johndoe', 'points': 920, 'isCurrentUser': true},
  //   {'rank': 3, 'username': 'healthnut', 'points': 845, 'isCurrentUser': false},
  //   {'rank': 4, 'username': 'fitfoodie', 'points': 784, 'isCurrentUser': false},
  //   {'rank': 5, 'username': 'nutrimaster', 'points': 732, 'isCurrentUser': false},
  // ];

  bool _isLoading = true;
  List<Map<String, dynamic>> _globalLeaderboard = [];
  List<Map<String, dynamic>> _weeklyLeaderboard = [];
  List<Map<String, dynamic>> _monthlyLeaderboard = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _leaderboardCategories.length, vsync: this);
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      // Fetch all leaderboards
      final globalResponse = await HttpService().get('leaderboard/season/$userId');
      final weeklyResponse = await HttpService().get('leaderboard/week/$userId');
      final monthlyResponse = await HttpService().get('leaderboard/month/$userId');

      if (globalResponse.data['code'] == 200) {
        _globalLeaderboard = List<Map<String, dynamic>>.from(globalResponse.data['details']);
      }
      if (weeklyResponse.data['code'] == 200) {
        _weeklyLeaderboard = List<Map<String, dynamic>>.from(weeklyResponse.data['details']);
      }
      if (monthlyResponse.data['code'] == 200) {
        _monthlyLeaderboard = List<Map<String, dynamic>>.from(monthlyResponse.data['details']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading leaderboard: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _getCurrentUserData(List<Map<String, dynamic>> leaderboard) {
    return leaderboard.firstWhere(
          (user) => user['isCurrentUser'] == true,
      orElse: () => {},
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _fetchLeaderboardData,
        child: isLandscape
            ? SingleChildScrollView(
          child: Column(
            children: [
              _buildLeaderboardHeader(),
              _buildTabBar(),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: _buildTabBarView(),
              ),
            ],
          ),
        )
            : Column(
          children: [
            _buildLeaderboardHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabBarView()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    final currentUserData = _getCurrentUserData(_tabController.index == 0
        ? _globalLeaderboard
        : _tabController.index == 1
        ? _weeklyLeaderboard
        : _monthlyLeaderboard);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade400, Colors.teal.shade700],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Leaderboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compete with others and earn rewards!',
            style: TextStyle(
              color: const Color.fromRGBO(255, 255, 255, 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (currentUserData?.isNotEmpty == true)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUserRankCard(
                  currentUserData!['rank'],
                  currentUserData['username'],
                  currentUserData['points'],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildLeaderboardTab(_globalLeaderboard),
        _buildLeaderboardTab(_weeklyLeaderboard),
        _buildLeaderboardTab(_monthlyLeaderboard),
      ],
    );
  }

  Widget _buildUserRankCard(int rank, String username, int points) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Column(
          children: [
            Text(
              'Your Rank',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade800,
                  radius: 20,
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$username',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$points pts',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        tabs: _leaderboardCategories
            .map((category) => Tab(text: category))
            .toList(),
      ),
    );
  }

  Widget _buildLeaderboardTab(List<Map<String, dynamic>> leaderboardData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                const SizedBox(width: 50, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                const Expanded(child: Text('User', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                const SizedBox(width: 16),
                const Text('Points', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: leaderboardData.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final user = leaderboardData[index];
                return _buildLeaderboardItem(
                  user['rank'],
                  user['username'],
                  user['points'],
                  user['isCurrentUser'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String username, int points, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? Color.fromRGBO(0, 150, 136, 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.teal : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.teal : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: rank <= 3
                ? [Colors.amber, Colors.grey.shade300, Colors.brown.shade300][rank - 1]
                : Colors.teal.shade100,
            child: rank <= 3
                ? Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 16,
            )
                : Text(
              username.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$username',
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isCurrentUser)
                  const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.teal : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$points pts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}