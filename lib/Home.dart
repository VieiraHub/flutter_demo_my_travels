import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_travels/Mapa.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore _db = Firestore.instance;

  _openMap(String idTravel) {
    Navigator.push(
        context, MaterialPageRoute(
            builder: (_) => Mapa(  idTravel: idTravel  )
      )
    );
  }

  _deleteTravel(String idTravel) {
    _db.collection("travels").document(idTravel).delete();
  }

  _addLocal() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Mapa()));
  }

  _addListenerTravels() async {
    final stream = _db.collection("travels").snapshots();
    stream.listen((data) {
      _controller.add(data);
    });
  }

  @override
  void initState() {
    super.initState();
    _addListenerTravels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Travels")),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          backgroundColor: Color(0xff0066cc),
          onPressed: () {
            _addLocal();
          }),
      body: StreamBuilder<QuerySnapshot>(
          stream: _controller.stream,
          // ignore: missing_return
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
              case ConnectionState.active:
              case ConnectionState.done:
                QuerySnapshot querySnapshot = snapshot.data;
                List<DocumentSnapshot> travels =
                    querySnapshot.documents.toList();

                return Column(
                  children: [
                    Expanded(
                        child: ListView.builder(
                            itemCount: travels.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot item = travels[index];
                              String title = item["title"];
                              String idTravel = item.documentID;

                              return GestureDetector(
                                onTap: () {
                                  _openMap(idTravel);
                                },
                                child: Card(
                                  child: ListTile(
                                    title: Text(title),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            _deleteTravel(idTravel);
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }))
                  ],
                );
                break;
            }
          }),
    );
  }
}
