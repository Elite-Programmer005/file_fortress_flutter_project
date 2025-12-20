import 'package:file_fortress/core/constants/routes.dart';
import 'package:file_fortress/domain/entities/file_entity.dart';
import 'package:file_fortress/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_fortress/core/themes/app_theme.dart';
import 'package:file_fortress/presentation/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Database and Storage Initialization ---
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(FileEntityAdapter());
  await Hive.openBox<FileEntity>('files');

  // --- Check if Master Key Exists ---
  const storage = FlutterSecureStorage();
  final masterKey = await storage.read(key: 'master_key');
  final initialRoute = masterKey == null ? Routes.setupPin : Routes.pinLogin;

  // --- System UI and Orientation ---
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: FileFortressApp(initialRoute: initialRoute),
    ),
  );
}

class FileFortressApp extends StatelessWidget {
  final String initialRoute;

  const FileFortressApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'FileFortress',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: initialRoute,
          routes: Routes.routes,
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              },
              child: child,
            );
          },
        );
      },
    );
  }
}
