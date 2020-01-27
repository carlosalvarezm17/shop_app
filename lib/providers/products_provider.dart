import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';

import 'package:shop_app/providers/product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  // var _showFavoritesOnly = false;

  final String authToken;

  Products(this.authToken, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchProducts() async {
    final url = 'https://flutter-update-ceam.firebaseio.com/products.json?auth=$authToken';
    final resp = await http.get(url);
    final extractedData = json.decode(resp.body) as Map<String, dynamic>;
    final List<Product> loadedProducts = [];
    if (extractedData == null) {
      return;
    }
    extractedData.forEach((prodId, prodData) {
      loadedProducts.add(Product(
        id: prodId,
        title: prodData['title'],
        description: prodData['description'],
        price: prodData['price'],
        isFavorite: prodData['isFavorite'],
        imageUrl: prodData['imageUrl'],
      ));
    });
    _items = loadedProducts;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    const url = 'https://flutter-update-ceam.firebaseio.com/products.json';
    try {
      final resp = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'isFavorite': product.isFavorite,
        }),
      );

      final newProduct = Product(
        id: json.decode(resp.body)['name'],
        title: product.title,
        price: product.price,
        description: product.description,
        imageUrl: product.imageUrl,
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProd) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    final url = 'https://flutter-update-ceam.firebaseio.com/products/$id.json';
    await http.patch(
      url,
      body: json.encode({
        'title': newProd.title,
        'description': newProd.description,
        'imageUrl': newProd.imageUrl,
        'price': newProd.price,
      }),
    );
    _items[prodIndex] = newProd;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    final url = 'https://flutter-update-ceam.firebaseio.com/products/$id.json';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final resp = await http.delete(url);

    if (resp.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product');
    }
    existingProduct = null;
    
  }
}
