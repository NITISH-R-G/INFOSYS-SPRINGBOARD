import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/contract_detail_screen.dart';
import 'screens/vin_lookup_screen.dart';
import 'screens/risk_strategy_screen.dart';
import 'screens/comparison_screen.dart';
import 'screens/comparison_dashboard_screen.dart';
import 'screens/dealer_dashboard_screen.dart';
import 'screens/offer_builder_screen.dart';
import 'screens/dealer_chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/audit_screen.dart';
import 'screens/macos_dashboard_screen.dart';

import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/analysis_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: const ContractAIApp(),
    ),
  );
}

class ContractAIApp extends StatelessWidget {
  const ContractAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ContractAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/upload': (context) => const UploadScreen(),
        '/vin-lookup': (context) => const VinLookupScreen(),
        '/negotiate': (context) => const RiskStrategyScreen(),
        '/dealer_chat': (context) => const DealerChatScreen(),
        '/comparison-dashboard': (context) => const ComparisonDashboardScreen(),
        '/dealer/dashboard': (context) => const DealerDashboardScreen(),
        '/dealer/offer-builder': (context) => const OfferBuilderScreen(),
        '/audit': (context) => const AuditScreen(),
        '/macos-dashboard': (context) => const MacosDashboardScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes like /contract/:id
        if (settings.name?.startsWith('/contract/') ?? false) {
          final id = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => ContractDetailScreen(contractId: id),
          );
        }

        if (settings.name == '/compare') {
          final args = settings.arguments as List<String>;
          return MaterialPageRoute(
            builder: (context) => ComparisonScreen(contractIds: args),
          );
        }
        return null;
      },
    );
  }
}
