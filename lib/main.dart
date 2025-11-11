import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nested Users CRUD',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UserScreen(),
    );
  }
}

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List users = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? editingUserId;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // Fetch all users
  fetchUsers() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/users'));
    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
      });
    }
  }

  // Add or Update user
  saveUser() async {
    final user = {
      "name": nameController.text,
      "age": int.tryParse(ageController.text) ?? 0,
      "address": {
        "street": streetController.text,
        "city": cityController.text,
        "country": countryController.text,
      },
      "contacts": [
        {"type": "phone", "detail": phoneController.text},
        {"type": "email", "detail": emailController.text},
      ],
    };

    if (editingUserId == null) {
      await http.post(
        Uri.parse('http://127.0.0.1:8000/users'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user),
      );
    } else {
      await http.put(
        Uri.parse('http://127.0.0.1:8000/users/$editingUserId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user),
      );
    }

    clearForm();
    fetchUsers();
    Navigator.pop(context);
  }

  deleteUser(String id) async {
    await http.delete(Uri.parse('http://127.0.0.1:8000/users/$id'));
    fetchUsers();
  }

  editUser(Map u) {
    editingUserId = u["id"];
    nameController.text = u["name"];
    ageController.text = u["age"].toString();
    streetController.text = u["address"]["street"];
    cityController.text = u["address"]["city"];
    countryController.text = u["address"]["country"];
    var phone = u["contacts"].firstWhere(
      (c) => c["type"] == "phone",
      orElse: () => {"detail": ""},
    )["detail"];
    var email = u["contacts"].firstWhere(
      (c) => c["type"] == "email",
      orElse: () => {"detail": ""},
    )["detail"];
    phoneController.text = phone;
    emailController.text = email;
    showFormDialog();
  }

  clearForm() {
    editingUserId = null;
    nameController.clear();
    ageController.clear();
    streetController.clear();
    cityController.clear();
    countryController.clear();
    phoneController.clear();
    emailController.clear();
  }

  showFormDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editingUserId == null ? "Add User" : "Edit User"),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextFormField(
                  controller: ageController,
                  decoration: InputDecoration(labelText: "Age"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: streetController,
                  decoration: InputDecoration(labelText: "Street"),
                ),
                TextFormField(
                  controller: cityController,
                  decoration: InputDecoration(labelText: "City"),
                ),
                TextFormField(
                  controller: countryController,
                  decoration: InputDecoration(labelText: "Country"),
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: "Phone"),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              clearForm();
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(onPressed: saveUser, child: Text("Save")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nested Users")),
      floatingActionButton: FloatingActionButton(
        onPressed: showFormDialog,
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          var u = users[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${u["name"]} (${u["age"]})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Address: ${u["address"]["street"]}, ${u["address"]["city"]}, ${u["address"]["country"]}',
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Contacts: ${u["contacts"].map((c) => "${c["type"]}: ${c["detail"]}").join(", ")}',
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => editUser(u),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteUser(u["id"]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
