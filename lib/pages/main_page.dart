import 'package:flutter/material.dart';
import 'package:pdfreaderk/navigationpages/recentpage.dart';
import '../navigationpages/createrecentpadf.dart';
import '../navigationpages/favorite.dart';
import 'homepage.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Homescreen(),
    const RecentPdfScreen(),
    const CreatePdfScreen(),
    const FavoritePage(), // ✅ Use favorite page
  ];

  final List<String> _titles = [
    "PDF Files",
    "Recent Files",
    "Create PDF",
    "Favorite",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.blue,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        iconSize: 30,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: "PDF FILES",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Recent",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: "Create",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite",
          ),
        ],
      ),
    );
  }
}
