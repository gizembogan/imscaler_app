
import 'package:flutter/material.dart';
import '../pages/profile_page.dart';

class ProfileIconButton extends StatelessWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 35.0,
      splashRadius: 40.0,
      icon: const Icon(Icons.person, color: Colors.white),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
      },
    );
  }
}
