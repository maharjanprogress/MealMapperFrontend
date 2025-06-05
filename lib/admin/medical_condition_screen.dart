// c:\Users\progr\AndroidStudioProjects\meal_mapper\lib\medical_condition_screen.dart
import 'package:flutter/material.dart';

class MedicalConditionScreen extends StatelessWidget {
  const MedicalConditionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 100, color: Colors.blue.shade300),
          const SizedBox(height: 20),
          Text(
            'Medical Condition Management',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, color: Colors.grey[700], fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 10),
          Text(
            'Manage medical conditions and related dietary guidelines.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
