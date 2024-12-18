import 'package:flutter/material.dart';
import 'package:customer_app/src/models/customer.dart';

class Home extends StatelessWidget {
  final Customer customer;

  Home({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${customer.id}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Name: ${customer.name}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Email: ${customer.email}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Password: ${customer.password}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Pin: ${customer.pin}', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
