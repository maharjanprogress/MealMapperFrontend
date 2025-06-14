// c:\Users\progr\AndroidStudioProjects\meal_mapper\lib\medical_condition_screen.dart
import 'package:flutter/material.dart';

import 'tabs/view_medical_conditions_tab.dart';
import 'tabs/add_medical_condition_tab.dart';
import 'tabs/update_medical_condition_tab.dart';

enum MedicalConditionView { viewAll, add, update }

class MedicalConditionScreen extends StatefulWidget {
  const MedicalConditionScreen({Key? key}) : super(key: key);

  @override
  _MedicalConditionScreenState createState() => _MedicalConditionScreenState();
}

class _MedicalConditionScreenState extends State<MedicalConditionScreen> {
  MedicalConditionView _currentView = MedicalConditionView.viewAll;
  Map<String, dynamic>? _selectedMedicalConditionForUpdate;

  void _setView(MedicalConditionView view, {Map<String, dynamic>? condition}) {
    setState(() {
      _currentView = view;
      _selectedMedicalConditionForUpdate = condition;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;
    String title;
    FloatingActionButton? fab;

    switch (_currentView) {
      case MedicalConditionView.viewAll:
        title = 'Medical Conditions';
        currentWidget = ViewMedicalConditionsTab(
          onUpdatePressed: (condition) => _setView(MedicalConditionView.update, condition: condition),
        );
        fab = FloatingActionButton.extended(
          onPressed: () => _setView(MedicalConditionView.add),
          icon: const Icon(Icons.add),
          label: const Text('Add Condition'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        );
        break;
      case MedicalConditionView.add:
        title = 'Add Medical Condition';
        currentWidget = AddMedicalConditionTab(
          onMedicalConditionSaved: () => _setView(MedicalConditionView.viewAll),
          onCancel: () => _setView(MedicalConditionView.viewAll),
        );
        break;
      case MedicalConditionView.update:
        title = 'Update Medical Condition';
        // Ensure condition data is available for update view
        if (_selectedMedicalConditionForUpdate == null) {
          // Fallback or error state if somehow update is triggered without data
          currentWidget = const Center(child: Text('Error: No condition selected for update.'));
        } else {
          currentWidget = UpdateMedicalConditionTab(
            initialMedicalCondition: _selectedMedicalConditionForUpdate!,
            onMedicalConditionUpdated: () => _setView(MedicalConditionView.viewAll),
            onCancel: () => _setView(MedicalConditionView.viewAll),
          );
        }
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // Optionally add a back button if not on the main viewAll tab
        leading: _currentView != MedicalConditionView.viewAll
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _setView(MedicalConditionView.viewAll),
        )
            : null,
      ),
      body: currentWidget,
      floatingActionButton: fab, // FAB is only shown on the ViewAll tab
    );
  }
}
