import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'PagesEvaluation/SelectCategory.dart';

class SelectJudgePage extends StatefulWidget {
  @override
  _SelectJudgePageState createState() => _SelectJudgePageState();
}

class _SelectJudgePageState extends State<SelectJudgePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirmación de Jurado')),
      body: GestureDetector(
        onTap: () {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.selectJudge('', '', ''); // Deseleccionar el jurado
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('jueces').snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text('Error al cargar los jurados'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final List<DocumentSnapshot> judges = snapshot.data!.docs;

            final List<DocumentSnapshot> allStyleJudges = judges
                .where((judge) =>
                    (judge['categoria'] as List).contains('All Style'))
                .toList();

            final List<DocumentSnapshot> breakingJudges = judges
                .where((judge) =>
                    (judge['categoria'] as List).contains('Breaking'))
                .toList();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'All Style',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    itemCount: allStyleJudges.length,
                    itemBuilder: (BuildContext context, int index) {
                      final judge = allStyleJudges[index];
                      final appState = Provider.of<AppState>(context);
                      final isSelected = appState.selectedJudgeId == judge.id;

                      return InkWell(
                        onTap: () {
                          appState.selectJudge(judge.id, judge['nombre_juez'], 'All Style');
                        },
                        child: Container(
                          color: isSelected ? Colors.amber : null,
                          child: ListTile(
                            leading: judge['foto_url'] != null
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(judge['foto_url']),
                                  )
                                : null,
                            title: Text(
                              judge['nombre_juez'],
                              style: TextStyle(
                                  color: isSelected ? Colors.black : null),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Breaking',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    itemCount: breakingJudges.length,
                    itemBuilder: (BuildContext context, int index) {
                      final judge = breakingJudges[index];
                      final appState = Provider.of<AppState>(context);
                      final isSelected = appState.selectedJudgeId == judge.id;

                      return InkWell(
                        onTap: () {
                          appState.selectJudge(judge.id, judge['nombre_juez'], 'Breaking');
                        },
                        child: Container(
                          color: isSelected ? Colors.amber : null,
                          child: ListTile(
                            leading: judge['foto_url'] != null
                                ? CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(judge['foto_url']),
                                  )
                                : null,
                            title: Text(
                              judge['nombre_juez'],
                              style: TextStyle(
                                  color: isSelected ? Colors.black : null),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Consumer<AppState>(
        builder: (BuildContext context, AppState appState, _) {
          final bool hasSelectedJudge = appState.selectedJudgeId.isNotEmpty;

          return FloatingActionButton(
            child: Icon(Icons.arrow_forward),
            onPressed: () {
              if (hasSelectedJudge) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectCategoryPage(),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Aviso'),
                      content: Text('Por favor, seleccione su jurado'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}