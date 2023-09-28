import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme_notifier.dart';
import 'SelectCategory.dart';

class OneToOneBreakingEvalPage extends StatelessWidget {
  final String selectedJudgeId;
  final String selectedJudgeName;
  final String categoryName;

  OneToOneBreakingEvalPage(
      {required this.selectedJudgeId,
      required this.selectedJudgeName,
      required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final appState = Provider.of<AppState>(context);
    final selectedJudgeId = appState.selectedJudgeId;
    final selectedJudgeName = appState.selectedJudgeName;
    return Scaffold(
      body: JudgingPage(
        themeNotifier: themeNotifier,
        selectedJudgeName: selectedJudgeName,
        selectedJudgeId: selectedJudgeId,
        categoryName: categoryName,
      ),
    );
  }
}

Future<void> saveOriginalRole(String role) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('originalRole', role);
}

Future<String> getOriginalRole() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('originalRole') ?? '';
}

class JudgingPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final String selectedJudgeName;
  final String categoryName;
  final String selectedJudgeId;

  JudgingPage(
      {required this.themeNotifier,
      required this.selectedJudgeName,
      required this.selectedJudgeId,
      required this.categoryName});

  @override
  _JudgingPageState createState() => _JudgingPageState();
}

final TextEditingController _commentsController = TextEditingController();

class _JudgingPageState extends State<JudgingPage> {
  List<String> criterios = [
    'Técnica',
    'Musicalidad',
    'Originalidad',
    'Creatividad',
    'Actitud y Presencia Escénica',
  ];
  Map<String, double> puntajes = {};
  Stream<QuerySnapshot> get _judgesStream =>
      FirebaseFirestore.instance.collection('jueces').snapshots();
  String? participanteSeleccionado;
  String? selectedJudgeId;
  String? selectedJudgeName;

  final ValueNotifier<int> totalNotifier = ValueNotifier(0);

  int calcularPuntuacionTotal() {
    int total = 0;
    puntajes.forEach((criterio, puntuacion) {
      total += puntuacion.toInt();
    });
    return total;
  }

  Future<String> obtenerNombreJuez() async {
    final firestore = FirebaseFirestore.instance;

  try {
      print(
          'Valor de selectedJudgeId: ${widget.selectedJudgeId}'); // Agrega este mensaje de registro
      DocumentSnapshot document = await firestore
          .collection('jueces')
          .doc(widget.selectedJudgeId)
          .get();
      return document.get('nombre_juez') as String;
    } catch (e) {
      print('Error al obtener el nombre del juez: $e');
      return 'Error';
    }
  }

  @override
  void initState() {
    super.initState();
    selectedJudgeName = widget.selectedJudgeName;
    criterios.forEach((criterio) {
      puntajes[criterio] = 0;
    });
  }

  Future<void> actualizarResultados(
      String participanteId,
      Map<String, dynamic> nuevaInfo,
      String nombreParticipante,
      String nombreJuez) async {
    final firestore = FirebaseFirestore.instance;
    final resultadoRef = firestore.collection('1vs1Breaking_resultados')
        .doc(participanteId);
    final snapshot = await resultadoRef.get();

    int nuevoTotal;
    Map<String, dynamic> nuevoDetalle;

    if (snapshot.exists) {
      // Si el documento existe, actualiza el total y el detalle
      Map<String, dynamic> detalleActual = snapshot.data()!['detalle'];

      // Calculamos el nuevoTotal restando la puntuación anterior y sumando la nueva puntuación
      int puntuacionAnterior =
          detalleActual[widget.selectedJudgeName]?['total'] ?? 0;
      nuevoTotal =
          snapshot.data()!['total'] - puntuacionAnterior + nuevaInfo['total'];

      // Actualizamos el detalle para el juez específico
      detalleActual[widget.selectedJudgeName] = {
        'puntajes': nuevaInfo['detalle']['puntajes'],
        'comentarios': nuevaInfo['detalle']['comentarios'],
        'total': nuevaInfo['total'], // Agregamos el campo 'total' al detalle
      };

      await resultadoRef.set({
        'nombre_participante': nombreParticipante,
        'nombre_juez': nombreJuez,
        'total': nuevoTotal,
        'detalle': detalleActual,
      }, SetOptions(merge: true));
    } else {
      // Si el documento no existe, asigna la nueva información
      nuevoTotal = nuevaInfo['total'];
      nuevoDetalle = {
        widget.selectedJudgeName: {
          'puntajes': nuevaInfo['detalle']['puntajes'],
          'comentarios': nuevaInfo['detalle']['comentarios'],
          'total': nuevaInfo['total'], // Agregamos el campo 'total' al detalle
        },
      };

      await resultadoRef.set({
        'nombre_participante': nombreParticipante,
        'nombre_juez': nombreJuez,
        'total': nuevoTotal,
        'detalle': nuevoDetalle,
      });
    }
  }

  void _enviarPuntuacion() async {
    if (participanteSeleccionado != null && selectedJudgeName != null) {
      try {
        final firestore = FirebaseFirestore.instance;

        // Obtener el nombre del juez seleccionado
        DocumentSnapshot snapshotJuez = await firestore
            .collection("jueces")
            .doc(widget.selectedJudgeId)
            .get();
        String nombreJuez = snapshotJuez.get('nombre_juez') ?? '';

        // Obtener el nombre del participante seleccionado
        DocumentSnapshot snapshotParticipante = await firestore
            .collection("participants")
            .doc(participanteSeleccionado)
            .get();
        String nombreParticipante = snapshotParticipante.get('name') ?? '';

        QuerySnapshot existingEntry = await firestore
            .collection('1vs1Breaking_puntajes')
            .where("name", isEqualTo: nombreParticipante)
            .where("nombre_juez", isEqualTo: nombreJuez)
            .get();

        if (existingEntry.docs.isEmpty) {
          await firestore.collection('1vs1Breaking_puntajes').add({
            "name": nombreParticipante,
            "puntajes": puntajes,
            "nombre_juez": nombreJuez,
            "comentarios": _commentsController.text,
            "timestamp": Timestamp.now(),
          });
        } else {
          await firestore
              .collection('1vs1Breaking_puntajes')
              .doc(existingEntry.docs.first.id)
              .update({
            "puntajes": puntajes,
            "comentarios": _commentsController.text,
            "timestamp": Timestamp.now(),
          });
        }

        double nuevoTotalDouble =
            puntajes.values.reduce((sum, element) => sum + element);
        int nuevoTotal = nuevoTotalDouble.toInt();
        await actualizarResultados(
            participanteSeleccionado!,
            {
              'total': nuevoTotal,
              'detalle': {
                'puntajes': puntajes,
                'comentarios': _commentsController.text,
              },
            },
            nombreParticipante,
            nombreJuez);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Puntuación enviada!'),
              content: Text('La puntuación ha sido enviada con éxito.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        print("Error al enviar la puntuación: $e");
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error al enviar la puntuación'),
            content: Text(
                'Por favor, selecciona un participante y un juez antes de enviar la puntuación.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget buildScoreListItem({
    required String title,
    required double value,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 18),
              ),
              Spacer(),
              Text(
                value.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 18),
              ),
            ],
          ),
        ),
        Slider(
          min: 0,
          max: 10,
          divisions: 10,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<String>(
          future: obtenerNombreJuez(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Cargando...');
            } else if (snapshot.hasError) {
              return Text('Error');
            } else {
              return Text('1vs1 Breaking: ${snapshot.data}');
            }
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evaluación de Participantes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("participants")
                    .where("categories",
                        arrayContains:
                            widget.categoryName) // Filtrar por categoría
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  } else {
                    return FutureBuilder<List<DropdownMenuItem<String>>>(
                      future: Future.wait(snapshot.data!.docs
                          .map((DocumentSnapshot document) async {
                        Map<String, dynamic> data =
                            document.data() as Map<String, dynamic>;
                        var _score = 0;

                        // Obten el resulado del participante
                        var _participantResult = await FirebaseFirestore
                            .instance
                            .collection('1vs1Breaking_resultados')
                            .doc(document.id)
                            .get();

                        if (_participantResult.exists) {
                          var _judgeDetails = _participantResult['detalle']
                              [widget.selectedJudgeName];
                          if (_judgeDetails != null) {
                            _score = _judgeDetails['total'];
                          }
                        }

                        final item = DropdownMenuItem<String>(
                          value: document.id,
                          child: Container(
                            decoration: BoxDecoration(
                              border: _score > 0
                                  ? Border.all(color: Colors.green)
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(data['name']),
                                Text(
                                  'PTS: ' + _score.toString(),
                                  style: TextStyle(
                                    color:
                                        _score > 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        return item;
                      }).toList()),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<DropdownMenuItem<String>>>
                              snapshotItems) {
                        if (!snapshotItems.hasData) {
                          return CircularProgressIndicator();
                        } else {
                          return DropdownButtonFormField(
                            decoration: InputDecoration(
                              labelText: 'Participante',
                            ),
                            items: snapshotItems.data,
                            onChanged: (value) {
                              setState(() {
                                participanteSeleccionado = value as String?;
                              });
                            },
                            value: participanteSeleccionado,
                          );
                        }
                      },
                    );
                  }
                },
              ),
              SizedBox(height: 10),
              for (int index = 0; index < criterios.length; index++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: buildScoreListItem(
                    title: criterios[index],
                    value: puntajes[criterios[index]] ?? 0,
                    onChanged: (newValue) {
                      setState(() {
                        puntajes[criterios[index]] = newValue;
                      });
                      totalNotifier.value = calcularPuntuacionTotal();
                    },
                  ),
                ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  // Cambiamos el color del cuadro en función del tema actual
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFFffd808)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: totalNotifier,
                  builder: (context, value, child) {
                    return Text(
                      'Puntuación total: $value',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Theme.of(context).textTheme.bodyText1!.color,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _commentsController,
                decoration: InputDecoration(
                  labelText: 'Comentarios (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _enviarPuntuacion,
                child: Text('Enviar Puntuación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
