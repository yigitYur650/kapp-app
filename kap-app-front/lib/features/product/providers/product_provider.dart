// lib/features/product/providers/product_provider.dart

import 'package:flutter/foundation.dart';
import '../domain/product_model.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;
  String? _errorMessage;
  List<Product> _items = [];

  // Onay bekleyen toggle'lar (animasyon için)
  final Set<String> _pendingToggles = {};

  ProductStatus get status        => _status;
  String? get errorMessage        => _errorMessage;
  Set<String> get pendingToggles  => _pendingToggles;

  /// Tiklenmeyen ürünler (Alınacaklar sekmesi)
  List<Product> get needs => _items.where((p) => !p.checked).toList();

  /// Tiklenen ürünler (Alınanlar sekmesi)
  List<Product> get got   => _items.where((p) => p.checked).toList();

  // ─── Veri Yükleme ─────────────────────────────────────────────────────────

  Future<void> loadItems(String listId) async {
    _status = ProductStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400)); // shimmer gösterimi

    try {
      // TODO: _repo.getItems(listId)
      _items = _mockItems();
      _status = ProductStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProductStatus.error;
    }
    notifyListeners();
  }

  // ─── Toggle (gecikme + animasyon desteğiyle) ──────────────────────────────

  /// Kartı 300ms "beklemede" durumuna alır, sonra gerçek toggle yapar.
  Future<void> toggleItem(String id) async {
    if (_pendingToggles.contains(id)) return; // çift tıklamayı engelle

    final idx = _items.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    // 1) Kartı animasyon moduna al → UI animasyonu başlasın
    _pendingToggles.add(id);
    notifyListeners();

    // 2) Animasyonun tamamlanması için bekle (kart uçarken)
    await Future.delayed(const Duration(milliseconds: 320));

    // 3) Gerçek toggle
    _items[idx] = _items[idx].copyWith(checked: !_items[idx].checked);
    _pendingToggles.remove(id);
    notifyListeners();

    // TODO: _repo.toggleItem(...)
  }

  // ─── Ürün Ekleme ──────────────────────────────────────────────────────────

  Future<void> addItem({
    required String name,
    required int quantity,
    String? unit,
    String? category,
  }) async {
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      checked: false,
    );
    _items.insert(0, product);
    notifyListeners();
    // TODO: _repo.addItem(...)
  }

  // ─── Ürün Düzenleme ───────────────────────────────────────────────────────

  Future<void> updateItem({
    required String id,
    required String name,
    required int quantity,
    String? unit,
    String? category,
  }) async {
    final idx = _items.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
    );
    notifyListeners();
    // TODO: _repo.updateItem(...)
  }

  // ─── Ürün Silme ───────────────────────────────────────────────────────────

  Future<void> deleteItem(String id) async {
    // Sil animasyonu için önce pending'e ekle, sonra gerçekten sil
    _pendingToggles.add(id);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 280));

    _items.removeWhere((p) => p.id == id);
    _pendingToggles.remove(id);
    notifyListeners();
    // TODO: _repo.deleteItem(...)
  }

  // ─── Mock Veri ───────────────────────────────────────────────────────────

  List<Product> _mockItems() {
    return [
      const Product(id: '1', name: 'Süt', quantity: 2, unit: 'lt', category: 'dairy'),
      const Product(id: '2', name: 'Ekmek', quantity: 1, unit: 'adet', category: 'bakery'),
      const Product(id: '3', name: 'Yumurta', quantity: 12, unit: 'adet', category: 'dairy'),
      const Product(id: '4', name: 'Domates', quantity: 1, unit: 'kg', category: 'produce'),
      const Product(id: '5', name: 'Salatalık', quantity: 500, unit: 'gr', category: 'produce'),
      const Product(id: '6', name: 'Deterjan', quantity: 1, unit: 'adet', category: 'cleaning', checked: true),
      const Product(id: '7', name: 'Zeytinyağı', quantity: 1, unit: 'lt', category: 'other'),
    ];
  }
}
