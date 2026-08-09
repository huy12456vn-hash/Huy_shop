import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTab;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        final s = AppStrings(locale);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, -3),
              )
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
            onTap: onTab,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: s.navHome),
              BottomNavigationBarItem(icon: const Icon(Icons.category), label: s.navCategory),
              BottomNavigationBarItem(icon: const Icon(Icons.favorite_sharp), label: s.navWishlist),
              BottomNavigationBarItem(icon: const Icon(Icons.account_box), label: s.navAccount),
            ],
          ),
        );
      },
    );
  }
}