import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Participant {
  late String id;
  String name;
  List<String> categories;

  Participant({required this.id, required this.name, required this.categories});
}

class CreateParticipantPage extends StatefulWidget {
  @override
  _CreateParticipantPageState createState() => _CreateParticipantPageState();
}

class _CreateParticipantPageState extends State<CreateParticipantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categories = [
    '1vs1 Breaking',
    '3vs3 Breaking',
    '1vs1 All Style',
    '7 to Smoke Hip Hop',
  ];
  final _selectedCategories = <String>{};
  List<Participant> _participants = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchParticipants() async {
    final participantsQuerySnapshot =
        await FirebaseFirestore.instance.collection('participants').get();
    final participants = participantsQuerySnapshot.docs
        .map((doc) => Participant(
              id: doc.id,
              name: doc.data()['name'] as String,
              categories: List<String>.from(doc.data()['categories']),
            ))
        .toList();
    setState(() {
      _participants = participants;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('participants')
          .where('name', isEqualTo: name)
          .where('categories', isEqualTo: _selectedCategories.toList())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final participantId = querySnapshot.docs.first.id;

        await FirebaseFirestore.instance.collection('participants').doc(participantId).update({
          'name': name,
          'categories': _selectedCategories.toList(),
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('¡Participante actualizado!'),
              content: Text('El participante se ha actualizado exitosamente.'),
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
      } else {
        final participantReference = await FirebaseFirestore.instance.collection('participants').add({
          'name': name,
          'categories': _selectedCategories.toList(),
        });

        final newParticipant = Participant(
          id: participantReference.id,
          name: name,
          categories: _selectedCategories.toList(),
        );

        await FirebaseFirestore.instance.collection('participants').doc(newParticipant.id).set({
          'name': newParticipant.name,
          'categories': newParticipant.categories.toList(),
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('¡Participante creado!'),
              content: Text('El participante se ha creado exitosamente.'),
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
      }
      _nameController.clear();
      setState(() {
        _selectedCategories.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear participante'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Ingrese un nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Categorías:'),
              Expanded(
                child: ListView(
                  children: _categories.map((category) {
                    return CheckboxListTile(
                      title: Text(category),
                      value: _selectedCategories.contains(category),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Crear participante'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParticipantListPage(),
                    ),
                  ).then((_) {
                    _fetchParticipants();
                  });
                },
                child: Text('Ver participantes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParticipantListPage extends StatefulWidget {
  @override
  _ParticipantListPageState createState() => _ParticipantListPageState();
}

class _ParticipantListPageState extends State<ParticipantListPage> {
  List<Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    final participantsQuerySnapshot =
        await FirebaseFirestore.instance.collection('participants').get();
    final participants = participantsQuerySnapshot.docs
        .map((doc) => Participant(
              id: doc.id,
              name: doc.data()['name'] as String,
              categories: List<String>.from(doc.data()['categories']),
            ))
        .toList();
    setState(() {
      _participants = participants;
    });
  }

  Future<void> _deleteParticipant(String participantId) async {
    await FirebaseFirestore.instance
        .collection('participants')
        .doc(participantId)
        .delete();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¡Participante eliminado!'),
          content: Text('El participante ha sido eliminado exitosamente.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participantes'),
      ),
      body: ListView.builder(
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final participant = _participants[index];
          return ListTile(
            title: Text(participant.name),
            subtitle: Text(participant.categories.join(', ')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ParticipantDetailsPage(participant: participant),
                ),
              ).then((_) {
                _fetchParticipants();
              });
            },
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Eliminar participante'),
                      content: Text('¿Está seguro de que desea eliminar este participante?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteParticipant(participant.id);
                          },
                          child: Text('Eliminar'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ParticipantDetailsPage extends StatefulWidget {
  final Participant participant;

  ParticipantDetailsPage({required this.participant});

  @override
  _ParticipantDetailsPageState createState() => _ParticipantDetailsPageState();
}

class _ParticipantDetailsPageState extends State<ParticipantDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categories = [
    '1vs1 Breaking',
    '2vs2 Breaking',
    '1vs1 All Style',
    '7 to Smoke Hip Hop',
  ];
  final _selectedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.participant.name;
    _selectedCategories.addAll(widget.participant.categories);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedParticipant = Participant(
        id: widget.participant.id,
        name: _nameController.text,
        categories: _selectedCategories.toList(),
      );

      await FirebaseFirestore.instance
          .collection('participants')
          .doc(widget.participant.id)
          .update({
        'name': updatedParticipant.name,
        'categories': updatedParticipant.categories,
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('¡Participante actualizado!'),
            content: Text('El participante se ha actualizado exitosamente.'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del participante'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre:',
                  style: TextStyle(fontSize: 18),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Ingrese un nombre';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                Text(
                  'Categorías:',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children: _categories.map((category) {
                    return FilterChip(
                      label: Text(category),
                      selected: _selectedCategories.contains(category),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Actualizar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ParticipantEditPage extends StatefulWidget {
  final Participant participant;

  ParticipantEditPage({required this.participant});

  @override
  _ParticipantEditPageState createState() => _ParticipantEditPageState();
}

class _ParticipantEditPageState extends State<ParticipantEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categories = [
    '1vs1 Breaking',
    '3vs3 Breaking',
    '1vs1 All Style',
    '7 to Smoke Hip Hop',
  ];
  final _selectedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.participant.name;
    _selectedCategories.addAll(widget.participant.categories);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedParticipant = Participant(
        id: widget.participant.id,
        name: _nameController.text,
        categories: _selectedCategories.toList(),
      );

      await FirebaseFirestore.instance
          .collection('participants')
          .doc(widget.participant.id)
          .update({
        'name': updatedParticipant.name,
        'categories': updatedParticipant.categories,
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('¡Participante actualizado!'),
            content: Text('El participante se ha actualizado exitosamente.'),
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
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar participante'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Ingrese un nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Categorías:'),
              Expanded(
                child: ListView(
                  children: _categories.map((category) {
                    return CheckboxListTile(
                      title: Text(category),
                      value: _selectedCategories.contains(category),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Actualizar participante'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}