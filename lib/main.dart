import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:who_app/pages/home_page.dart';
import 'firebase_options.dart';
import 'models/form.dart' as form_model;
import 'models/form_element.dart';
import 'models/page.dart' as page_model;
import 'models/selection.dart';
import 'models/text.dart' as text_model;

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  var form = form_model.Form(title: "default", pages: [page_model.Page(title: "page1", pageNumber: 1, description: "descriptionPage", elements: [text_model.Text(title: "text1", subTitle: "subtitle1", required: false, text: "")]), page_model.Page(title: "page2", pageNumber: 2, description: "descriptionPage", elements: [Selection(title: "text1", subTitle: "subtitle1", required: true, options: ["option1", "option2"], numOptions: 1)])]);
  final json = form.toJson();
  final db = FirebaseFirestore.instance;
  db.collection("forms").add(json);

  var snap = await db.collection("forms").get();
  var forms = snap.docs.map((x) => form_model.Form.fromJson(x.data())).toList();

  runApp(MaterialApp(home: HomePage(db: db)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    final List<Map<String, String>> forms = [
      {'title': '1984', 'author': 'George Orwell', 'description': 'A dystopian society under constant surveillance.'},
    ];

    final List<Map<String, String>> books = [
      {'title': '1984', 'author': 'George Orwell', 'description': 'A dystopian society under constant surveillance.'},
      {'title': 'Brave New World', 'author': 'Aldous Huxley', 'description': 'A futuristic world driven by technology and control.'},
      {'title': 'Fahrenheit 451', 'author': 'Ray Bradbury', 'description': 'A society where books are outlawed and burned.'},
    ];

    return MaterialApp(
      title: 'WHO Health Facilities',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Forms')),
        body: ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(books[index]['title']!),
              subtitle: Text(books[index]['author']!),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(
                      title: books[index]['title']!,
                      author: books[index]['author']!,
                      description: books[index]['description']!,
                    ),
                  ),
                );
              },
            );
          },
        ),
      )
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  final String title;
  final String author;
  final String description;

  BookDetailScreen({required this.title, required this.author, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: $title', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Author: $author', style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
            SizedBox(height: 12),
            Text('Description:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(description, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// class HomePage extends StatefulWidget {
//   const HomePage({super.key, required this.title});
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   final String title;
//
//   @override
//   State<HomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<HomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
