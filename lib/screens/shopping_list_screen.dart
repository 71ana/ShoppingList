import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/firestore_service.dart';

class ShoppingListScreen extends StatefulWidget {
  final String listName;
  final String listId;

  ShoppingListScreen({required this.listName, required this.listId});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<ShoppingItem>> _itemsStream;
  final TextEditingController _textController = TextEditingController(); // Added here
  final Map<String, TextEditingController> _controllersMap = {}; // Track controllers per item
  final Map<String, bool> _isEditingMap = {}; // Track edit state per item

  @override
  void initState() {
    super.initState();

    // Fetch items for this specific list from Firestore
    _itemsStream = _firestoreService.getItemsForList(widget.listId);
  }

  @override
  void dispose() {
    // Dispose the main text controller
    _textController.dispose();

    // Dispose all item-specific controllers
    for (var controller in _controllersMap.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item name cannot be empty!')),
      );
      return;
    }

    _firestoreService.addItemToList(
      widget.listId,
      ShoppingItem(
        id: '', // Firestore will generate the ID
        name: name.trim(),
        isPurchased: false,
      )
    );
  }

  void _togglePurchase(String itemId, bool isPurchased) {
    _firestoreService.toggleItemPurchase(itemId, !isPurchased);
    setState(() {});
  }

  void _deleteItem(String itemId) {
    _firestoreService.deleteItem(itemId);
  }

  void _editItem(String itemId, String newName) {
    _firestoreService.editItem(itemId, newName);
  }

// Toggle edit mode for a specific item
  void _toggleEditMode(String itemId) {
    setState(() {
      if (_isEditingMap[itemId] == true) {
        // Exit edit mode for this item
        _isEditingMap[itemId] = false;
        _controllersMap[itemId]?.dispose(); // Dispose controller to free memory
      } else {
        // Enter edit mode for this item
        _isEditingMap[itemId] = true;
        // Find the item name directly from the items list
        _controllersMap[itemId] = TextEditingController();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.listName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController, // Correctly referenced
                    decoration: InputDecoration(
                      hintText: 'Add a new item...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onSubmitted: (value) {
                      _addItem(value);
                      _textController.clear(); // Clear after submission
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _addItem(_textController.text);
                    _textController.clear();
                  },
                  child: Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ShoppingItem>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Your list is empty.'));
                }

                final items = snapshot.data!;

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: GestureDetector(
                        onTap: () {
                          _toggleEditMode(item.id); // Toggle edit mode for this item
                        },
                        child: _isEditingMap[item.id] == true
                            ? TextField(
                          controller: _controllersMap[item.id], // Use per-item controller
                          autofocus: true,
                          onSubmitted: (newName) {
                            _editItem(item.id, newName);
                            setState(() {
                              _isEditingMap[item.id] = false;
                            });
                          },
                          decoration: InputDecoration(border: OutlineInputBorder()),
                        )
                            : Text(item.name), // Display name if not editing
                      ),
                      trailing: Wrap(
                        spacing: 12,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.check_circle,
                              color: item.isPurchased ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              _togglePurchase(item.id, item.isPurchased);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _deleteItem(item.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
