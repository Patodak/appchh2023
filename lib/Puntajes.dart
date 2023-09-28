import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Puntaje {
  final String id;
  final String nombre;
  final double total;
  final String ganador; // Nuevo campo agregado
  final bool top16; // Nuevo campo agregado

  Puntaje({
    required this.id,
    required this.nombre,
    required this.total,
    required this.ganador,
    required this.top16,
  });
}

class Puntajes extends StatefulWidget {
  @override
  _PuntajesState createState() => _PuntajesState();
}

class _PuntajesState extends State<Puntajes> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  late Stream<List<Puntaje>> _stream;

  final List<String> _nombresCategorias = [
    "1vs1 All Style",
    "1vs1 Breaking",
    "7 to Smoke Hip Hop",
    "3vs3 Breaking"
  ];

  Stream<List<Puntaje>> _actualizarPuntajes() {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String collectionName = '';

  switch (_currentPageIndex) {
    case 0:
      collectionName = '1vs1AllStyle_resultados';
      break;
    case 1:
      collectionName = '1vs1Breaking_resultados';
      break;
    case 2:
      collectionName = '7toSmokeHipHop_resultados';
      break;
    case 3:
      collectionName = '3vs3Breaking_resultados';
      break;
    default:
      collectionName = '';
  }

  return _firestore.collection(collectionName).snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      String nombre = '';
      if (_currentPageIndex == 3) { // 3vs3 Breaking
        nombre = doc.data().containsKey('name') ? doc['name'] : "No disponible";
      } else {
        nombre = doc.data().containsKey('nombre_participante') ? doc['nombre_participante'] : "No disponible";
      }
      double total = doc.data().containsKey('total') ? (doc['total'] as num).toDouble() : 0;
      String ganador = doc.data().containsKey('ganador') ? doc['ganador'] : ""; // Nuevo campo ganador

      return Puntaje(
        id: doc.id,
        nombre: nombre,
        total: total,
        ganador: ganador,
        top16: false,
      );
    }).toList();
  });
}

  IconData _obtenerIcono(int posicion) {
    switch (posicion) {
      case 0:
        return Icons.emoji_events;
      case 1:
        return Icons.star;
      case 2:
        return Icons.grade;
      default:
        return Icons.person;
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    _stream = _actualizarPuntajes();
  }

  @override
  void dispose() {
    _pageController.dispose(); // Liberar el PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Puntajes del Filtro")),
      body: PageView.builder(
        controller: _pageController,
        itemCount: 4, // Número de categorías
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
            _stream = _actualizarPuntajes();
          });
        },
        itemBuilder: (context, index) {
          return StreamBuilder<List<Puntaje>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData) {
                return Center(child: Text("No hay datos. Error: ${snapshot.error}"));
              } else {
                List<Puntaje> puntajesOrdenados = List.from(snapshot.data!);
                puntajesOrdenados.sort((a, b) => -a.total.compareTo(b.total));

                return Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        _nombresCategorias[index],
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    Expanded(
      child: ListView.builder(
        itemCount: puntajesOrdenados.length,
        itemBuilder: (context, index) {
          Puntaje puntaje = puntajesOrdenados[index];
          bool esTop3 = index < 3;
          bool esTop16 = index < 16;
          TextStyle estilo = esTop16 ? TextStyle(fontSize: 18, fontWeight: FontWeight.bold) : TextStyle(fontSize: 18);

          return Container(
            decoration: BoxDecoration(
              color: esTop16 ? Colors.yellow.withOpacity(0.8) : Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.black, width: 0.5)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    esTop3 ? Icon(_obtenerIcono(index), size: 18) : SizedBox(width: 18),
                    SizedBox(width: 8),
                    Text(
                      (_currentPageIndex == 3) ? puntaje.nombre : '${index + 1}. ${puntaje.nombre}',
                      style: estilo,
                    ),
                  ],
                ),
                Text(
                  '${puntaje.total.toStringAsFixed(1)}',
                  style: estilo,
                ),
              ],
            ),
          );
        },
      ),
    ),
  ],
);
              }
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        onTap: (index) {
          setState(() {
            _currentPageIndex = index;
            _stream = _actualizarPuntajes();
            _pageController.jumpToPage(index);
          });
        },
        items: _nombresCategorias.map((categoria) {
          return BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: categoria,
          );
        }).toList(),
      ),
    );
  }
}