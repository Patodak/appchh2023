import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Crew {
  late String id;
  String name;

  Crew({required this.id, required this.name});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crew App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AddCrewPage(),
    );
  }
}

class AddCrewPage extends StatefulWidget {
  @override
  _AddCrewPageState createState() => _AddCrewPageState();
}

class _AddCrewPageState extends State<AddCrewPage> {
  final _formKey = GlobalKey<FormState>();
  final _crewNameController = TextEditingController();

  Future<void> _createCrew() async {
    if (_formKey.currentState!.validate()) {
      final name = _crewNameController.text;

      final crewReference =
          await FirebaseFirestore.instance.collection('crews').add({
        'name': name,
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Crew creada'),
            content: Text('La crew se ha creado exitosamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cerrar'),
              ),
            ],
          );
        },
      );

      _crewNameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Crew'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _crewNameController,
                decoration: InputDecoration(labelText: 'Nombre de la crew'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Ingrese un nombre para la crew';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _createCrew,
                child: Text('Crear Crew'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CrewListPage(),
                    ),
                  );
                },
                child: Text('Ver Crews'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CrewListPage extends StatefulWidget {
  @override
  _CrewListPageState createState() => _CrewListPageState();
}

class _CrewListPageState extends State<CrewListPage> {
  List<Crew> _crews = [];

  @override
  void initState() {
    super.initState();
    _fetchCrews();
  }

  Future<void> _fetchCrews() async {
    final crewsQuerySnapshot =
        await FirebaseFirestore.instance.collection('crews').get();
    final crews = crewsQuerySnapshot.docs
        .map((doc) => Crew(
              id: doc.id,
              name: doc.data()['name'] as String,
            ))
        .toList();
    setState(() {
      _crews = crews;
    });
  }

  Future<void> _deleteCrew(String crewId) async {
  final confirm = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar esta crew?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Eliminar'),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await FirebaseFirestore.instance
        .collection('crews')
        .doc(crewId)
        .delete();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Crew eliminada'),
          content: Text('La crew ha sido eliminada exitosamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchCrews();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
  Future<void> _updateCrewName(String crewId) async {
    TextEditingController _newNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modificar nombre de la crew'),
          content: TextFormField(
            controller: _newNameController,
            decoration: InputDecoration(labelText: 'Nuevo nombre'),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Ingrese un nombre para la crew';
              }
              return null;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String newName = _newNameController.text;
                await FirebaseFirestore.instance
                    .collection('crews')
                    .doc(crewId)
                    .update({
                  'name': newName,
                });

                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Nombre de la crew actualizado'),
                      content: Text('El nombre de la crew ha sido actualizado exitosamente.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _fetchCrews();
                          },
                          child: Text('Cerrar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crews'),
      ),
      body: ListView.builder(
        itemCount: _crews.length,
        itemBuilder: (context, index) {
          final crew = _crews[index];
          return ListTile(
            title: Text(crew.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _updateCrewName(crew.id),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteCrew(crew.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}