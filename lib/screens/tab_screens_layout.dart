import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cookie_jar/cookie_jar.dart';
import 'dart:convert';
import '../widgets/logoutbutton.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:html/parser.dart' as htmlParser;


class TabScreenLayout extends StatefulWidget {
  final int id;
  const TabScreenLayout({Key? key, this.id = 0}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<TabScreenLayout> {
  List<Map<String, String>> responseData = [];
  List<List<Map<String, String>>> secondResponseData = [];
  int selectedIndex = 0;
  List<bool> isContentVisible = [];
  bool isSpeaking = false;
  final _flutterTts = FlutterTts();

  void initializeTts() {
    _flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
    _flutterTts.setErrorHandler((message) {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }
  void speak(String text) async {
    final strippedText = _stripHtmlTags(text);
    await _flutterTts.speak(strippedText);
  }

  String _stripHtmlTags(String htmlText) {
    final regex = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    final parsedText = htmlParser.parse(htmlText);
    final strippedText = parsedText.body!.text.trim();
    final normalizedText = strippedText.replaceAll(regex, '');
    return normalizedText;
  }

  void stop() async {
    await _flutterTts.stop();
    setState(() {
      isSpeaking = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _flutterTts.stop();
  }

  Future<List<Map<String, dynamic>>> lifeCoachRoutes() async {
    try {
      final cookieJar = CookieJar();
      final uri = Uri.parse(
          'https://jobportal.techallylabs.com/api/v1/life-coach/life-coach-routes');
      final request = http.Request('GET', uri);
      final cookies = await cookieJar.loadForRequest(uri);
      Cookie? token;

      for (final cookie in cookies) {
        if (cookie.name == 'jwt_token') {
          token = cookie;
          break;
        }
      }
      if (token != null) {
        request.headers['Authorization'] = 'Bearer ${token.value}';
      }
      request.headers['Content-Type'] = 'application/json';

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedData = jsonDecode(responseData) as List<dynamic>;
      final routes = decodedData
          .map((data) => {
                'id': data['id'],
                'name': data['name'],
              })
          .toList();
      return routes;
    } catch (err) {
      print(err);
      return []; // Return an empty list in case of an error
    }
  }

  Future<void> fetchData() async {
    try {
      final firstUri = Uri.parse(
          'https://jobportal.techallylabs.com/api/v1/life-coach/top-nav/${widget.id}');
      final firstResponse = await http.get(firstUri);

      if (firstResponse.statusCode == 200) {
        final decodedData = jsonDecode(firstResponse.body) as List<dynamic>;
        final dataList = decodedData.map((data) {
          final name = data['name'].toString();
          final id = data['id'].toString();
          return {'name': name, 'id': id};
        }).toList();
        setState(() {
          responseData = dataList;
          isContentVisible = List.generate(responseData.length, (_) => false);
        });
      }

      final secondResponseList = await Future.wait(responseData.map((data) {
        final secondUri = Uri.parse(
            'https://jobportal.techallylabs.com/api/v1/life-coach/types/${data['id']}');
        return http.get(secondUri).then((secondResponse) {
          if (secondResponse.statusCode == 200) {
            final decodedData =
            jsonDecode(secondResponse.body) as List<dynamic>;
            final dataList = decodedData.map((data) {
              final name = data['name'].toString();
              final content = data['content'].toString();
              return {'name': name, 'content': content};
            }).toList();
            return dataList;
          }
          return [];
        });
      }));

      setState(() {
        secondResponseData = secondResponseList.cast<List<Map<String, String>>>();
      });
    } catch (err) {
      print(err);
    }
  }

  Future<void> refreshData(BuildContext context) async {
    // Call the fetchData method to retrieve the latest data
    await fetchData();
    await Future.delayed(const Duration(seconds: 2));
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data Refreshed',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:Color(0xFF08154A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => refreshData(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          backgroundColor: const Color(0xFF08154A),
          centerTitle: true,
        ),
        body: Row(
          children: [
            Expanded(
              flex: 1,
              child: SafeArea(
                child: Container(
                  color: const Color(0xFF08154A), // Customize the color for the drawer
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ListView(
                      children: [
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child: Container(
                                    color: Colors.transparent,
                                    width: 100.0,
                                    height: 100.0,
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 100.0,
                                      height: 100.0,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20.0),
                                const LogOutButton(),
                              ],
                            ),
                            const SizedBox(height: 30.0),
                            Container(
                              height: 1.0,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            SingleChildScrollView(
                              child: ListTile(
                                title: RefreshIndicator(
                                  onRefresh: () => refreshData(context),
                                  child:
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                    future: lifeCoachRoutes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final routes = snapshot.data;
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: routes!
                                                .map(
                                                  (route) => GestureDetector(
                                                    onTap: () {
                                                      final id = route['id'];
                                                      final name =
                                                          route['name'];
                                                      print('ID: $id');
                                                      print('Name: $name');
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              TabScreenLayout(
                                                                  id: id),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 8.0),
                                                      child: Text(
                                                        route['name'],
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.topCenter,
                child: DefaultTabController(
                      length: responseData.length,
                      child: Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            tabs: responseData
                                .map(
                                  (data) => Tab(
                                    child: Container(
                                      alignment: Alignment.center,
                                      constraints:
                                          const BoxConstraints.expand(
                                              width: 150),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6ECF9),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Text(
                                        data['name'] ?? " ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:Color(0xFF08154A),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onTap: (index) {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                          ),
                          Expanded(
                            child: Container(
                              child: TabBarView(
                                children: secondResponseData.isNotEmpty
                                    ? List.generate(secondResponseData.length, (i) {
                                  final secondResponse = secondResponseData[i];
                                  return SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        for (final response in secondResponse)
                                          Column(
                                            children: [
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      speak(response['name'] ?? '');
                                                    },
                                                    child: Text(
                                                      '${response['name'] ?? ''} :',
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        color: Color(0xFF08154A),
                                                        fontWeight: FontWeight.bold,

                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        isContentVisible[i] = !isContentVisible[i];
                                                      });
                                                    },
                                                    child: Icon(
                                                      isContentVisible[i]
                                                          ? Icons.arrow_drop_down
                                                          : Icons.arrow_drop_up,
                                                      color: const Color(0xFF08154A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (isContentVisible[i])
                                                const SizedBox(height: 10),
                                              AnimatedCrossFade(
                                                duration: const Duration(milliseconds: 300),
                                                crossFadeState: isContentVisible[i]
                                                    ? CrossFadeState.showFirst
                                                    : CrossFadeState.showSecond,
                                                firstChild: GestureDetector(
                                                  onTap: () {
                                                    speak(response['content'] ??
                                                        '');
                                                  },
                                                  child: HtmlWidget(
                                                    '<div style="text-align: center;color: #08154A;font-size: 18px">${response['content'] ?? ''}</div>',
                                                    webView: true,
                                                  ),
                                                ),
                                                secondChild: Container(),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  );
                                })
                                    : [
                                  const Center(
                                    child: Text('No data available',style: TextStyle(color: Color(0xFF08154A),fontWeight: FontWeight.bold),),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
