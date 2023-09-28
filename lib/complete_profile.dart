import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'select_dance_and_skill_page.dart';

class CompleteProfilePage extends StatefulWidget {
  @override
  _CompleteProfilePageState createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  String _genderValue = 'Seleccionar Género';
  double _experienceYears = 0;

  DateTime? _selectedDate;
  int? _age;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerText(
                    'Por favor, completa la información adicional a continuación:'),
                SizedBox(height: 16),
                _buildNameField(),
                _buildUsernameField(),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context),
                        child: AbsorbPointer(
                          child: _buildFormField(
                              _dobController, 'Fecha de nacimiento'),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildGenderDropdown(),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(_locationController, 'Ubicación'),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                          _contactController, 'Número de contacto', '+569'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _headerText('Años de Baile'),
                _buildExperienceField(),
                SizedBox(height: 16),
                _headerText('Foto de Perfil'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DanceAndSkillPage(),
                      ),
                    );
                  },
                  child: Text("Ir a Estilo de Baile y Nivel de Habilidades"),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        bool isUpdated = await _updateProfile();
                        if (isUpdated) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ha ocurrido un problema al guardar los cambios. Por favor, inténtelo de nuevo.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text("Guardar"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _buildFormField(
      TextEditingController controller, String hintText,
      [String? prefix]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefix: prefix != null ? Text(prefix) : null,
      ),
    );
  }

  Widget _headerText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _fullNameController,
      decoration: InputDecoration(
        hintText: 'Nombre Completo',
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        hintText: 'Nombre Usuario',
      ),
    );
  }

  void _pickDate(BuildContext context) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dobController.text =
            "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        _age = DateTime.now().year - _selectedDate!.year;
      });
    }
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _genderValue,
        onChanged: (String? newValue) {
          setState(() {
            _genderValue = newValue!;
          });
        },
        items: <String>[
          'Seleccionar Género',
          'Masculino',
          'Femenino',
          'Otro',
          'Prefiero no decir'
        ].map<DropdownMenuItem<String>>(
          (String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildExperienceField() {
    final TextEditingController controller =
        TextEditingController(text: _experienceYears.toStringAsFixed(0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Años de Baile',
          style: TextStyle(fontSize: 16),
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: (String value) {
                  setState(() {
                    int years = int.tryParse(value) ?? 0;

                    if (years > _age!) {
                      controller.text = _age.toString();
                      _experienceYears = _age!.toDouble();
                    } else {
                      _experienceYears = years.toDouble();
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: '0',
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Text(
                'años',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        Map<String, dynamic>? userData =
            userProfile.data() as Map<String, dynamic>? ?? {};

        _fullNameController.text = userData['nombre completo'] ?? "";
        _usernameController.text = userData['nombre usuario'] ?? "";
        _dobController.text = userData['fecha de nacimiento'] ?? "";
        _genderValue = userData['género'] ?? 'Seleccionar Género';
        _locationController.text = userData['ubicación'] ?? "";
        _age = _selectedDate != null
            ? DateTime.now().year - _selectedDate!.year
            : null;
        _contactController.text =
            (userData['contacto'] as String? ?? "").replaceFirst('+569', '');
        _experienceYears = userData['años de baile'] as double? ?? 0;
      });
    }
  }

  Future<bool> _updateProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        DocumentSnapshot userDoc = await userRef.get();

        if (!userDoc.exists) {
          // Si el documento del usuario no existe, lanzamos un error
          throw ErrorDescription("Documento de usuario no encontrado");
        } else {
          // Si el documento existe, actualizamos el documento con los detalles del perfil
          await userRef.update({
            'nombre completo': _fullNameController.text,
            'nombre usuario': _usernameController.text,
            'fecha de nacimiento': _dobController.text,
            'género': _genderValue,
            'ubicación': _locationController.text,
            'contacto': '+569' + _contactController.text,
            'años de baile': _experienceYears,
            'role': (userDoc.data() as Map<String, dynamic>)['role'],
          });
        }

        return true;
      } catch (e) {
        print('Error actualizando perfil de usuario: $e');
        return false;
      }
    }

    return false;
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Hiphop',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CompleteProfilePage(),
    );
  }
}