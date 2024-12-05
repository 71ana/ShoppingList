import 'package:flutter/material.dart';
import 'shopping_list_screen.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, String>> shoppingLists = []; // Stores list name and ID

  @override
  void initState() {
    super.initState();

    // Listen for shopping lists from Firestore
    _firestoreService.getShoppingLists().listen((lists) {
      setState(() {
        shoppingLists = lists;
      });
    });
  }

  // Function to create a new shopping list
  void _createList(String listName) {
    _firestoreService.createShoppingList(listName);
  }

  void _showAddListDialog() {
    final TextEditingController _dialogController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New List'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: _dialogController,
              decoration: InputDecoration(
                hintText: 'Enter list name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: Text('Create', style: TextStyle(color: Colors.green)),
              onPressed: () {
                if (_dialogController.text.isNotEmpty) {
                  _createList(_dialogController.text);
                }
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Lists',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.indigo[200], // Custom color scheme
        elevation: 4.0, // Shadow for depth
      ),
      body: shoppingLists.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 50,
              color: Colors.indigo,
            ),
            SizedBox(height: 16),
            Text(
              'No shopping lists yet. Tap the "+" button to create one.',
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

          return Dismissible(
            key: Key(listId), // Use unique ID as key
            direction: DismissDirection.endToStart,
            onDismissed: (direction) async {
              // Remove the list from the UI immediately
              setState(() {
                shoppingLists.removeAt(index);
              });

              try {
                // Wait for the Firestore deletion to complete
                await _firestoreService.deleteShoppingList(listId);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$listName deleted')),
                );
              } catch (e) {
                // Handle errors
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete $listName')),
                );

                // Restore the list in case of failure
                setState(() {
                  shoppingLists.insert(index, {'id': listId, 'name': listName});
                });
              }
            },

            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2.0,
              margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                title: Text(
                  listName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.black54),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoppingListScreen(listName: listName, listId: listId,),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddListDialog,
        backgroundColor: Colors.indigo[200],
        child: Icon(Icons.add, size: 30),
        tooltip: 'Create a New List',
      ),
    );
  }
}
