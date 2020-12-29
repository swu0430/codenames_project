import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'apikey.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<MyApp> {

  static final String DEVELOPER_KEY = ApiDevKey.DEV_KEY;
  List data;

  @override
  void initState() {
    super.initState();
    fetchimages();
  }

  Future<String> fetchimages() async {
    var fetchdata = await http.get('https://api.unsplash.com/photos/random?client_id=${DEVELOPER_KEY}&count=25');

    setState(() {
      data = json.decode(fetchdata.body);
    });
    return 'Success';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:"Codenames - Play Online",
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("CODENAMES: [INSERT VERSION]", 
            style: GoogleFonts.shojumaru(
              fontSize: 24.0,
            ), //GoogleFonts
          ),
        ),
        body: Center(
          child: Container(
            width: 800, 
            height: 800,
            padding: const EdgeInsets.all(10.0),
            child: GridView.builder(
              itemCount: data.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, 
                crossAxisSpacing: 10.0, 
                mainAxisSpacing: 10.0,
              ),
              itemBuilder: (BuildContext context, int index){
                return Image.network(data[index]['urls']['small'], 
                  fit: BoxFit.fill,
                  color: Colors.red,
                  colorBlendMode: BlendMode.darken
                );
              }
            )
          ),
        )
      ),
    );
  }
}

