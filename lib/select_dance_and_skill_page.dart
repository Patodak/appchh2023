import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DanceAndSkillPage extends StatefulWidget {
  @override
  _DanceAndSkillPageState createState() => _DanceAndSkillPageState();
}

class _DanceAndSkillPageState extends State<DanceAndSkillPage> {
  Map<String, double> skillLevels = {};
  Map<String, bool> teachingInterest = {};
  Map<String, bool> danceInterest = {};
  List<String> danceStyles = [
    "Breakdance",
    "Hip Hop",
    "Popping",
    "Dancehall",
    "Afro",
    "Vogue",
    "House"
  ];

  TextEditingController newStyleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkAndCreateUser();
    loadData();
  }

  @override
  void dispose() {
    newStyleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estilos de Baile'),
        actions: [
    TextButton.icon(
      onPressed: saveData,
      icon: Icon(Icons.save),
      label: Text('Guardar'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: danceStyles.length,
              itemBuilder: (BuildContext context, int index) {
                String style = danceStyles[index];
                bool hasSkill = skillLevels.containsKey(style);
                bool hasTeachingInterest = teachingInterest.containsKey(style);

                return Column(
                  children: [
                    CheckboxListTile(
                      title: Text(style),
                      value: danceInterest[style] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          danceInterest[style] = value!;
                          if (value!) {
                            if (!hasSkill) {
                              skillLevels[style] = 1.0;
                            }
                            if (!hasTeachingInterest) {
                              teachingInterest[style] = false;
                            }
                          } else {
                            skillLevels.remove(style);
                            teachingInterest.remove(style);
                          }
                        });
                      },
                    ),
                      if (hasSkill)
                      Slider(
                        value: skillLevels[style]!,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        onChanged: (double value) {
                          setState(() {
                            skillLevels[style] = value;
                          });
                        },
                        onChangeStart: (double value) {},
                        onChangeEnd: (double value) {},
                        label: skillLevels[style]!.toInt().toString(),
                      ),
                    if (hasTeachingInterest)
                      SwitchListTile(
                        title: Text("¿Dispuesto a enseñar?"),
                        value: teachingInterest[style]!,
                        onChanged: (bool value) {
                          setState(() {
                            teachingInterest[style] = value;
                          });
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Agregar estilo de baile'),
                      content: TextField(
                        controller: newStyleController,
                        decoration: InputDecoration(
                          labelText: 'Nuevo estilo de baile',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            String newStyle = newStyleController.text;
                            if (newStyle.isNotEmpty) {
                              setState(() {
                                danceStyles.add(newStyle);
                              });
                            }
                            Navigator.pop(context);
                          },
                          child: Text('Guardar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Agregar estilo de baile'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> checkAndCreateUser() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Obtener la referencia al documento del usuario actual
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    // Verificar si el documento existe
    DocumentSnapshot userData = await userRef.get();

    if (!userData.exists) {
      // Crear un nuevo documento con la información del usuario
      await userRef.set({
        // Agrega los campos adicionales que necesites almacenar para el usuario
        'userId': userId,
      });
    }
  }

  Future<void> saveData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Obtener la referencia al documento del usuario actual
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    // Actualizar los datos específicos del usuario en Firebase Firestore
    await userRef.update({
      'skillLevels': skillLevels,
      'teachingInterest': teachingInterest,
      'danceInterest': danceInterest,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Cambios guardados correctamente."),
      ),
    );
  }

    Future<void> loadData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Obtener la referencia al documento del usuario actual
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    // Obtener los datos del usuario desde Firebase Firestore
    DocumentSnapshot userData = await userRef.get();

    if (userData.exists) {
      // Cargar datos existentes
      Map<String, dynamic>? data = userData.data() as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          skillLevels = (data['skillLevels'] ?? {})
            .map<String, double>((key, value) => MapEntry<String, double>(key, value.toDouble()));
          teachingInterest = (data['teachingInterest'] ?? {})
            .map<String, bool>((key, value) => MapEntry<String, bool>(key, value as bool));
          danceInterest = (data['danceInterest'] ?? {})
            .map<String, bool>((key, value) => MapEntry<String, bool>(key, value as bool));

          // Verificar si los estilos de baile ya tienen valor
          for (String style in danceStyles) {
            if (!danceInterest.containsKey(style)) {
              danceInterest[style] = false;
            }
    
            if (!skillLevels.containsKey(style)) {
              skillLevels[style] = 1.0;
            }
    
            if (!teachingInterest.containsKey(style)) {
              teachingInterest[style] = false;
            }
          }
        });
      }
    }
  }}