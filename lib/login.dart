import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // Variable para almacenar el documento del usuario actualmente autenticado
  DocumentSnapshot? _currentUser;
  // Variable para determinar si el usuario es nuevo
  bool _isNewUser = false;

  @override
  void initState() {
    super.initState();
  }

  Stream<DocumentSnapshot> _getCurrentUserStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    }

    return const Stream.empty(); // Esto es sólo para satisfacer el valor de retorno de la función.
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _currentUser = querySnapshot.docs.first;
        });
      } else {
        // El usuario no existe en la colección de usuarios
        setState(() {
          _isNewUser = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar sesión')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 50),
                // Mostrar saludo "Hola nuevo usuario" si el usuario es nuevo
                StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data == null) {
      // Si no hay datos del usuario, significa que es un nuevo usuario o no está registrada la sesión.
      return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Text('Hola nuevo usuario'),
      );
    } else {
      // Si se tiene información del usuario, obtener los datos del Firestore
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Si no hay datos en Firestore para el usuario, el usuario es nuevo
            return Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text('Hola nuevo usuario'),
            );
          }
          // Si hay datos de Firestore, mostrar su nombre de usuario
          final username = snapshot.data!['nombre usuario'];          
          return Text('Hola $username');
        });
    }
  },
),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico o nombre de usuario',
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa un correo o nombre de usuario';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  child: Text('Iniciar sesión con Email'),
                  onPressed: _login,
                ),
                ElevatedButton(
                  child: Text('Inicia sesión con Google'),
                  onPressed: _loginWithGoogle,
                ),
                ElevatedButton(
                  child: Text('Cerrar mi sesión de Google'),
                  onPressed: _logoutAndGoToLogin,
                ),

                TextButton(
                  child: Text('Registrarse'),
                  onPressed: _signup,
                ),
                TextButton(
                  child: Text('Restablecer contraseña'),
                  onPressed: () async {
                    String email = _emailController.text.trim();

                    if (email.isEmpty ||
                        !email.contains('@') ||
                        !email.contains('.')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Por favor, ingresa un correo válido'),
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Se ha enviado un correo electrónico para restablecer la contraseña'),
                        ),
                      );
                    } catch (e) {
                      print(
                          'Error al enviar el correo electrónico de restablecimiento de contraseña: $e');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Ocurrió un error al enviar el correo electrónico de restablecimiento de contraseña'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final form = _formKey.currentState;

    if (form != null && form.validate()) {
      try {
        String email = _emailController.text.trim();
        String? username = _usernameController.text.trim();
        String password = _passwordController.text;

        if (username.isEmpty && (email.isEmpty || !email.contains('@'))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ingresa un correo o nombre de usuario válido'),
            ),
          );
          return;
        }

        // Si se ingresó un nombre de usuario, buscar por nombre de usuario
        if (username.isNotEmpty) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('nombre usuario', isEqualTo: username)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final emailFromDatabase =
                querySnapshot.docs.first['email'] as String;
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailFromDatabase,
              password: password,
            );
            print('Inicio de sesión exitoso');
            Navigator.pushNamed(context, '/main_menu');
            return;
          }
        }

        // Si se ingresó un correo electrónico, buscar por correo electrónico
        if (email.isNotEmpty) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          print('Inicio de sesión exitoso');
          Navigator.pushNamed(context, '/main_menu');
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontró el usuario')),
        );
      } on FirebaseAuthException catch (e) {
        print('Error de FirebaseAuth: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.message ?? 'Ocurrió un error al iniciar sesión.'}'),
          ),
        );
      } catch (e) {
        print('Error desconocido: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error desconocido al iniciar sesión.'),
          ),
        );
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Antes de actualizar el documento en Firestore, revisamos si ya existe el usuario
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: userCredential.user!.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Si no existe, actualizamos el documento en Firestore con el nuevo usuario
        FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'nombre usuario': googleUser.displayName,
          'email': googleUser.email,
          'uid': userCredential.user!.uid,
          'role': 'espectador',
        });
      }

      print('Inicio de sesión con Google exitoso');
      Navigator.pushNamed(context, '/main_menu');
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión con Google'),
        ),
      );
    }
}

  void _logoutAndGoToLogin() async {
    // Cierra la sesión de Firebase
    await FirebaseAuth.instance.signOut();

    // Cierra la sesión de Google
    await _googleSignIn.signOut();

    // Redirige a la pantalla de login.
    // Esto debería forzar al usuario a reautenticarse la próxima vez que intenten loguearse con Google.
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _signup() {
    Navigator.pushNamed(context, '/register');
  }
}
