import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_drawer.dart';
import '../providers/order.dart' show Order;
import '../widgets/order_item.dart';

class OrderScreen extends StatelessWidget {
  static const routeName = '/Orders';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Orders'),
        ),
        drawer: AppDrawer(),
        body: FutureBuilder(
          builder: (ctx, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              if (dataSnapshot.error != null) {
                return Center(
                  child: Text('An error occured!'),
                );
              } else {
                return Consumer<Order>(
                  builder: (ctx, orderData, child) {
                    return ListView.builder(
                      itemBuilder: (ctx, i) {
                        return OrderItem(orderData.orders[i]);
                      },
                      itemCount: orderData.orders.length,
                    );
                  },
                );
              }
            }
          },
          future:
              Provider.of<Order>(context, listen: false).fetchAndSetOrders(),
        ));
  }
}
