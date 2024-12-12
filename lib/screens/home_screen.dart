import 'package:Listify/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:animations/animations.dart';
import 'package:lottie/lottie.dart';
import '../models/shopping_item.dart';
import 'map_screen.dart';
import 'shopping_list_screen.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeContent(),
    MapScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(index),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10.0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'My Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, String>> shoppingLists = [];

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;

      // Fetch shopping lists from Firestore
      _firestoreService.getShoppingLists(uid).listen((lists) {
        setState(() {
          shoppingLists = lists;
        });
      });
    }
  }

  void _createList(String listName) {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      _firestoreService.createShoppingList(uid, listName);

      // Show success Snackbar
      _showSuccessSnackbar("List Created", "$listName has been successfully created!");
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    final snackBar = SnackBar(
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: ContentType.success,
      ),
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showAddListDialog() {
    final TextEditingController _dialogController = TextEditingController();

    showModal(
      context: context,
      configuration: FadeScaleTransitionConfiguration(),
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade500, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create New List',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dialogController,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Enter list name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_dialogController.text.isNotEmpty) {
                              _createList(_dialogController.text);
                            }
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -84,
                left: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 40,
                  child: Icon(
                    Icons.list_alt_rounded,
                    color: Colors.teal.shade400,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Shopping Lists',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 5.0,
      ),
      body: shoppingLists.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/loading_cart.json',
              width: 300,
              height: 300,
              repeat: true,
            ),
            Text(
              'No shopping lists yet.\nTap "+" to create one!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: shoppingLists.length,
        itemBuilder: (context, index) {
          final list = shoppingLists[index];
          final listId = list['id']!;
          final listName = list['name']!;

          return StreamBuilder<List<ShoppingItem>>(
            stream: _firestoreService.getItemsForList(listId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(
                      listName,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Loading items...'),
                  ),
                );
              }

              final items = snapshot.data!;
              final int totalItems =
              _firestoreService.getTotalItemsForList(items);
              final int completedItems =
              _firestoreService.getCompletedItemsForList(items);
              final double progress =
              totalItems > 0 ? (completedItems / totalItems) : 0.0;

              return Dismissible(
                key: Key(listId),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  setState(() => shoppingLists.removeAt(index));
                  await _firestoreService.deleteShoppingList(listId);
                },
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.redAccent, Colors.red],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.delete, color: Colors.white),
                    ],
                  ),
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.list_alt,
                          color: Colors.white, size: 28),
                    ),
                    title: Text(
                      listName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          "$completedItems of $totalItems items completed",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          color: progress < 0.5
                              ? Colors.redAccent
                              : (progress < 1.0
                              ? Colors.amber
                              : Colors.green),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: Colors.grey, size: 24),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShoppingListScreen(
                            listId: listId,
                            listName: listName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: OpenContainer(
        closedElevation: 10,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        closedColor: Colors.indigoAccent,
        closedBuilder: (context, action) {
          return FloatingActionButton(
            onPressed: _showAddListDialog,
            backgroundColor: Colors.indigo,
            child: Icon(Icons.add, size: 40, color: Colors.white),
          );
        },
        openBuilder: (context, action) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Add New List'),
            ),
            body: Center(child: Text('Add list screen')),
          );
        },
      ),
    );
  }
}
