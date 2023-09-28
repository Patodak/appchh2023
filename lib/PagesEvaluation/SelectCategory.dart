import 'package:flutter/material.dart';
import '1vs1BreakingEvalPage.dart';
import '3vs3BreakingEvalPage.dart';
import '1vs1AllStyleEvalPage.dart';
import '7toSmokeHipHopEvalPage.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class SelectCategoryPage extends StatelessWidget {
  final String? selectedJudgeName;

  SelectCategoryPage({this.selectedJudgeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccion de Categoria'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Consumer<AppState>(
              builder: (BuildContext context, AppState appState, _) {
                final String selectedJudgeCategory = appState.selectedJudgeCategory;

                List<String> categories = [];

                if (selectedJudgeCategory == 'Breaking') {
                  categories = ['1vs1 Breaking', '3vs3 Breaking'];
                } else if (selectedJudgeCategory == 'All Style') {
                  categories = ['1vs1 All Style', '7 to Smoke Hip Hop'];
                }

                return Column(
                  children: categories.map((category) {
                    return ElevatedButton(
                      child: Text(category),
                      onPressed: () {
                        String selectedJudgeId = appState.selectedJudgeId;
                        String selectedJudgeName = appState.selectedJudgeName;

                        if (category == '1vs1 Breaking') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OneToOneBreakingEvalPage(
                                selectedJudgeId: selectedJudgeId,
                                selectedJudgeName: selectedJudgeName,
                                categoryName: category,
                              ),
                            ),
                          );
                        } else if (category == '3vs3 Breaking') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ThreeToThreeBreakingEvalPage(
                                selectedJudgeId: selectedJudgeId,
                                selectedJudgeName: selectedJudgeName,
                                categoryName: category,
                              ),
                            ),
                          );
                        } else if (category == '1vs1 All Style') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OneToOneAllStyleEvalPage(
                                selectedJudgeId: selectedJudgeId,
                                selectedJudgeName: selectedJudgeName,
                                categoryName: category,
                              ),
                            ),
                          );
                        } else if (category == '7 to Smoke Hip Hop') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SevenToSmokeHipHopEvalPage(
                                selectedJudgeId: selectedJudgeId,
                                selectedJudgeName: selectedJudgeName,
                                categoryName: category,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 32),
            Container(
              alignment: Alignment.bottomRight,
              padding: EdgeInsets.only(right: 16, bottom: 16),
              child: Consumer<AppState>(
                builder: (BuildContext context, AppState appState, _) {
                  return Text(
                    'Juez seleccionado: ${appState.selectedJudgeName}',
                    style: TextStyle(fontSize: 16),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}