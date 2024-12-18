import 'dart:convert';
import 'package:http/http.dart' as http;

class Customer {
  final String id;
  final String name;
  final String email;
  final String pin;
  final String password;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.pin,
    required this.password,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      pin: json['pin'],
      password: json['password'],
    );
  }
}

class CustomerService {
  final String baseUrl = 'http://localhost/w-16-MobApp';

  Future<Customer?> getCustomer(
      String email, String password, String pin) async {
    final url =
        Uri.parse('$baseUrl/read.php?email=$email&password=$password&pin=$pin');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Customer.fromJson(data['customer']);
      } else {
        throw (data['message']);
      }
    } else {
      throw Exception('Failed to fetch customer');
    }
  }

  Future<bool> createCustomer(
      String name, String email, String pin, String password) async {
    final url = Uri.parse('$baseUrl/create.php');

    final response = await http.post(
      url,
      body: {
        'name': name,
        'email': email,
        'pin': pin.toString(),
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to create customer');
    }
  }
}
