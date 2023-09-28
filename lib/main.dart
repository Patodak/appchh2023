import 'package:boxapp/create_judge.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'SelectJudge.dart';
import 'Puntajes.dart';
import 'Admin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'complete_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'roles_and_permissions.dart'; // Importar roles_and_permissions.dart
import 'shared_prefs.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (context) => ThemeNotifier(),
        ),
        ChangeNotifierProvider<UserRepository>(
          create: (context) => UserRepository(),
        ),
        ChangeNotifierProvider<AppState>(
          create: (context) => AppState(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class AppUser {
  final String uid;
  final String email;
  final String role;

  AppUser({required this.uid, required this.email, required this.role});
}

class UserRepository extends ChangeNotifier {
  AppUser? _user;

  AppUser? get currentUser => _user;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateUser(String? uid, String? email) async {
    if (uid != null && email != null) {
      DocumentSnapshot userDocument =
          await firestore.collection('users').doc(uid).get();
      _user = AppUser(
        uid: uid,
        email: email,
        role: (userDocument.data() as Map<String, dynamic>?)?['role'] ??
            'espectador',
      );
    } else {
      _user = null;
    }

    notifyListeners();
  }
}

String participanteSeleccionado = "";

final Color myColor = Color(0xFFffd808);

ThemeData get _darkTheme => ThemeData.dark().copyWith(
      primaryColor: myColor,
      sliderTheme: ThemeData.dark().sliderTheme.copyWith(
            activeTrackColor: myColor,
            thumbColor: myColor,
            overlayColor: myColor.withOpacity(0.2),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: myColor,
          onPrimary: Colors.black,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: myColor,
        titleTextStyle: ThemeData.dark()
            .textTheme
            .headline6!
            .copyWith(color: Colors.black, fontSize: 15),
      ),
    );

ThemeData get _pinkTheme => ThemeData.light().copyWith(
      primaryColor: Color.fromARGB(255, 252, 156, 198),
      scaffoldBackgroundColor: Colors.pink.shade100,
      sliderTheme: ThemeData.light().sliderTheme.copyWith(
            activeTrackColor: Color.fromARGB(255, 252, 156, 198),
            thumbColor: Color.fromARGB(255, 252, 156, 198),
            overlayColor: Color.fromARGB(255, 252, 156, 198).withOpacity(0.2),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: const Color.fromARGB(255, 224, 36, 118),
          onPrimary: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color.fromARGB(255, 252, 156, 198),
        titleTextStyle: ThemeData.light()
            .textTheme
            .headline6!
            .copyWith(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 15),
      ),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: Color.fromARGB(255, 0, 0, 0),
            displayColor: Colors.white,
          ),
    );

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (context) => LoginPage());
    case '/login':
      return MaterialPageRoute(builder: (context) => LoginPage());
    case '/register':
      return MaterialPageRoute(builder: (context) => RegisterPage());
    case '/main_menu':
      return MaterialPageRoute(builder: (context) => MainMenuPage());
    default:
      return MaterialPageRoute(builder: (context) => LoginPage());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Clinica Hip Hop',
      theme: ThemeData(
        primaryColor: myColor,
        sliderTheme: SliderThemeData(
          activeTrackColor: myColor,
          thumbColor: myColor,
          overlayColor: myColor.withOpacity(0.2),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: myColor,
            onPrimary: Colors.black,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: myColor,
          titleTextStyle: ThemeData.light()
              .textTheme
              .headline6!
              .copyWith(color: Colors.black, fontSize: 15),
        ),
      ),
      darkTheme: _darkTheme,
      themeMode: themeNotifier.themeMode,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
      builder: (context, child) {
        return themeNotifier.customThemeMode == CustomThemeMode.pink
            ? Theme(data: _pinkTheme, child: child!)
            : child!;
      },
    );
  }
}

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      UserRepository userRepository =
          Provider.of<UserRepository>(context, listen: false);
      userRepository.updateUser(userRepository.auth.currentUser?.uid,
          userRepository.auth.currentUser?.email);
    });
  }

  // Agregar función para verificar si el usuario tiene acceso.
  bool _hasAccess(AppUser user, String pageName) {
    String userRole = user.role;
    Set<String>? rolePermissions = rolesAndPermissions[userRole];
    return rolePermissions != null && rolePermissions.contains(pageName);
  }

  Future<String?> retrieveOriginalRole() async {
    return await getOriginalRole();
  }

  @override
  Widget build(BuildContext context) {
    UserRepository userRepository = Provider.of<UserRepository>(context);
    AppUser? user = userRepository.currentUser;

    return user != null
        ? Scaffold(
            appBar: AppBar(
              title: Text(
                'BOX 8',
                style: TextStyle(fontSize: 20),
              ),
              actions: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      userRepository.currentUser?.role ?? '',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.brightness_4),
                      onPressed: () {
                        final themeNotifier =
                            Provider.of<ThemeNotifier>(context, listen: false);
                        themeNotifier.toggleTheme();
                      },
                    ),
                  ],
                ),
              ],
            ),
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/logo.png',
                        width: 200,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Clínica HipHop',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      SizedBox(height: 30),

                      if (_hasAccess(user, 'SelectJudge'))
                        _buildMenuButton(
                          context,
                          title: 'Evaluacion de Participantes',
                          onPressed: () {
                            _navigateToPage(context, SelectJudgePage());
                          },
                        ),

                      // Puntajes y CompleteProfile siempre están disponibles.
                      _buildMenuButton(
                        context,
                        title: 'Puntaje Filtros',
                        onPressed: () {
                          _navigateToPage(context, Puntajes());
                        },
                      ),
                      
                      if (_hasAccess(user, 'Admin'))
                        _buildMenuButton(
                          context,
                          title: 'Admin',
                          onPressed: () {
                            _navigateToPage(context, AdminPage());
                          },
                        ),
                      // CompleteProfile siempre está disponible.
                      _buildMenuButton(
                        context,
                        title: 'Completar perfil',
                        onPressed: () {
                          _navigateToPage(context, CompleteProfilePage());
                        },
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'By PatoDak',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.caption!.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : CircularProgressIndicator();
  }

  Widget _buildMenuButton(BuildContext context,
      {required String title, required VoidCallback onPressed}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        child: Text(title),
        onPressed: onPressed,
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget targetPage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => targetPage,
      ),
    );
  }
}
