import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/shopping_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection names
  final String shoppingListsCollection = 'shoppingLists';
  final String itemsCollection = 'items';

  // Create a new shopping list
  Future<void> createShoppingList(String listName) async {
    await _db.collection(shoppingListsCollection).add({
      'name': listName,
      'createdAt': Timestamp.now(),
    });
  }

  // Fetch all shopping lists
  Stream<List<Map<String, String>>> getShoppingLists() {
    return FirebaseFirestore.instance
        .collection('shoppingLists')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'] as String,
      };
    }).toList());
  }


  // Add an item to a specific list
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    print('Adding item to list: $listId, ${item.name}');
    await _db.collection(itemsCollection).add({
      'listId': listId,
      'name': item.name,
      'isPurchased': item.isPurchased,
      'createdAt': Timestamp.now(),
    });
  }

  // Fetch items from a shopping list
  Stream<List<ShoppingItem>> getItemsForList(String listId) {
    return _db.collection(itemsCollection)
        .where('listId', isEqualTo: listId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShoppingItem(
          id: doc.id,
          name: doc['name'],
          isPurchased: doc['isPurchased'],
        );
      }).toList();
    });
  }

  // Update item status
  Future<void> toggleItemPurchase(String itemId, bool isPurchased) async {
    await _db.collection(itemsCollection).doc(itemId).update({
      'isPurchased': isPurchased,
    });
  }

  // Delete an item
  Future<void> deleteItem(String itemId) async {
    await _db.collection(itemsCollection).doc(itemId).delete();
  }

  //Edit an item
  Future<void> editItem(String itemId, String newName) async {
    await _db.collection(itemsCollection).doc(itemId).update({'name': newName});
  }

  // Delete a shopping list (along with its items)
  Future<void> deleteShoppingList(String listId) async {
    final shoppingList = _db.collection(shoppingListsCollection).doc(listId);
    final itemsSnapshot = await _db.collection(itemsCollection)
        .where('listId', isEqualTo: listId)
        .get();

    for (var doc in itemsSnapshot.docs) {
      await deleteItem(doc.id); // Delete each item
    }

    await shoppingList.delete(); //delete the list
  }
}
