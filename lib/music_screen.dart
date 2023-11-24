import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:universal_recommendation_system/util/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({Key? key}) : super(key: key);

  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  TextEditingController searchControllermusic = TextEditingController();
  List<String> musicHistory = [];
  List<String> musicSuggestions = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final HistoryData historyData = HistoryData();
  late Stream<List<String>> musicHistoryStream;
  String? searchError;
  @override
  void initState() {
    super.initState();
    musicHistoryStream = historyData.fetchmusicHistoryStream(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            width: 500,
            child: TypeAheadField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: searchControllermusic,
                decoration: InputDecoration(
                  labelText: searchError,
                  labelStyle: TextStyle(
                      color: Colors.red[500],
                      fontWeight: FontWeight.w300,
                      fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.search,
                      color: AppColors.bgColors,
                    ),
                    onPressed: () {
                      final searchTerm = searchControllermusic.text;
                      if (searchTerm.isEmpty) {
                        setState(() {
                          searchError = 'Field is empty';
                        });
                        Timer(const Duration(seconds: 1), () {
                          searchError = null;
                          setState(() {});
                        });
                      } else {
                        // Clear the error message if it was previously set
                        setState(() {
                          searchError = null;
                        });
                        print(searchTerm);
                        historyData.storemusicHistory(userId, searchTerm);
                        searchControllermusic.clear();
                      }
                    },
                  ),
                ),
              ),
              suggestionsCallback: (pattern) {
                return _getSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                setState(() {
                  searchControllermusic.text = suggestion;
                });
              },
            ),
          ),
          StreamBuilder<List<String>>(
            stream: musicHistoryStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                musicHistory = snapshot.data ?? [];
                return Container();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }

  List<String> _getSuggestions(String query) {
    final List<String> suggestions = [];

    for (int i = musicHistory.length - 1; i >= 0; i--) {
      final String music = musicHistory[i];
      if (music.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(music);
      }
    }

    return suggestions;
  }
}

class HistoryData {
  Stream<List<String>> fetchmusicHistoryStream(String userId) {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final musicHistoryCollection = userDocRef.collection('music');

      return musicHistoryCollection.doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['musicHistory'] is List) {
            final musicHistoryList =
                List<Map<String, dynamic>>.from(data['musicHistory']);
            final musics = musicHistoryList
                .map((musicData) => musicData['music'].toString())
                .toList();
            return musics;
          }
        }
        return [];
      });
    } catch (e) {
      print('Error fetching music history: $e');
      return Stream.value([]);
    }
  }

  Future<void> storemusicHistory(String userId, String music) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final musicHistoryCollection = userDocRef.collection('music');
      final musicHistoryDocument = musicHistoryCollection.doc(userId);

      // Get the current timestamp
      final Timestamp timestamp = Timestamp.now();

      // Create a map with the music and timestamp
      final Map<String, dynamic> musicData = {
        'music': music,
        'timestamp': timestamp,
      };

      // Add this map to the music history
      await musicHistoryDocument.set({
        'musicHistory': FieldValue.arrayUnion([musicData])
      }, SetOptions(merge: true));
      print('music history data added successfully');
    } catch (e) {
      print('Error storing music history: $e');
    }
  }
}
