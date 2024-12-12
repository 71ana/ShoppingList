import 'package:cloud_firestore/cloud_firestore.dart';
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
        .collection('shoppingLists')
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
          .collection('items') // Replace with your collection name
          .where('listId', isEqualTo: listId) // Filter by list ID
          .where('name', isEqualTo: productName) // Filter by product name
          .get();

      // Return true if any documents match, false otherwise
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking product in list: $e');
      return false; // Assume product is not in the list if an error occurs
    }
  }

  /// **Add an item to a specific list**
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    await _firestore.collection(itemsCollection).add({
      'listId': listId,
      'name': item.name,
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
          isPurchased: data['isPurchased'] as bool,
        );
      }).toList();
    });
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

  Future<void> editItem(String itemId, String newName) async {
    await _firestore.collection(itemsCollection).doc(itemId).update({
      'name': newName,
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
