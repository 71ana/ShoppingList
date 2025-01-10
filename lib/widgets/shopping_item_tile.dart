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

  String _formatQuantity(String quantity) {
    final doubleValue = double.tryParse(quantity);
    if (doubleValue != null && doubleValue % 1 == 0) {
      return doubleValue.toInt().toString();
    }
    return quantity;
  }


  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted'),
          backgroundColor: Colors.red,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.redAccent,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
        child:GestureDetector(
      onTap: onToggle,
      child:
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.white,
          ),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: item.isPurchased ? Colors.transparent : Colors.deepPurpleAccent.withOpacity(0.15),
                      width: 2.0,
                    )
                  ),
                  child : CircleAvatar(
                    backgroundColor: item.isPurchased ? Colors.deepPurpleAccent[50]: Colors.white,
                    child: Icon(
                      Icons.check,
                      color: item.isPurchased ? Colors.deepPurpleAccent : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10), // Spacing

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                          color: item.isPurchased ? Colors.grey : Colors.black,
                          decorationColor: item.isPurchased ? Colors.grey : Colors.black,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    if (item.quantity != "0" && item.quantity.isNotEmpty)
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          alignment: Alignment.center,
                          height: 24,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                size: 14,
                                color: item.isPurchased ? Colors.grey[300] : Colors.black,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _formatQuantity(item.quantity),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.isPurchased ? Colors.grey[300] : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
