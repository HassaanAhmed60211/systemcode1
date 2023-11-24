import 'dart:async';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_auth/email_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:universal_recommendation_system/book_screen.dart';
import 'package:universal_recommendation_system/fashion_screen.dart';
import 'package:universal_recommendation_system/home_screen.dart';
import 'package:universal_recommendation_system/models/user_model.dart';
import 'package:universal_recommendation_system/movie_screen.dart';
import 'package:universal_recommendation_system/music_screen.dart';
import 'package:universal_recommendation_system/provider/screen_provider.dart';
import 'package:universal_recommendation_system/provider/user_provider.dart';
import 'package:universal_recommendation_system/util/colors.dart';
import 'package:universal_recommendation_system/util/textstyle.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseFirestore.instance;
  // Index of the current screen

  final List<Widget> _screens = [
    const HomeScreen(), // Index 0
    const MovieScreen(), // Index 1
    const BookScreen(),
    const MusicScreen(),
    const FashionScreen(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchUsername();
  }

  Future<String> fetchUsername() async {
    final user = _auth.currentUser;
    if (user != null) {
      final documentSnapshot = await db.collection('user').doc(user.uid).get();
      if (documentSnapshot.exists) {
        final userData = documentSnapshot.data() as Map<String, dynamic>;
        final username = userData['username'] as String;
        print(username);
        return username;
      }
    }
    return '';
  }

  GlobalKey<RefreshIndicatorState> refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    var screenProvider = Provider.of<ScreenProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.bgColors,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 90,
        titleSpacing: 30,
        backgroundColor: AppColors.bgColors,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              "UNIVERSAL RECOMMENDATION SYSTEM",
              style: AppTextStyle.logoTextStyle(),
            ),
            const Spacer(),
            _buildNavigationMenu(),
            RefreshIndicator(
              key: refreshKey,
              onRefresh: () async {
                setState(() {
                  // Refresh your data here if needed
                });
              },
              child: FutureBuilder<String>(
                future: fetchUsername(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final username = snapshot.data;
                    return PopupMenuButton<String>(
                      iconColor: Colors.white,
                      onSelected: (value) {
                        if (value == 'user') {
                          // Handle showing user profile or other user-related actions
                        } else if (value == 'logout') {
                          FirebaseAuth.instance.signOut();
                          screenProvider.setCurrentScreen(0);
                        } else if (value == 'login') {
                          _showLoginDialog();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        final popupItems = <PopupMenuEntry<String>>[];
                        if (username!.isNotEmpty) {
                          // User is logged in, show "Username" and "Logout" options
                          popupItems.add(
                            PopupMenuItem<String>(
                              value: 'user',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(
                                    width: 7,
                                  ),
                                  Text(username),
                                ],
                              ),
                            ),
                          );
                          popupItems.add(
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.black,
                                  ),
                                  SizedBox(
                                    width: 7,
                                  ),
                                  Text('Logout'),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // User is not logged in, show "Login" option
                          popupItems.add(
                            const PopupMenuItem<String>(
                              value: 'login',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.login,
                                    color: Colors.black,
                                  ),
                                  SizedBox(
                                    width: 7,
                                  ),
                                  Text('Login'),
                                ],
                              ),
                            ),
                          );
                        }
                        return popupItems;
                      },
                    );
                  } else {
                    // While waiting for the future to complete, you can display a loading indicator or a placeholder.
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          for (var index = 0; index < _screens.length; index++)
            Visibility(
              visible: screenProvider.currentScreen ==
                  index, // Use the provider value
              child: _screens[index],
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu() {
    return StatefulBuilder(builder: (context, setState) {
      var screenProvider = Provider.of<ScreenProvider>(context);
      return Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {});
              screenProvider.setCurrentScreen(0);
            },
            child: Text(
              "Home",
              style: AppTextStyle.headerTextStyle(),
            ),
          ),
          const SizedBox(width: 30),
          InkWell(
            onTap: () {
              print("Movie");
              if (_auth.currentUser != null) {
                final user = _auth.currentUser;
                if (user!.emailVerified) {
                  setState(() {
                    screenProvider
                        .setCurrentScreen(1); // Display the Movie screen
                  });
                } else {
                  _showEmailVerifyDialog(); // Show the email verification dialog
                }
              } else {
                _showLoginDialog();
              }
            },
            child: Text(
              "Movie",
              style: AppTextStyle.headerTextStyle(),
            ),
          ),
          const SizedBox(width: 30),
          InkWell(
            onTap: () {
              if (_auth.currentUser != null) {
                final user = _auth.currentUser;
                if (user!.emailVerified) {
                  setState(() {
                    screenProvider
                        .setCurrentScreen(2); // Display the Movie screen
                  });
                } else {
                  _showEmailVerifyDialog(); // Show the email verification dialog
                }
              } else {
                _showLoginDialog();
              }
            },
            child: Text(
              "Book",
              style: AppTextStyle.headerTextStyle(),
            ),
          ),
          const SizedBox(width: 30),
          InkWell(
            onTap: () {
              setState(() {});
              if (_auth.currentUser != null) {
                final user = _auth.currentUser;
                if (user!.emailVerified) {
                  setState(() {
                    screenProvider
                        .setCurrentScreen(3); // Display the Movie screen
                  });
                } else {
                  _showEmailVerifyDialog(); // Show the email verification dialog
                }
              } else {
                _showLoginDialog();
              }
            },
            child: Text(
              "Music",
              style: AppTextStyle.headerTextStyle(),
            ),
          ),
          const SizedBox(width: 30),
          InkWell(
            onTap: () {
              if (_auth.currentUser != null) {
                final user = _auth.currentUser;
                if (user!.emailVerified) {
                  setState(() {
                    screenProvider
                        .setCurrentScreen(4); // Display the Movie screen
                  });
                } else {
                  _showEmailVerifyDialog(); // Show the email verification dialog
                }
              } else {
                _showLoginDialog();
              }
            },
            child: Text(
              "Fashion",
              style: AppTextStyle.headerTextStyle(),
            ),
          ),
          const SizedBox(width: 30),
        ],
      );
    });
  }

  TextEditingController loginControlleremail = TextEditingController();
  TextEditingController loginControllerpassword = TextEditingController();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  bool _autoValidate = false;
  String errorCode = '';
  bool error = false;
  Future<void> _showLoginDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: AlertDialog(
                title: const Text("Login"),
                content: Form(
                  key: _loginFormKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: loginControlleremail,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.com')) {
                            return 'Invalid email format';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        obscureText: true,
                        controller: loginControllerpassword,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      rowNavigation(
                          'Dont have an account? ', context, 'Sign Up', () {
                        Navigator.of(context).pop();
                        _showSignupDialog();
                      }),
                      const SizedBox(
                        height: 10,
                      ),
                      Consumer<UserProvider>(
                          builder: (context, userprovider, child) {
                        return InkWell(
                          onTap: () async {
                            if (_loginFormKey.currentState!.validate()) {
                              setState(
                                () {
                                  error = false;
                                },
                              );
                              try {
                                await _auth.signInWithEmailAndPassword(
                                    email: loginControlleremail.text,
                                    password: loginControllerpassword.text);
                                userprovider.setUser(_auth.currentUser!.uid);
                                print(_auth.currentUser!.uid);

                                Navigator.of(context).pop(); // Close the dialog
                                refreshKey.currentState?.show();
                                // Update the user's information

                                loginControlleremail.clear();
                                loginControllerpassword.clear();
                              } on FirebaseAuthException catch (e) {
                                String errorMessage = "";

                                if (e.code == 'invalid-login-credentials') {
                                  error = true;
                                  Timer(const Duration(seconds: 3), () {
                                    error = false;
                                    setState(
                                      () {},
                                    );
                                  });
                                  errorCode = "User not exist";
                                } else {
                                  errorMessage = "Other exception";
                                  var snackbar =
                                      SnackBar(content: Text(errorMessage));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackbar);
                                }
                              }
                              setState(() {});
                            } else {
                              setState(() {
                                _autoValidate = true;
                              });
                            }
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.blue,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 100,
                              ),
                              child: Text(
                                "Login",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(
                        height: 5,
                      ),
                      Center(
                          child: Text(
                        error ? errorCode : "",
                        style: const TextStyle(color: Colors.red),
                      ))
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  EmailAuth emailAuth = EmailAuth(sessionName: "User Registration");
  TextEditingController signupControllerusername = TextEditingController();
  TextEditingController signupControllerEmail = TextEditingController();
  TextEditingController signupControllerPassword = TextEditingController();
  TextEditingController otpController = TextEditingController();
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();
  List<String> gender = ['Male', 'Female'];
  String genderSelected = '';
  Future<void> _showSignupDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Center(
              child: AlertDialog(
            title: const Text("Sign Up"),
            content: Form(
              key: _signupFormKey,
              autovalidateMode: _autoValidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: signupControllerusername,
                    decoration: const InputDecoration(labelText: 'name'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: signupControllerEmail,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.com')) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    obscureText: true,
                    controller: signupControllerPassword,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: ToggleSwitch(
                      minWidth: 90.0,
                      initialLabelIndex: 1,
                      cornerRadius: 20.0,
                      activeFgColor: Colors.white,
                      inactiveBgColor: Colors.grey,
                      inactiveFgColor: Colors.white,
                      totalSwitches: 2,
                      labels: gender,
                      activeBgColors: const [
                        [Colors.blue],
                        [Colors.pink]
                      ],
                      onToggle: (index) {
                        if (index != null) {
                          genderSelected = gender[index];
                          print(genderSelected);
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  rowNavigation('Already have an account? ', context, 'Log In',
                      () {
                    Navigator.of(context).pop();
                    _showLoginDialog();
                  }),
                  const SizedBox(
                    height: 10,
                  ),
                  Consumer<UserProvider>(
                    builder: (context, userprovider, child) {
                      return InkWell(
                        onTap: () {
                          signUp();
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 100,
                            ),
                            child: Text(
                              "Sign Up",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Center(
                      child: Text(
                    error ? errorCode : "",
                    style: const TextStyle(color: Colors.red),
                  ))
                ],
              ),
            ),
          ));
        });
      },
    );
  }

  Widget rowNavigation(text1, context, text, onpressed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text1,
          style: AppTextStyle.textColor(15),
        ),
        const SizedBox(
          width: 3,
        ),
        TextButton(
            onPressed: () {
              onpressed();
            },
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            )),
      ],
    );
  }

  Future<void> addUser(UserModel User) async {
    final quizdatauser = FirebaseFirestore.instance.collection('user');
    FirebaseAuth auth = FirebaseAuth.instance;
    try {
      final user = auth.currentUser;
      if (user != null) {
        final uuserr = UserModel(
            userid: User.userid,
            email: User.email,
            username: User.username,
            gender: User.gender);
        await quizdatauser.doc(user.uid).set(uuserr.toMap());
      }
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  void signUp() async {
    if (_signupFormKey.currentState!.validate()) {
      setState(() {
        error = false;
      });
      try {
        await _auth.createUserWithEmailAndPassword(
          email: signupControllerEmail.text,
          password: signupControllerPassword.text,
        );

        Navigator.pop(context);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          addUser(UserModel(
            userid: user.uid,
            username: signupControllerusername.text,
            email: signupControllerEmail.text,
            gender: genderSelected,
          ));
        }

        signupControllerEmail.clear();
        signupControllerPassword.clear();
        signupControllerusername.clear();
        error = false;
        setState(() {});
      } on FirebaseAuthException catch (e) {
        print(e.code);
        if (e.code == 'email-already-in-use') {
          setState(() {
            error = true;
            errorCode = "Email already in use";
          });
          Timer(const Duration(seconds: 3), () {
            setState(() {
              error = false;
            });
          });
        } else {
          errorCode = "An error occurred during signup";
          var snackbar = SnackBar(content: Text(errorCode));
          ScaffoldMessenger.of(context).showSnackBar(snackbar);
        }
        setState(() {});
      }
    } else {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  Future<void> _showEmailVerifyDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: AlertDialog(
                  title: const Text("Click to verify your email"),
                  content: ElevatedButton(
                      onPressed: () async {
                        _auth.currentUser!.sendEmailVerification();
                        final snackBar = SnackBar(
                          /// need to set following properties for best effect of awesome_snackbar_content
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'Success!',
                            message:
                                'A verification link has been sent to your email address. Please check your inbox and click on the link to complete the verification process',

                            /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                            contentType: ContentType.success,
                          ),
                        );

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(snackBar);
                        _auth.signOut();
                        refreshKey.currentState?.show();
                        Navigator.pop(context);
                      },
                      child: const Text("Verify Email"))),
            );
          },
        );
      },
    );
  }
}
