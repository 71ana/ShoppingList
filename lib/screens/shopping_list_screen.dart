import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/screens/scanner_screen.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item name cannot be empty!')),
      );
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
    print('Added item to Firestore: $name'); // Debug
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

  void _fetchProductFromApi(String barcode) async {
    final url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';

    try {
      print('Fetching product for barcode: $barcode'); // Debug: barcode
      final response = await http.get(Uri.parse(url));
      print('API Response Status: ${response.statusCode}'); // Debug: status

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response Data: $data'); // Debug: response data

        if (data != null && data['product'] != null) {
          final product = data['product'];
          final productName = product['product_name'] ?? 'Unknown Product';

          final exists = await _firestoreService.isProductInList(widget.listId, productName);
          if (!exists) {
            _addItem(productName); // Add the product to the list
            print('Product detected and added: $productName'); // Debug: product added
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Product "$productName" is already in the shopping list.')),
            );
            print('Product "$productName" is already in the shopping list.');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No product found for this barcode.')),
          );
          print('No product found for this barcode.');
        }
      } else {
        print('API Error: ${response.statusCode}');
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
            print('Scanned code: $code');
            _fetchProductFromApi(code); // Fetch product details
          },
        ),
      ),
    );
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
                    controller: _textController,
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
                      _textController.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _openScanner,
                ),
                ElevatedButton(
                  onPressed: () {
                    _addItem(_textController.text);
                    _textController.clear();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ShoppingItem>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Your list is empty.'));
                }

                final items = snapshot.data!;
                print('Fetched items from Firestore: ${items.map((e) => e.name).toList()}'); // Debug

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
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
                            setState(() {
                              _isEditingMap[item.id] = false;
                            });
                          },
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        )
                            : Text(item.name),
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
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
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





// double _budget = 0.0;
// void _showBudgetDialog() {
//   final budgetController = TextEditingController();
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Text('Set Budget'),
//       content: TextField(
//         controller: budgetController,
//         decoration: InputDecoration(labelText: 'Enter your budget'),
//         keyboardType: TextInputType.number,
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: Text('Cancel'),
//         ),
//         TextButton(
//           onPressed: () {
//             setState(() {
//               _budget = double.tryParse(budgetController.text) ?? 0.0;
//             });
//             Navigator.of(context).pop();
//           },
//           child: Text('Save'),
//         ),
//       ],
//     ),
//   );
// }