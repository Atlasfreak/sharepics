import 'package:flutter/material.dart';
import 'package:sharepics/src/pages/home_page.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.

    Color onPrimaryLight = ThemeData.light().colorScheme.onPrimary;
    Color onPrimaryDark = ThemeData.dark().colorScheme.onPrimary;
    return MaterialApp(
      // Providing a restorationScopeId allows the Navigator built by the
      // MaterialApp to restore the navigation stack when a user leaves and
      // returns to the app after it has been killed while running in the
      // background.
      restorationScopeId: 'app',

      // Use AppLocalizations to configure the correct application title
      // depending on the user's locale.
      //
      // The appTitle is defined in .arb files found in the localization
      // directory.
      onGenerateTitle: (BuildContext context) => "Sharepic generator",

      // Define a light and dark color theme. Then, read the user's
      // preferred ThemeMode (light, dark, or system default) from the
      // SettingsController to display the correct theme.
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: ThemeData.light().colorScheme.inversePrimary,
          titleTextStyle: TextStyle(
              color: Color.fromARGB(
                  onPrimaryLight.alpha,
                  255 - onPrimaryLight.red,
                  255 - onPrimaryLight.green,
                  255 - onPrimaryLight.blue),
              fontSize: 20),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: ThemeData.dark().colorScheme.inversePrimary,
          titleTextStyle: TextStyle(
              color: Color.fromARGB(
                  onPrimaryDark.alpha,
                  255 - onPrimaryDark.red,
                  255 - onPrimaryDark.green,
                  255 - onPrimaryDark.blue),
              fontSize: 20),
        ),
      ),
      themeMode: ThemeMode.system,

      home: HomePage(),
    );
  }
}
