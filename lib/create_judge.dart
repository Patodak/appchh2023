import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateJudgePage extends StatefulWidget {
  @override
  _CreateJudgePageState createState() => _CreateJudgePageState();
}

class _CreateJudgePageState extends State<CreateJudgePage> {
  final TextEditingController _judgeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<bool> isCategorySelected = [false, false];
  List<String> categoryOptions = ['Breaking', 'All Style'];
  final String defaultImageUrl = 'https://i.imgur.com/dZnDMZX.png';

  Stream<QuerySnapshot> get _judgesStream {
    return _firestore.collection('jueces').snapshots();
  }

  void initState() {
    super.initState();
  }

  Future<void> addJudge(String docId, String name, String email,
    String photoUrl, List<String> categories) async {
  print('Agregando juez: $name, $email, $photoUrl, $categories');

  List<String> selectedCategories = [];
  for (int i = 0; i < isCategorySelected.length; i++) {
    if (isCategorySelected[i]) {
      selectedCategories.add(categoryOptions[i]);
    }
  }

  // Asignar la URL predeterminada si el campo de foto está vacío
  String selectedPhotoUrl = photoUrl.isNotEmpty ? photoUrl : defaultImageUrl;

  CollectionReference juecesRef = _firestore.collection('jueces');
  DocumentReference newJudgeRef = await juecesRef.add({
    'nombre_juez': name.toUpperCase(),
    'email': email.toLowerCase(),
    'foto_url': selectedPhotoUrl,
    'categoria': categories,
    'role': 'jurado', // Asignar el rol "jurado" al juez
  });

  if (newJudgeRef != null) {
    print('Juez agregado exitosamente');
    String newJudgeId = newJudgeRef.id;
  } else {
    print('Error al agregar el juez');
  }
}

  Future<void> editJudge(String docId, String newName, String newEmail,
      String newPhotoUrl, List<String> categories) async {
    await _firestore.collection('jueces').doc(docId).update({
      'nombre_juez': newName.toUpperCase(),
      'email': newEmail.toLowerCase(),
      'foto_url': newPhotoUrl.isEmpty
          ? 'http://url.to_default_picture.png'
          : newPhotoUrl,
      'categoria': categories,
    });
  }

  Future<void> removeJudge(String docId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Eliminar jurado'),
        content: Text('¿Estás seguro de eliminar este jurado?'),
        actions: [
          TextButton(
            onPressed: () async {
              await _firestore.collection('jueces').doc(docId).delete();
              Navigator.pop(context);
            },
            child: Text('Eliminar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar jueces'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showEditDialog(
              context,
              _judgeController,
              _emailController,
              _photoUrlController,
              _categoryController,
              'Crear nuevo juez',
              addJudge,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _judgesStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          List<DocumentSnapshot> documents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (BuildContext context, int index) {
              final doc = documents[index];
              Map<String, dynamic> judgeData =
                  doc.data() as Map<String, dynamic>;
              String photoUrl = judgeData['foto_url'] ?? defaultImageUrl;
              String nombreJuez =
                  doc.get('nombre_juez') ?? 'Sin nombre de juez';
              List<String> categories = judgeData['categoria'] != null
                  ? List<String>.from(judgeData['categoria'])
                  : [];

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.network(
                        photoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.network(
                          defaultImageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(nombreJuez),
                      subtitle: Text(categories.join(', ')),
                      onTap: () => _showEditDialog(
                        context,
                        _judgeController,
                        _emailController,
                        _photoUrlController,
                        _categoryController,
                        'Editar juez',
                        editJudge,
                        doc.id,
                        judgeData['nombre_juez'] ?? '',
                        judgeData['email'] ?? '',
                        judgeData['foto_url'] ?? '',
                        categories,
                      ),
                    ),
                    ButtonBar(
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            removeJudge(doc.id);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    TextEditingController judgeController,
    TextEditingController emailController,
    TextEditingController photoUrlController,
    TextEditingController categoryController,
    String title,
    Function(
            String docId,
            String newName,
            String newEmail,
            String newPhotoUrl,
            List<String> newCategories)
        onConfirm, [
    String docId = '',
    String originalName = '',
    String originalEmail = '',
    String originalPhotoUrl = '',
    List<String> originalCategories = const [],
  ]) {
    judgeController.text = originalName;
    emailController.text = originalEmail;
    photoUrlController.text = originalPhotoUrl;
    categoryController.text = originalCategories.join(', ');

    List<bool> tempSelectedCategories =
        List.generate(categoryOptions.length, (_) => false);
    for (String category in originalCategories) {
      int index = categoryOptions.indexOf(category);
      if (index != -1) {
        tempSelectedCategories[index] = true;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: judgeController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del juez',
                        hintText: 'Ingrese el nombre',
                      ),
                    ),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'example@example.com',
                      ),
                    ),
                    TextField(
                      controller: photoUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL de la foto',
                        hintText: 'Ingrese la URL de la foto',
                      ),
                    ),
                    for (int i = 0; i < categoryOptions.length; i++)
                      CheckboxListTile(
                        title: Text(categoryOptions[i]),
                        value: tempSelectedCategories[i],
                        onChanged: (newValue) {
                          setState(() {
                            tempSelectedCategories[i] = newValue ?? false;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    List<String> selectedCategories = [];
                    for (int i = 0; i < tempSelectedCategories.length; i++) {
                      if (tempSelectedCategories[i]) {
                        selectedCategories.add(categoryOptions[i]);
                      }
                    }
                    onConfirm(
                      docId,
                      judgeController.text,
                      emailController.text,
                      photoUrlController.text,
                      selectedCategories,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}