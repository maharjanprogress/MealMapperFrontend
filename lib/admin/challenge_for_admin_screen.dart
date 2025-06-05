// c:\Users\progr\AndroidStudioProjects\meal_mapper\lib\admin\challenge_for_admin_screen.dart
import 'package:flutter/material.dart';
// Import the new tab files
import 'tabs/ongoing_challenges_tab.dart';
import 'tabs/add_challenges_tab.dart';

class ChallengeForAdminScreen extends StatefulWidget {
  const ChallengeForAdminScreen({Key? key}) : super(key: key);

  @override
  _ChallengeForAdminScreenState createState() =>
      _ChallengeForAdminScreenState();
}

class _ChallengeForAdminScreenState extends State<ChallengeForAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add listener if you need to react to tab changes
    // _tabController.addListener(() {
    //   if (_tabController.indexIsChanging) {
    //     // Tab is changing
    //   } else {
    //     // Tab has changed
    //     print("Selected Tab: ${_tabController.index}");
    //   }
    // });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.teal.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.teal.shade700,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'Ongoing Challenges'),
            Tab(text: 'Add Challenges'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              OngoingChallengesTab(), // Use the new tab widget
              AddChallengesTab(), // Use the new tab widget
            ],
          ),
        ),
      ],
    );
  }
}
