// home_screen.dart
import 'dart:io';
import 'dart:convert';
import 'http_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'components/food_card.dart';
import 'components/streak_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _isLoading = false;
  bool _hasAnalyzed = false;
  String _recognizedFood = '';
  List<Map<String, dynamic>> _recommendations = [];
  final int _currentStreak = 7;
  final int _longestStreak = 14;
  final HttpService _httpService = HttpService();

  // Mock data for recommendations
  final List<Map<String, dynamic>> _mockRecommendations = [
    {
      'name': 'Grilled Salmon with Asparagus',
      'calories': 320,
      'protein': 38,
      'carbs': 12,
      'fat': 14,
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Hamburger_%2812164386105%29.jpg/1200px-Hamburger_%2812164386105%29.jpg',
    },
    {
      'name': 'Quinoa Salad with Avocado',
      'calories': 280,
      'protein': 10,
      'carbs': 38,
      'fat': 16,
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Hamburger_%2812164386105%29.jpg/1200px-Hamburger_%2812164386105%29.jpg',
    },
    {
      'name': 'Greek Yogurt with Berries',
      'calories': 220,
      'protein': 20,
      'carbs': 24,
      'fat': 8,
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Hamburger_%2812164386105%29.jpg/1200px-Hamburger_%2812164386105%29.jpg',
    },
    {
      'name': 'Vegetable Stir-Fry with Tofu',
      'calories': 305,
      'protein': 18,
      'carbs': 28,
      'fat': 16,
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Hamburger_%2812164386105%29.jpg/1200px-Hamburger_%2812164386105%29.jpg',
    },
  ];

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
        _hasAnalyzed = false;
      });

      // Simulate API call for food recognition
      await _uploadImage();

      // Mock recognition result
      setState(() {
        _isLoading = false;
        _hasAnalyzed = true;
        _recommendations = _mockRecommendations;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image selected")),
      );
      return;
    }

    try {
      final response = await _httpService.uploadFile(
        'get_image', // Endpoint
        _image!.path, // File path
        fieldName: 'image', // Field name expected by the backend
      );
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (response.statusCode == 200) {
        _recognizedFood = data["details"];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.data}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreakCard(
              currentStreak: _currentStreak,
              longestStreak: _longestStreak,
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Recognize Your Food',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _image == null
                        ? Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Take a photo of your food',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                        : Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _image!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (_isLoading)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Analyzing your food...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.camera_alt),
                            label: Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _getImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.photo_library),
                            label: Text('Gallery'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: Colors.teal,
                              side: BorderSide(color: Colors.teal),
                            ),
                            onPressed: () => _getImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    if (_hasAnalyzed) ...[
                      const SizedBox(height: 16),
                      Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Recognized as:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _recognizedFood,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text('Not correct? Edit'),
                        onPressed: () {
                          // TODO: Implement edit functionality
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_hasAnalyzed && _recommendations.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final food = _recommendations[index];
                  return FoodCard(
                    name: food['name'],
                    calories: food['calories'],
                    protein: food['protein'],
                    carbs: food['carbs'],
                    fat: food['fat'],
                    imagePath: food['image'],
                  );
                },
              ),
            ] else if (_hasAnalyzed) ...[
              const SizedBox(height: 24),
              Text(
                'No recommendations available.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}