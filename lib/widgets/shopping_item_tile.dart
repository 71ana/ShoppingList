import 'package:flutter/material.dart';
import '../models/shopping_item.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ShoppingItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        item.name,
        style: TextStyle(
          fontSize: 16,
          decoration: item.isPurchased ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      trailing: Wrap(
        spacing: 12, // Adds space between the buttons
        children: [
          IconButton(
            icon: Icon(
              Icons.check_circle,
              color: item.isPurchased ? Colors.green : Colors.grey,
            ),
            onPressed: onToggle,
          ),
          IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit)),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}


