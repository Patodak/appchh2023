import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String _selectedJudgeId = '';
  String get selectedJudgeId => _selectedJudgeId;

  String _selectedJudgeName = '';
  String get selectedJudgeName => _selectedJudgeName;

  String _selectedJudgeCategory = '';
String get selectedJudgeCategory => _selectedJudgeCategory;

  void selectJudge(String id, String name, String category) {
  _selectedJudgeId = id;
  _selectedJudgeName = name;
  _selectedJudgeCategory = category;
  print('Seleccionaste al juez: $id, $name, $category');
  notifyListeners();
}

  void clearSelectedJudge() {
    _selectedJudgeId = '';
    _selectedJudgeName = '';
    notifyListeners();
  }
}