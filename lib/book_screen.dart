import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:universal_recommendation_system/util/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({Key? key}) : super(key: key);

  @override
  _BookScreenState createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  TextEditingController searchControllerbook = TextEditingController();
  List<String> bookHistory = [];
  List<String> bookSuggestions = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final HistoryData historyData = HistoryData();
  late Stream<List<String>> bookHistoryStream;
  String? searchError;
  @override
  void initState() {
    super.initState();
    bookHistoryStream = historyData.fetchbookHistoryStream(userId);
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
                controller: searchControllerbook,
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
                      final searchTerm = searchControllerbook.text;
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
                        historyData.storebookHistory(userId, searchTerm);
                        searchControllerbook.clear();
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
                  searchControllerbook.text = suggestion;
                });
              },
            ),
          ),
          StreamBuilder<List<String>>(
            stream: bookHistoryStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                bookHistory = snapshot.data ?? [];
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

    for (int i = bookHistory.length - 1; i >= 0; i--) {
      final String book = bookHistory[i];
      if (book.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(book);
      }
    }

    return suggestions;
  }
}

// fetching and storing history function in this class
class HistoryData {
  Stream<List<String>> fetchbookHistoryStream(String userId) {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final bookHistoryCollection = userDocRef.collection('book');

      return bookHistoryCollection.doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['bookHistory'] is List) {
            final bookHistoryList =
                List<Map<String, dynamic>>.from(data['bookHistory']);
            final books = bookHistoryList
                .map((bookData) => bookData['book'].toString())
                .toList();
            return books;
          }
        }
        return [];
      });
    } catch (e) {
      print('Error fetching book history: $e');
      return Stream.value([]);
    }
  }

  Future<void> storebookHistory(String userId, String book) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final bookHistoryCollection = userDocRef.collection('book');
      final bookHistoryDocument = bookHistoryCollection.doc(userId);

      // Get the current timestamp
      final Timestamp timestamp = Timestamp.now();

      // Create a map with the book and timestamp
      final Map<String, dynamic> bookData = {
        'book': book,
        'timestamp': timestamp,
      };

      // Add this map to the book history
      await bookHistoryDocument.set({
        'bookHistory': FieldValue.arrayUnion([bookData])
      }, SetOptions(merge: true));
      print('book history data added successfully');
    } catch (e) {
      print('Error storing book history: $e');
    }
  }
}
