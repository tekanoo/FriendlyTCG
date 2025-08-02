import 'package:flutter/material.dart';
import 'trades_screen.dart';
import 'my_trades_screen.dart';

class TradesMainScreen extends StatefulWidget {
  const TradesMainScreen({super.key});

  @override
  State<TradesMainScreen> createState() => _TradesMainScreenState();
}

class _TradesMainScreenState extends State<TradesMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TradesScreen(),
          MyTradesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Rechercher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Mes échanges',
          ),
        ],
      ),
    );
  }
}
