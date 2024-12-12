import 'dart:convert';
import 'package:Listify/screens/scanner_screen.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/shopping_item.dart';
import '../services/firestore_service.dart';
import 'package:http/http.dart' as http;

class ShoppingListScreen extends StatefulWidget {
  final String listName;
  final String listId;

  const ShoppingListScreen({required this.listName, required this.listId});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<ShoppingItem>> _itemsStream;
  final TextEditingController _textController = TextEditingController();
  final Map<String, TextEditingController> _controllersMap = {};
  final Map<String, bool> _isEditingMap = {};

  @override
  void initState() {
    super.initState();
    _itemsStream = _firestoreService.getItemsForList(widget.listId);
  }

  @override
  void dispose() {
    _textController.dispose();
    for (var controller in _controllersMap.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) {
      final snackBar = SnackBar(
        content: AwesomeSnackbarContent(
          title: 'Error',
          message: 'Item name cannot be empty!',
          contentType: ContentType.failure,
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    _firestoreService.addItemToList(
      widget.listId,
      ShoppingItem(
        id: '',
        name: name.trim(),
        isPurchased: false,
      ),
    );

    final snackBar = SnackBar(
      content: AwesomeSnackbarContent(
        title: 'Success',
        message: '"$name" added successfully!',
        contentType: ContentType.success,
      ),
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _textController.clear();
  }

  void _togglePurchase(String itemId, bool isPurchased) {
    _firestoreService.toggleItemPurchase(itemId, !isPurchased);
  }

  void _deleteItem(String itemId) {
    _firestoreService.deleteItem(itemId);
  }

  void _editItem(String itemId, String newName) {
    _firestoreService.editItem(itemId, newName);
  }

  void _fetchProductFromApi(String barcode) async {
    final url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['product'] != null) {
          final product = data['product'];
          final productName = product['product_name'] ?? 'Unknown Product';

          final exists = await _firestoreService.isProductInList(widget.listId, productName);
          if (!exists) {
            _addItem(productName);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Product "$productName" is already in the shopping list.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No product found for this barcode.')),
          );
        }
      }
    } catch (e) {
      print('Error fetching product: $e');
    }
  }

  void _toggleEditMode(String itemId) {
    setState(() {
      if (_isEditingMap[itemId] == true) {
        _isEditingMap[itemId] = false;
        _controllersMap[itemId]?.dispose();
      } else {
        _isEditingMap[itemId] = true;
        _controllersMap[itemId] = TextEditingController();
      }
    });
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          onScan: (code) {
            _fetchProductFromApi(code);
          },
        ),
      ),
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
        title: Text(widget.listName,
        style: TextStyle(color: Colors.white),),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Input Field with Shadow and Rounded Design
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3), // Shadow color
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3), // Shadow offset
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Add a new item...',
                        prefixIcon: Icon(Icons.edit, color: Colors.indigo), // Add an icon
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onSubmitted: (value) {
                        _addItem(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Add spacing between elements
                // QR Code Scanner Button with Shadow
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: Colors.indigo, size: 28),
                    tooltip: 'Scan Barcode',
                    onPressed: _openScanner,
                  ),
                ),
                const SizedBox(width: 8), // Add spacing
                // Add Button with Shadow and Rounded Design
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      _addItem(_textController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ShoppingItem>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      width: 150,
                      height: 150,
                      repeat: true,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/add_item.json',
                          width: 200,
                          height: 200,
                          repeat: true,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your list is empty.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data!;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: GestureDetector(
                            onTap: () {
                              _togglePurchase(item.id, item.isPurchased);
                            },
                            child: CircleAvatar(
                              backgroundColor: item.isPurchased ? Colors.green : Colors.grey[300],
                              child: Icon(
                                item.isPurchased ? Icons.check : null,
                                color: item.isPurchased ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                          title: GestureDetector(
                            onTap: () {
                              _toggleEditMode(item.id);
                            },
                            child: _isEditingMap[item.id] == true
                                ? TextField(
                              controller: _controllersMap[item.id],
                              autofocus: true,
                              onSubmitted: (newName) {
                                _editItem(item.id, newName);
                                _toggleEditMode(item.id);
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter item name',
                              ),
                            )
                                : Text(
                              item.name,
                              style: TextStyle(
                                decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteItem(item.id);
                            },
                          ),
                        ),
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
