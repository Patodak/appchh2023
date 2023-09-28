import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'numeric_keypad.dart';
import 'manage_roles.dart'; // Importa la página manage_roles.dart
 // Importa la página permissions_management.dart
import 'create_participant.dart';
import 'create_judge.dart';
import 'add_crew.dart'; // Importa la página add_crew.dart

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;
  bool _isNumericKeypadVisible = true;

  TextEditingController _passwordController = TextEditingController();

  bool _isPasswordCorrect(String password) {
    const String adminPassword = '564316';
    return password == adminPassword;
  }

  Widget _buildManageRolesButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageRoles(),
          ),
        );
      },
      icon: Icon(Icons.supervised_user_circle),
    );
  }

  Widget _buildAccessCreateParticipantButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateParticipantPage(),
          ),
        );
      },
      icon: Icon(Icons.person_add),
      label: Text('Agregar participante'),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
      ),
    );
  }

  Widget _buildAccessCreateJudgeButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateJudgePage(),
          ),
        );
      },
      icon: Icon(Icons.person_add_alt_1),
      label: Text('Agregar juez'),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
      ),
    );
  }

  Widget _buildAccessAddCrewButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddCrewPage(),
          ),
        );
      },
      icon: Icon(Icons.group_add),
      label: Text('Agregar crew'),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.orange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página de administrador'),
        actions: _isAdmin
            ? [
                _buildManageRolesButton(context),
              ]
            : [],
      ),
      body: _isAdmin
          ? SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 16),
                  _buildAccessCreateParticipantButton(context),
                  SizedBox(height: 16),
                  _buildAccessCreateJudgeButton(context),
                  SizedBox(height: 16),
                  _buildAccessAddCrewButton(context),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ingrese la clave de 6 dígitos'),
                  SizedBox(height: 16),
                  _isNumericKeypadVisible
                      ? NumericKeypad(
                          onValueChange: (value) {
                            _passwordController.text = value;
                          },
                          onConfirm: () {
                            setState(() {
                              _isAdmin =
                                  _isPasswordCorrect(_passwordController.text);
                            });

                            if (!_isAdmin) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Clave incorrecta')),
                              );
                              _passwordController.clear();
                            } else {
                              _isNumericKeypadVisible = false;
                            }
                          },
                        )
                      : Container(),
                ],
              ),
            ),
    );
  }
}