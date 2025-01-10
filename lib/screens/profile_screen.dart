import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedAvatar;

  final List<String> _avatars = [
    'assets/icons/avatar1.png',
    'assets/icons/avatar2.png',
    'assets/icons/avatar3.png',
    'assets/icons/avatar4.png',
    'assets/icons/avatar5.png',
    'assets/icons/avatar6.png',
    'assets/icons/avatar7.png',
    'assets/icons/avatar8.png',
    'assets/icons/avatar9.png',
  ];
  int totalLists = 0;
  int totalItems = 0;
  String mostFrequentItem = "N/A";

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _fetchUserStats();
  }

  void _loadAvatar() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _selectedAvatar = doc['profilePicture'] ?? _avatars.first;
      });
    }
  }

  void _selectAvatar(String avatarPath) async {
    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'profilePicture': avatarPath}, SetOptions(merge: true));

      setState(() {
        _selectedAvatar = avatarPath;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Avatar updated successfully!'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Widget _buildStatItem(IconData icon, String label, dynamic value) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _openAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              'Choose an Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          content: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _avatars.map((avatar) {
              return GestureDetector(
                onTap: () {
                  _selectAvatar(avatar);
                  Navigator.pop(context); // Close the dialog
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: avatar == _selectedAvatar
                      ? Colors.teal
                      : Colors.grey[300],
                  backgroundImage: AssetImage(avatar),
                  child: avatar == _selectedAvatar
                      ? Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _fetchUserStats() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userId = user.uid;
      final firestoreService = FirestoreService();

      final listsCount = await firestoreService.getTotalLists(userId);
      setState(() {
        totalLists = listsCount;
      });

      int itemsCount = await firestoreService.getTotalItems(userId);

      setState(() {
        totalItems = itemsCount;
      });

      final List<String> items = await firestoreService.getItemsForUser(userId);

      setState(() {
        mostFrequentItem = items[0];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final userEmail = user?.email ?? 'Not logged in';
    final userName = userEmail.contains('@') ? userEmail.split('@')[0] : 'Guest';


    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD8BFD8), Color(0xFFA3D8F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _openAvatarSelectionDialog,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Main Avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.teal,
                      backgroundImage: _selectedAvatar != null
                          ? AssetImage(_selectedAvatar!)
                          : null,
                      child: _selectedAvatar == null
                          ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    // Camera Icon
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$userName! 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (user == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Please log in.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Stats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(Icons.list_alt, 'Lists', totalLists),
                          _buildStatItem(Icons.shopping_cart, 'Items', totalItems),
                          _buildStatItem(Icons.star, 'Favorite', mostFrequentItem),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Log Out Button
              ElevatedButton.icon(
                onPressed: () async {
                  await _auth.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
