import 'dart:convert';
import 'package:Listify/screens/scanner_screen.dart';
import 'package:animations/animations.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/shopping_item.dart';
import '../services/firestore_service.dart';
import 'package:http/http.dart' as http;

import '../widgets/shopping_item_tile.dart';

class ShoppingListScreen extends StatefulWidget {
  final String listName;
  final String listId;
  final String userId;

  const ShoppingListScreen({required this.listName, required this.listId, required this.userId});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<ShoppingItem>> _itemsStream;
  final TextEditingController _textController = TextEditingController();
  final Map<String, TextEditingController> _controllersMap = {};
  String _selectedSortOption = "Date";
  final List<ShoppingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _itemsStream = _firestoreService.getItemsForList(widget.listId);
  }

  List<ShoppingItem> _sortItems(List<ShoppingItem> items, String option) {
    switch (option) {
      case 'Name (A-Z)':
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name (Z-A)':
        items.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Quantity':
        items.sort((a, b) => int.tryParse(a.quantity)?.compareTo(int.tryParse(b.quantity) ?? 0) ?? 0);
        break;
      case 'Date':
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Purchased First':
        items.sort((a, b) => (b.isPurchased ? 1 : 0).compareTo(a.isPurchased ? 1 : 0));
        break;
      case 'Purchased Last':
        items.sort((a, b) => (a.isPurchased ? 1 : 0).compareTo(b.isPurchased ? 1 : 0));
        break;
    }
    return items;
  }



  @override
  void dispose() {
    _textController.dispose();
    for (var controller in _controllersMap.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addItem(String name, String quantity) async {
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

    final exists = await _firestoreService.isProductInList(widget.listId, name);
    if (!exists) {
      _firestoreService.addItemToList(
        widget.listId,
        ShoppingItem(
          id: '',
          name: name.trim(),
          quantity: quantity,
          isPurchased: false,
          createdAt: DateTime.now(),
        ),
      );
      _textController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product "$name" is already in the shopping list.')),
      );
    }
  }

  void _togglePurchase(String itemId, bool isPurchased) {
    _firestoreService.toggleItemPurchase(itemId, !isPurchased);
  }

  void _deleteItem(String itemId) {
    _firestoreService.deleteItem(itemId);
  }

  void _editItem(String itemId, String newName, String newQuantity) {
    _firestoreService.editItem(itemId, newName, newQuantity);
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

          _addItem(productName, "0");
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

  void _addItemDialog() {
    final TextEditingController _itemNameController = TextEditingController();
    final TextEditingController _quantityController = TextEditingController();

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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Add New Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Name Input Field
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _itemNameController,
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Item Name',
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
                        ),
                        const SizedBox(width: 16), // Spacer between inputs

                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Qty',
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ElevatedButton.icon(
                        //   onPressed: () => Navigator.of(context).pop(),
                        //   icon: const Icon(Icons.close),
                        //   label: const Text('Cancel'),
                        //   style: ElevatedButton.styleFrom(
                        //     foregroundColor: Colors.white,
                        //     backgroundColor: Colors.lightBlue,
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(12),
                        //     ),
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 16.0,
                        //       vertical: 12.0,
                        //     ),
                        //   ),
                        // ),
                        ElevatedButton.icon(
                          onPressed: () {
                            final name = _itemNameController.text.trim();
                            final quantityText = _quantityController.text.trim();

                            if (name.isNotEmpty) {
                              _addItem(name, quantityText);
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Item name cannot be empty!'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Add'),
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
              // Icon at the Top of Dialog
              Positioned(
                top: -84,
                left: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 40,
                  child: Icon(
                    Icons.add_shopping_cart,
                    color: Colors.indigo.shade500,
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


  void _showEditItemDialog(ShoppingItem item) {
    final TextEditingController _nameController =
    TextEditingController(text: item.name);
    final TextEditingController _quantityController =
    TextEditingController(text: item.quantity.toString());

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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Item Name',
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
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Qty',
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            final updatedName = _nameController.text.trim();
                            final updatedQuantityText =
                            _quantityController.text.trim();
                            final updatedQuantity =
                                double.tryParse(updatedQuantityText) ?? 0.0;

                            if (updatedName.isNotEmpty) {
                              _editItem(item.id, updatedName, updatedQuantity.toString());
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Item name cannot be empty!'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Save'),
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
              // Icon at the Top of Dialog
              Positioned(
                top: -84,
                left: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 40,
                  child: Icon(
                    Icons.edit,
                    color: Colors.indigo.shade500,
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

  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<String>>(
          future: _getSuggestions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No suggestions available.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }
            final suggestions = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...suggestions.map((item) {
                    return ListTile(
                      title: Text(item),
                      trailing: IconButton(
                        icon: Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          _addItem(item, "");
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Future<List<String>> _getSuggestions() async {
    final items = await _userShoppingHistory();

    return items.take(5).toList();
  }


  Future<List<String>> _userShoppingHistory() async {
    return await _firestoreService.getItemsForUser(widget.userId);
  }

  void _showSortingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Sort Items',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 16),

                ListView(
                  shrinkWrap: true,
                  children: [
                    _buildSortingOption('Date', Icons.date_range),
                    _buildSortingOption('Name (A-Z)', Icons.sort_by_alpha),
                    _buildSortingOption('Name (Z-A)', Icons.sort),
                    _buildSortingOption('Quantity', Icons.format_list_numbered),
                    _buildSortingOption('Purchased First', Icons.check_circle),
                    _buildSortingOption('Purchased Last', Icons.circle_outlined),
                  ],
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.indigo,
                    ),
                    child: Text('Close',
                    style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortingOption(String option, IconData icon) {
    final bool isSelected = _selectedSortOption == option;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSortOption = option;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.indigo : Colors.grey,
              ),
              const SizedBox(width: 16),
              Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.indigo : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
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
              colors: [Color(0xFFD8BFD8), Color(0xFFA3D8F4),],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort, size: 25, color: Colors.indigo),
            onPressed: _showSortingDialog,
          ),
        ],
        title: Text(widget.listName,
        style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
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

                final items = _sortItems(snapshot.data!, _selectedSortOption);
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Card(
                        elevation: 2,

                        child: ShoppingItemTile(
                        item: item,
                        onToggle: () => _togglePurchase(item.id, item.isPurchased),
                        onDelete: () => _deleteItem(item.id),
                        onEdit: () => _showEditItemDialog(item),
                        ),
                      )
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.qr_code_scanner, color: Colors.indigo, size: 25),
              tooltip: 'Scan Barcode',
              onPressed: _openScanner,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.indigo[300],
                shape: BoxShape.circle
              ),
              padding: EdgeInsets.all(4),
              child:
              IconButton(onPressed: () {
                _addItemDialog();
                },
                  icon: Icon(
                    CupertinoIcons.plus,
                    color: Colors.white,
                    size: 33,
                  ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.lightbulb_outline, color: Colors.indigo, size: 25),
              tooltip: 'Suggestions',
              onPressed: () {
                _showSuggestions();
              },
            ),

          ],
        ),
      ),
    );
  }
}

