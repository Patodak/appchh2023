import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrarse')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 50),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(hintText: 'Correo'),
                        validator: (String? value) {
                          // Validación del correo electrónico
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Por favor ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Nombre de usuario',
                        ),
                        validator: (String? value) {
                          // Validación del nombre de usuario
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre de usuario';
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
                          // Validación de contraseña
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  child: Text('Registrarse'),
                  onPressed: _signup,
                ),
                ElevatedButton(
                  child: Text('Registrarse con Google'),
                  onPressed: _signupWithGoogle,
                ),
                TextButton(
                  child: Text('Iniciar sesión'),
                  onPressed: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signup() async {
    final form = _formKey.currentState;

    if (form != null && form.validate()) {
      try {
        UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

        // Guardar datos del usuario en la colección "users"
        await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': userCredential.user!.email,
            'role': 'espectador',
            'uid': userCredential.user!.uid,
            'nombre usuario': _usernameController.text,
            // Aquí puedes añadir más campos personalizados para el usuario
          });

        print('Registro exitoso');
        Navigator.pushNamed(context, '/main_menu');
      } on FirebaseAuthException catch (e) {
        print('Error de FirebaseAuth: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message ?? 'Ocurrió un error al registrarse.'}'),
          ),
        );
      } catch (e) {
        print('Error desconocido: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error desconocido al registrarse.'),
          ),
        );
      }
    } else {
      print('Error de validación del formulario');
    }
  }

  Future<void> _signupWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final String? email = googleUser.email;
      final List<String?> existingUser = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email!);

      if (existingUser.isNotEmpty) {
        // El usuario ya tiene una cuenta existente con este correo electrónico.
        // Muestra un mensaje al usuario o maneja la situación según tus necesidades,
        // ya que no podrán iniciar sesión con Google utilizando este correo electrónico.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Este correo electrónico ya está registrado.'),          ),
        );
        return;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Generar el nombre de usuario a partir del correo electrónico
      final username = email.split('@').first;

      // Guardar datos del usuario en la colección "users"
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'role': 'espectador',
            'uid': userCredential.user!.uid,
            'nombre usuario': username,
          });

      print('Registro con Google exitoso');
      Navigator.pushNamed(context, '/main_menu');
    } catch (e) {
      print('Error al registrarse con Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrarse con Google'),
        ),
      );
    }
  }

  void _login() {
    Navigator.pushNamed(context, '/login');
  }
}