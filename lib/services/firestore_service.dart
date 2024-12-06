import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  final String shoppingListsCollection = 'shoppingLists';
  final String itemsCollection = 'items';

  /// **Create a new shopping list**
  Future<void> createShoppingList(String uid, String listName) async {
    await _firestore.collection(shoppingListsCollection).add({
      'name': listName,
      'userId': uid, // Associate the list with the user's UID
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Listen for shopping lists for the current user
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


  /// **Add an item to a specific list**
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    await _firestore.collection(itemsCollection).add({
      'listId': listId,
      'name': item.name,
      'isPurchased': item.isPurchased,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// **Fetch items from a shopping list**
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


  /// **Toggle item purchase status**
  Future<void> toggleItemPurchase(String itemId, bool isPurchased) async {
    await _firestore.collection(itemsCollection).doc(itemId).update({
      'isPurchased': isPurchased,
    });
  }

  /// **Delete an item**
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection(itemsCollection).doc(itemId).delete();
  }

  /// **Edit an item**
  Future<void> editItem(String itemId, String newName) async {
    await _firestore.collection(itemsCollection).doc(itemId).update({
      'name': newName,
    });
  }

  /// **Delete a shopping list (and its items)**
  Future<void> deleteShoppingList(String listId) async {
    final batch = _firestore.batch();

    // Fetch all items linked to the list
    final itemsSnapshot = await _firestore
        .collection(itemsCollection)
        .where('listId', isEqualTo: listId)
        .get();

    // Queue deletion of all items
    for (var doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the shopping list
    final shoppingListRef =
    _firestore.collection(shoppingListsCollection).doc(listId);
    batch.delete(shoppingListRef);

    // Commit all batched operations
    await batch.commit();
  }
}
