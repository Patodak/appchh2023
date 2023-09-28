import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class ManageRoles extends StatefulWidget {
  const ManageRoles({Key? key}) : super(key: key);

  @override
  _ManageRolesState createState() => _ManageRolesState();
}

class _ManageRolesState extends State<ManageRoles> {
  int _itemsPerPage = 10;
  int _currentPage = 0;
  String? userRole = "";
  final TextEditingController _searchController = TextEditingController();

  Stream<QuerySnapshot<Object?>> _getUsers(String searchString) {
  CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
  Query usersQuery = usersRef.orderBy('email');
  if (searchString.isNotEmpty) {
    usersQuery = usersQuery.where(FieldPath.documentId, isEqualTo: searchString);
  }
  return usersQuery.snapshots();
}

  Future<void> getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    var uid = user?.uid;
    DocumentSnapshot<Object?> doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userRole = doc.get('role');
    });
  }

  @override
  void initState() {
    super.initState();
    getUserRole();
  }

  List<DropdownMenuItem<String>> _roleItems(String currentRole) {
    Set<String> roles = {currentRole};
  
    roles.add('espectador');
    roles.add('jurado');

    if (userRole == 'creador') {
      roles.add('administrador');
    }

    return roles.map((role) => DropdownMenuItem(value: role, child: Text(role.capitalize()))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Roles - $userRole'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Busca usuarios',
              ),
              onChanged: (value) {
                  setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Object?>>(
  stream: _getUsers(_searchController.text),
  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    QueryDocumentSnapshot<Object?> doc = snapshot.data!.docs[index];
                    Map<String, dynamic> user = doc.data() as Map<String, dynamic>;
                    
                    if (user['role'] == 'creador') {
  return SizedBox.shrink();
}

return ListTile(
  title: Text(user['nombre usuario'] ?? 'Nombre no definido'),
  subtitle: Text(user['email']),
  trailing: DropdownButton<String>(
    value: user['role'],
    onChanged: (userRole == 'administrador' || userRole == 'creador')
      ? (String? newRole) async {
                              if (newRole != null) {
                                bool shouldChange = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Confirmación'),
                                      content: Text('¿Estás seguro de que quieres cambiar este rol?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Cancelar'),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Continuar'),
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (shouldChange) {
                                  FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user['uid'])
                                    .update({'role': newRole});
                                }
                              }
                            }
                          : null,
                        items: _roleItems(user['role']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}