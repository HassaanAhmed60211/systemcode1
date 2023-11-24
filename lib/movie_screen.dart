import 'dart:async';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:universal_recommendation_system/scrollablebehavior.dart';
import 'package:universal_recommendation_system/util/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_recommendation_system/util/textstyle.dart';

class MovieScreen extends StatefulWidget {
  const MovieScreen({Key? key}) : super(key: key);

  @override
  _MovieScreenState createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  TextEditingController searchControllermovie = TextEditingController();
  List<String> movieHistory = [];
  List<String> movieSuggestions = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final HistoryData historyData = HistoryData();
  late Stream<List<String>> movieHistoryStream;
  String? searchError;

  @override
  void initState() {
    super.initState();
    movieHistoryStream = historyData.fetchMovieHistoryStream(userId);
    getTop250Movies();
  }

  final TextEditingController _titleController = TextEditingController();
  final ScrollController controller = ScrollController();

  List<dynamic> recommendations = [];
  List<dynamic> top250Movies = [];
  bool isLoading = false;

  // URL of your Flask server
  final String serverUrl = 'http://127.0.0.1:5000/recommendations';
  final String top250moviesUrl = 'http://127.0.0.1:5001/top250movies';
  
    Future<void> getTop250Movies() async {

    try {
      final response = await http.get(Uri.parse('$top250moviesUrl'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          top250Movies = jsonResponse;
        });
      } else {
        print(
            'Failed to load top 250 movies. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');

    }
  }


  Future<void> getRecommendations(String title) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$serverUrl?title=$title'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          recommendations = jsonResponse;
          isLoading = false;
        });
      } else {
        print(
            'Failed to load recommendations. Status code: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
        
            SizedBox(
              height: 240,
              child: ScrollConfiguration(
                behavior: MyCustomScrollBehavior(),
                child: ListView.builder(
        controller: controller,
                                scrollDirection: Axis.horizontal,
                                itemCount: top250Movies.length,
                                itemBuilder: (context, index) {
                                  final top250MoviesData = top250Movies[index];
                                  return Column(
                                    children: [
                                       SizedBox(
                                      width: 140,
                                      height: 210,
                                      child: Container(
                                          clipBehavior:
                                              Clip.antiAliasWithSaveLayer,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                image: DecorationImage(image: NetworkImage(top250MoviesData['imageUrl']),fit: BoxFit.fitHeight)
                                              ),
                                          child: Align(
                                            alignment: Alignment.topRight,
                                            child: Container(
                                              height: 29,
                                              width: 37,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.only
                                                (bottomLeft: Radius.circular(6))
                                              ),
                                              child: Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.star_rate,color: Colors.amberAccent,size: 13,),
                                                    Text(
                                          top250MoviesData['rating'],
                                          style: TextStyle(
                                              fontFamily:
                                                  GoogleFonts.poppins().fontFamily,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black),
                                        )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: SizedBox(
                                        width: 140,
                                        child: Text(
                                          top250MoviesData['title'],
                                          maxLines: 2,
                                          style: TextStyle(
                                              fontFamily:
                                                  GoogleFonts.poppins().fontFamily,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white),
                                        ),
                                      ),
                                    )
                                    ],
                                  );
                                },
                              ),
              ),
            ),
           const SizedBox( height:25),
            SizedBox(
              height: 50,
              width: 500,
              child: TypeAheadField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: searchControllermovie,
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
                      onPressed: () async {
                        final searchTerm = searchControllermovie.text;
        
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
                          getRecommendations(searchTerm);
                          historyData.storeMovieHistory(userId, searchTerm);
                          searchControllermovie.clear();
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
                    searchControllermovie.text = suggestion;
                  });
                },
              ),
            ),
            StreamBuilder<List<String>>(
              stream: movieHistoryStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  movieHistory = snapshot.data ?? [];
                  return Container();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Container();
                }
              },
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "RECOMMENDATIONS",
              style: AppTextStyle.logoTextStyle(),
            ),
            const SizedBox(
              height: 10,
            ),
            Center(
              child: SizedBox(
                height: 370,
                width: 1150,
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : recommendations.isEmpty
                        ? Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 75.0),
                            child: Text(
                                  'No Recommendations',
                                  style: TextStyle(
                                      fontFamily: GoogleFonts.poppins().fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                          ),
                        )
                          
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recommendations.length,
                            itemBuilder: (context, index) {
                              final recommendation = recommendations[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 15.0, top: 2.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 210,
                                      height: 320,
                                      child: Card(
                                          clipBehavior:
                                              Clip.antiAliasWithSaveLayer,
                                          child: Image.network(
                                            recommendation['poster_path'],
                                            fit: BoxFit.cover,
                                          )),
                                    ),
                                    SizedBox(
                                      width: 210,
                                      child: Text(
                                        recommendation['clean_title'],
                                        maxLines: 2,
                                        style: TextStyle(
                                            fontFamily:
                                                GoogleFonts.poppins().fontFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getSuggestions(String query) {
    final List<String> suggestions = [];

    for (int i = movieHistory.length - 1; i >= 0; i--) {
      final String movie = movieHistory[i];
      if (movie.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(movie);
      }
    }

    return suggestions;
  }
}

class HistoryData {
  Stream<List<String>> fetchMovieHistoryStream(String userId) {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final movieHistoryCollection = userDocRef.collection('movie');

      return movieHistoryCollection.doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['movieHistory'] is List) {
            final movieHistoryList =
                List<Map<String, dynamic>>.from(data['movieHistory']);
            final movies = movieHistoryList
                .map((movieData) => movieData['movie'].toString())
                .toList();
            return movies;
          }
        }
        return [];
      });
    } catch (e) {
      print('Error fetching movie history: $e');
      return Stream.value([]);
    }
  }

  Future<void> storeMovieHistory(String userId, String movie) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('history').doc(userId);
      final movieHistoryCollection = userDocRef.collection('movie');
      final movieHistoryDocument = movieHistoryCollection.doc(userId);

      // Get the current timestamp
      final Timestamp timestamp = Timestamp.now();

      // Create a map with the movie and timestamp
      final Map<String, dynamic> movieData = {
        'movie': movie,
        'timestamp': timestamp,
      };

      // Add this map to the movie history
      await movieHistoryDocument.set({
        'movieHistory': FieldValue.arrayUnion([movieData])
      }, SetOptions(merge: true));
      print('Movie history data added successfully');
    } catch (e) {
      print('Error storing movie history: $e');
    }
  }
}
