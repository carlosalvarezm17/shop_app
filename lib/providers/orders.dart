import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';

import 'package:shop_app/providers/cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    const url = 'https://flutter-update-ceam.firebaseio.com/orders.json';
    final timeStamp = DateTime.now();
    try {
      final resp = await http.post(
        url,
        body: json.encode({
          'amount': total,
          'products': cartProducts
              .map(
                (cp) => {
                  'id': cp.id,
                  'title': cp.title,
                  'quantity': cp.quantity,
                  'price': cp.price,
                },
              )
              .toList(),
          'dateTime': timeStamp.toIso8601String(),
        }),
      );

      _orders.insert(
        0,
        OrderItem(
          id: json.decode(resp.body)['name'],
          amount: total,
          products: cartProducts,
          dateTime: timeStamp,
        ),
      );
      notifyListeners();
    } catch (err) {
      throw HttpException('Could not add order');
    }
  }
}
