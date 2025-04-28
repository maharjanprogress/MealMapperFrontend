// leaderboard_screen.dart
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _leaderboardCategories = [
    'Global',
    'Friends',
    'Weekly',
    'Monthly'
  ];

  // Mock leaderboard data
  final List<Map<String, dynamic>> _globalLeaderboard = [
    {'rank': 1, 'username': 'fitfoodie', 'points': 9750, 'isCurrentUser': false},
    {'rank': 2, 'username': 'healthnut', 'points': 8920, 'isCurrentUser': false},
    {'rank': 3, 'username': 'nutrimaster', 'points': 8450, 'isCurrentUser': false},
    {'rank': 4, 'username': 'johndoe', 'points': 7840, 'isCurrentUser': true},
    {'rank': 5, 'username': 'veggielover', 'points': 7320, 'isCurrentUser': false},
    {'rank': 6, 'username': 'mealeater', 'points': 6950, 'isCurrentUser': false},
    {'rank': 7, 'username': 'kitchenchef', 'points': 6780, 'isCurrentUser': false},
    {'rank': 8, 'username': 'foodexplorer', 'points': 6540, 'isCurrentUser': false},
    {'rank': 9, 'username': 'healthyeats', 'points': 6210, 'isCurrentUser': false},
    {'rank': 10, 'username': 'balancediet', 'points': 5980, 'isCurrentUser': false},
  ];

  final List<Map<String, dynamic>> _weeklyLeaderboard = [
    {'rank': 1, 'username': 'kitchenchef', 'points': 1250, 'isCurrentUser': false},
    {'rank': 2, 'username': 'johndoe', 'points': 920, 'isCurrentUser': true},
    {'rank': 3, 'username': 'healthnut', 'points': 845, 'isCurrentUser': false},
    {'rank': 4, 'username': 'fitfoodie', 'points': 784, 'isCurrentUser': false},
    {'rank': 5, 'username': 'nutrimaster', 'points': 732, 'isCurrentUser': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _leaderboardCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      child: Column(
        children: [
          _buildLeaderboardHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardTab(_globalLeaderboard),
                _buildLeaderboardTab(_weeklyLeaderboard), // Using weekly data for friends tab as placeholder
                _buildLeaderboardTab(_weeklyLeaderboard),
                _buildLeaderboardTab(_globalLeaderboard), // Using global data for monthly tab as placeholder
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
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
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUserRankCard(4, 'johndoe', 7840),
            ],
          ),
        ],
      ),
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
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 24, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                const Expanded(child: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                const Text('Points', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
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
        color: isCurrentUser ? Colors.teal.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? Colors.teal : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
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