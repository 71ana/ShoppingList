
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/shopping_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  final String shoppingListsCollection = 'shoppingLists';
  final String itemsCollection = 'items';

  Future<void> createShoppingList(String uid, String listName) async {
    await _firestore.collection(shoppingListsCollection).add({
      'name': listName,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, String>>> getShoppingLists(String uid) {
    return _firestore
        .collection(shoppingListsCollection)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      print('Document data: $data');
      return {
        'id': doc.id,
        'name': data['name'] as String,
      };
    }).toList());
  }

  Future<bool> isProductInList(String listId, String productName) async {
    try {
      final querySnapshot = await _firestore
          .collection('items')
          .where('listId', isEqualTo: listId)
          .where('name', isEqualTo: productName)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking product in list: $e');
      return false;
    }
  }

  Future<void> addItemToList(String listId, ShoppingItem item) async {
    await _firestore.collection(itemsCollection).add({
      'listId': listId,
      'name': item.name,
      'quantity': item.quantity,
      'isPurchased': item.isPurchased,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ShoppingItem>> getItemsForList(String listId) {
    return _firestore
        .collection(itemsCollection)
        .where('listId', isEqualTo: listId)
        .orderBy('createdAt', descending: true) // Ensure 'createdAt' exists
        .snapshots()
        .map((snapshot) {
      print('Items fetched for listId $listId: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Item data: $data');
        return ShoppingItem(
          id: doc.id,
          name: data['name'] as String,
          quantity: data['quantity'] as String,
          isPurchased: data['isPurchased'] as bool,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  Future<List<String>> getItemsForUser(String userId) async {
    final listsSnapshot = await _firestore
        .collection(shoppingListsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    final listIds = listsSnapshot.docs.map((doc) => doc.id).toList();

    if (listIds.isEmpty) {
      return [];
    }

    final itemsSnapshot = await _firestore
        .collection(itemsCollection)
        .where('listId', whereIn: listIds)
        .get();

    final itemCounts = <String, int>{};
    for (var doc in itemsSnapshot.docs) {
      final itemName = doc.data()['name'] as String?;
      if (itemName != null && itemName.isNotEmpty) {
        itemCounts[itemName] = (itemCounts[itemName] ?? 0) + 1;
      }
    }

    final sortedItems = itemCounts.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedItems.map((entry) => entry.key).toList();
  }

  Future<int> getTotalItems(String userId) async {
      final listsSnapshot = await _firestore
          .collection('shoppingLists')
          .where('userId', isEqualTo: userId)
          .get();

      final listIds = listsSnapshot.docs.map((doc) {
        return doc.id;
      }).toList();

      final itemsSnapshot = await _firestore
          .collection('items')
          .where('listId', whereIn: listIds)
          .get();

      return itemsSnapshot.docs.length;
  }


  Future<int> getTotalLists(String userId) async {
    final listsSnapshot = await _firestore
        .collection('shoppingLists')
        .where('userId', isEqualTo: userId)
        .get();
    return listsSnapshot.docs.length;
  }

  int getTotalItemsForList(List<ShoppingItem> items) {
    return items.length;
  }

  int getCompletedItemsForList(List<ShoppingItem> items) {
    return items.where((item) => item.isPurchased).length;
  }

  Future<void> toggleItemPurchase(String itemId, bool isPurchased) async {
    await _firestore.collection(itemsCollection).doc(itemId).update({
      'isPurchased': isPurchased,
    });
  }

  Future<void> deleteItem(String itemId) async {
    await _firestore.collection(itemsCollection).doc(itemId).delete();
  }

  Future<void> editItem(String itemId, String newName, String newQuantity) async {
    await _firestore.collection(itemsCollection).doc(itemId).update({
      'name': newName,
      'quantity': newQuantity
    });
  }

  Future<void> deleteShoppingList(String listId) async {
    final batch = _firestore.batch();

    // Fetch all items linked to the list
    final itemsSnapshot = await _firestore
        .collection(itemsCollection)
        .where('listId', isEqualTo: listId)
        .get();

    for (var doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    final shoppingListRef =
    _firestore.collection(shoppingListsCollection).doc(listId);
    batch.delete(shoppingListRef);

    await batch.commit();
  }
}
