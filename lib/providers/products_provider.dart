import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import './product.dart';
import '../models/http_exception.dart';

class ProductsProvider with ChangeNotifier {
  List<Product> _items = [];
  final String authToken;
  final String userId;

  ProductsProvider(this.authToken, this._items, this.userId);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favouriteItems {
    return _items.where((prodItem) => prodItem.isFavourite).toList();
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="createId"&equalTo="$userId"' : '';
    var url =
        'https://flutterupdate-a25d6-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url =
          'https://flutterupdate-a25d6-default-rtdb.firebaseio.com/userFavourites/$userId.json?auth=$authToken';
      final favouriteResponse = await http.get(url);
      final favouriteData = json.decode(favouriteResponse.body);
      final List<Product> loadedProduct = [];
      extractedData.forEach((prodID, prodData) {
        loadedProduct.add(
          Product(
              isFavourite: favouriteData == null
                  ? false
                  : favouriteData[prodID] ?? false,
              description: prodData['description'],
              id: prodID,
              imageUrl: prodData['imageUrl'],
              price: prodData['price'],
              title: prodData['title']),
        );
      });
      _items = loadedProduct;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://flutterupdate-a25d6-default-rtdb.firebaseio.com/products.json?auth=$authToken';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'createId': userId,
        }),
      );
      final newProduct = Product(
          description: product.description,
          id: json.decode(response.body)['name'],
          imageUrl: product.imageUrl,
          price: product.price,
          title: product.title);
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      throw error;
    }
    // print(json.decode(response.body));
    // throw error;
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((element) => element.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://flutterupdate-a25d6-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {}
  }

  Future<void> deleteProdct(String id) async {
    final url =
        'https://flutterupdate-a25d6-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
    final existingIndex = _items.indexWhere((element) => element.id == id);
    var existingProduct = _items[existingIndex];

    _items.removeAt(existingIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not Delete product.');
    }
    existingProduct = null;
  }

  Product findByID(String id) {
    return _items.firstWhere((element) => element.id == id);
  }
}
