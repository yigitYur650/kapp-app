// lib/features/product/data/product_repository.dart

import '../../../core/network/api_client.dart';

class ProductRepository {
  final ApiClient _client;
  ProductRepository(this._client);

  Future<List<dynamic>> getItems(String listId) async {
    final res = await _client.get('/lists/$listId/items');
    return res['items'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> addItem({
    required String listId,
    required String name,
    required int quantity,
    String? unit,
    String? category,
  }) async {
    return _client.post('/lists/$listId/items', {
      'name': name,
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
    });
  }

  Future<Map<String, dynamic>> toggleItem({
    required String listId,
    required String itemId,
    required bool checked,
  }) async {
    return _client.put('/lists/$listId/items/$itemId', {'checked': checked});
  }

  Future<void> deleteItem({
    required String listId,
    required String itemId,
  }) async {
    await _client.delete('/lists/$listId/items/$itemId');
  }
}
