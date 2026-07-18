import 'package:flutter/material.dart';
import 'package:shop_gucci/screens/pages/home_page.dart';
import 'package:shop_gucci/widgets/nav_widget.dart';
import '../screens/pages/category_page.dart';
import '../screens/pages/account_page.dart';
import '../screens/pages/wishlist_page.dart';
import '../screens/pages/search_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  late Widget currentBody;
  String currentTitle = "GUCCI";

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
          currentTitle = "GUCCI";
          break;
        case 1:
          currentBody = CategoryPage();
          currentTitle = "Category";
          break;
        case 2:
          currentBody = WishlistPage();
          currentTitle = "Wishlist";
          break;
        case 3:
          currentBody = AccountPage();
          currentTitle = "Account";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // nên để trắng đặc để bóng hiện rõ
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 3), // đổ bóng xuống dưới
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
              IconButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const SearchPage()));
              }, 
              icon: const Icon(Icons.search)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
            ],
          ),
        ),
      ),
      body: currentBody,
      bottomNavigationBar: AppBottomNav(currentIndex: currentIndex, onTab: changeTab),
    );
  }
}