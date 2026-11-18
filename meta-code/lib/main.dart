import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/ads/ad_banner.dart';
import 'core/storage.dart';
import 'features/agent_lab/agent_lab_screen.dart';
import 'features/learning_paths/paths_screen.dart';
import 'features/library_catalog/library_screen.dart';
import 'features/tutor_companion/tutor_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Sin await: los anuncios no deben retrasar el arranque.
  initAds();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MetaCodeApp(),
    ),
  );
}

class MetaCodeApp extends StatelessWidget {
  const MetaCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3D5AFE);
    return MaterialApp(
      title: 'meta-code',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.screen);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

const _destinations = [
  _Destination('Rutas', Icons.route_outlined, Icons.route, PathsScreen()),
  _Destination('Tutor', Icons.forum_outlined, Icons.forum, TutorScreen()),
  _Destination(
    'Laboratorio',
    Icons.science_outlined,
    Icons.science,
    AgentLabScreen(),
  ),
  _Destination(
    'Biblioteca',
    Icons.menu_book_outlined,
    Icons.menu_book,
    LibraryScreen(),
  ),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final body = IndexedStack(
      index: _index,
      children: [for (final d in _destinations) d.screen],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'meta-code',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: body),
                  const AdBanner(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBanner(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
