import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'apikey.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

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
  List colorListInteractive = new List<Color>(25);
  List colorList = new List<Color>();
  List blendModeListInteractive = new List<BlendMode>(25);
  List blendModeList = new List<BlendMode>();
  List borderColorListWhiteforPlayers = new List<Color>();
  Random random = new Random();
  int firstColor;
  bool spymaster = false;

  @override
  void initState() {
    super.initState();
    
    fetchimages();
    
    _colorList();

    for (int i = 0; i < 25; i++) {
      blendModeList.add(BlendMode.hardLight); 
      borderColorListWhiteforPlayers.add(Colors.white);
    }

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
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 16.0),
              Center(
                child: Container(
                  width: 800, 
                  height: 800,
                  padding: const EdgeInsets.all(10.0),
                  child: new GridView.count(
                    crossAxisCount: 5, 
                    crossAxisSpacing: 10.0, 
                    mainAxisSpacing: 10.0,
                    children: _buildGridTiles(25),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Center(
                child: Container(
                  width: 780, 
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      children: [
                        ButtonTheme(
                          minWidth: 125.0,
                          height: 35.0,
                          child: new RaisedButton(
                            shape: spymaster == false ? RoundedRectangleBorder(side: BorderSide(color: Colors.black)) : null,
                            onPressed: () {
                              setState(() {
                                spymaster = false;
                              });
                            },
                            color: Colors.grey[350],
                            child: const Text('Player',
                              style: TextStyle(fontSize: 20)
                            ),
                          )
                        ),
                        ButtonTheme(
                          minWidth: 125.0,
                          height: 35.0,
                          child: new RaisedButton(
                            shape: spymaster == true ? RoundedRectangleBorder(side: BorderSide(color: Colors.black)) : null,
                            onPressed: () {
                              setState(() {
                                spymaster = true;
                              });
                            },
                            color: Colors.grey[350],
                            child: const Text('Spymaster',
                              style: TextStyle(fontSize: 20)
                            ),
                          )
                        ),
                        SizedBox(width: 16.0),
                        ButtonTheme(
                          minWidth: 125.0,
                          height: 35.0,
                          child: new RaisedButton(
                            onPressed: () {
                              setState(() {
                                
                                //TODO

                              });
                            },
                            color: Colors.indigo[800],
                            textColor: Colors.white,
                            child: const Text('Next Game',
                              style: TextStyle(fontSize: 20)
                            ),
                          )
                        ),
                      ] // children
                    )
                  ) 
                )
              )
            ] // children
          )
        )
      )
    );
  }

  List<Widget> _buildGridTiles(int numberOfTiles) {
    List<Container> containers = new List<Container>.generate(numberOfTiles, (int index) {
        return new Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: spymaster == true ? colorList[index] : borderColorListWhiteforPlayers[index],
              width: spymaster == true ? 10.0 : 0.0,
            ),
          ),
          child: new InkWell(
            onTap: () {
              setState(() {
                colorListInteractive[index] = colorList[index];
                blendModeListInteractive[index] = blendModeList[index];
              });
            },
            child: Image.network(data[index]['urls']['small'],
              fit: BoxFit.fill,
              color: colorListInteractive[index],
              colorBlendMode: blendModeListInteractive[index],
          )
        )
      );
    });
    return containers;
  }

  void _colorList() {

    int numBlue, numRed, numNeutral, numDeath;
    int counterBlue = 0, counterRed = 0, counterNeutral = 0, counterDeath = 0;

    int randomPick;

    firstColor = random.nextInt(2);

    if (firstColor == 0) {
      numBlue = 9; numRed = 8; numNeutral = 7; numDeath = 1;
    } else if (firstColor == 1) {
      numBlue = 8; numRed = 9; numNeutral = 7; numDeath = 1;
    }

    while ((counterBlue < numBlue) || (counterRed < numRed) || (counterNeutral < counterNeutral) || (counterDeath < numDeath)) {

      randomPick = random.nextInt(4);

      print(randomPick);

      if (randomPick == 0) {
        if (counterBlue < numBlue) {
          colorList.add(Colors.blue);
          counterBlue++;
        }
      } else if (randomPick == 1) {
        if (counterRed < numRed) {
          colorList.add(Colors.red);
          counterRed++;
        }
      } else if (randomPick == 2) {
        if (counterNeutral < numNeutral) {
          colorList.add(Colors.brown[200]);
          counterNeutral++;
        }
      } else if (randomPick == 3) {
        if (counterDeath < numDeath) {
          colorList.add(Colors.grey[900]);
          counterDeath++;
        }
      }
    }

    colorList.shuffle();

  }
}