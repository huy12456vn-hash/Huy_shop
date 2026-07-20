import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/nav_widget.dart';
import 'pages/account_page.dart';
import 'pages/cart_page.dart';
import 'pages/category_page.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/wishlist_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  late Widget currentBody;
  String currentTitle = 'GUCCI';

  @override
  void initState() {
    super.initState();
    currentBody = HomePage();
  }

  void changeTab(int index) {
    setState(() {
      currentIndex = index;

      switch (index) {
        case 0:
          currentBody = HomePage();
          currentTitle = 'GUCCI';
          break;

        case 1:
          currentBody = const CategoryPage();
          currentTitle = 'Category';
          break;

        case 2:
          currentBody = const WishlistPage();
          currentTitle = 'Wishlist';
          break;

        case 3:
          currentBody = AccountPage();
          currentTitle = 'Account';
          break;
      }
    });
  }

  void _openSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  void _openCartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalCartItems = context.watch<CartProvider>().totalItems;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                blurRadius: 8,
                spreadRadius: 0,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              currentTitle,
              style: const TextStyle(letterSpacing: 5, fontSize: 30),
            ),
            actions: [
              IconButton(
                onPressed: _openSearchPage,
                icon: const Icon(Icons.search),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: _openCartPage,
                      icon: const Icon(Icons.shopping_bag_outlined),
                    ),
                    if (totalCartItems > 0)
                      Positioned(
                        top: 2,
                        right: 1,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            totalCartItems > 99
                                ? '99+'
                                : totalCartItems.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: currentBody,
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTab: changeTab,
      ),
    );
  }
}
