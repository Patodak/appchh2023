import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getOriginalRole() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? originalRole = prefs.getString('originalRole');
  return originalRole;
}