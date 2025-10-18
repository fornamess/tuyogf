import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/speech/speech_bloc.dart';
import 'bloc/history/history_bloc.dart';
import 'screens/improved_main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const CashflowApp());
}

class CashflowApp extends StatelessWidget {
  const CashflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SpeechBloc()),
        BlocProvider(create: (context) => HistoryBloc()),
      ],
      child: MaterialApp(
        title: 'Cashflow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.amber,
          primaryColor: const Color(0xFFFFD700),
          scaffoldBackgroundColor: const Color(0xFF0F0F23),
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
            bodySmall: TextStyle(color: Colors.white),
          ),
        ),
        home: const ImprovedMainScreen(),
      ),
    );
  }
}