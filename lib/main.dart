import 'package:flutter/material.dart';
import 'package:map/collector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pothole Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int onPage = 0;
  final titles = ['Pothole Detection', 'Map', 'Pothole Detection'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(titles[onPage]),
        centerTitle: true,
      ),
      body: const CollectorPage(title: 'Data Collector'),
      // body: PageView(
      //   children: const <Widget>[
      //     CollectorPage(title: 'Data Collector'),
      //     CollectorPage(title: 'Data Collector'),
      //     CollectorPage(title: 'Data Collector'),
      //   ],
      //   onPageChanged: (index) {
      //     setState(() {
      //       onPage = index;
      //     });
      //   },
      // ),
      // bottomNavigationBar: BottomNavigationBar(
      //   items: const <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.map),
      //       label: 'Map',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.data_exploration_outlined),
      //       label: 'Data Collector',
      //     ),
      //   ],
      //   currentIndex: onPage,
      //   selectedItemColor: Theme.of(context).colorScheme.primary,
      //   onTap: (index) {
      //     setState(() {
      //       onPage = index;
      //     });
      //   },
      // ),
    );
  }
}
