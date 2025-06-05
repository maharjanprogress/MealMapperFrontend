// c:\Users\progr\AndroidStudioProjects\meal_mapper\lib\admin_page.dart
import 'package:flutter/material.dart';
import 'challenge_for_admin_screen.dart';
import 'allergen_screen.dart';
import 'ingredient_screen.dart';
import 'medical_condition_screen.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Widget _selectedScreen = const ChallengeForAdminScreen(); // Default screen
  String _currentPageTitle = 'Challenge Management';

  void _selectScreen(Widget screen, String title) {
    setState(() {
      _selectedScreen = screen;
      _currentPageTitle = title;
    });
    Navigator.of(context).pop(); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPageTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF00695C), // Darker Teal for AppBar
        elevation: 4.0,
        iconTheme: const IconThemeData(color: Colors.white), // Ensure hamburger icon is white
      ),
      drawer: _buildDrawer(),
      body: _selectedScreen,
      backgroundColor: Colors.grey[100], // Light background for the body content
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF1D2331), // A deep, cool dark blue/grey
        child: Column(
          children: <Widget>[
            _createDrawerHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _createDrawerItem(
                    icon: Icons.shield_outlined,
                    text: 'Challenges',
                    onTap: () => _selectScreen(const ChallengeForAdminScreen(), 'Challenge Management'),
                    isSelected: _currentPageTitle == 'Challenge Management',
                  ),
                  _createDrawerItem(
                    icon: Icons.warning_amber_rounded,
                    text: 'Allergens',
                    onTap: () => _selectScreen(const AllergenScreen(), 'Allergen Management'),
                    isSelected: _currentPageTitle == 'Allergen Management',
                  ),
                  _createDrawerItem(
                    icon: Icons.kitchen_outlined,
                    text: 'Ingredients',
                    onTap: () => _selectScreen(const IngredientScreen(), 'Ingredient Management'),
                    isSelected: _currentPageTitle == 'Ingredient Management',
                  ),
                  _createDrawerItem(
                    icon: Icons.medical_services_outlined,
                    text: 'Medical Conditions',
                    onTap: () => _selectScreen(const MedicalConditionScreen(), 'Medical Condition Management'),
                    isSelected: _currentPageTitle == 'Medical Condition Management',
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2D3748), height: 1),
            _createDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
              },
            ),
            const SizedBox(height: 10), // Some padding at the bottom
          ],
        ),
      ),
    );
  }

  Widget _createDrawerHeader() {
    return Container(
      height: 200.0,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20), // Adjust top padding for status bar
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF004D40)], // Deeper Teals
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withOpacity(0.95),
            child: Icon(Icons.admin_panel_settings_rounded, size: 35, color: Color(0xFF004D40)),
          ),
          const SizedBox(height: 12),
          const Text(
            "Admin Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Meal Mapper Control Panel",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _createDrawerItem({required IconData icon, required String text, required GestureTapCallback onTap, bool isSelected = false}) {
    final Color selectedColor = Colors.tealAccent[100]!;
    final Color defaultColor = Colors.white.withOpacity(0.8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.teal.withOpacity(0.3),
        highlightColor: Colors.teal.withOpacity(0.15),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.withOpacity(0.20) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? selectedColor : Colors.transparent,
                width: 3.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 22, color: isSelected ? selectedColor : defaultColor),
              const SizedBox(width: 24),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? selectedColor : defaultColor,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
