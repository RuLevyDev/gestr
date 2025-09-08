import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gestr/core/auth/application/view/auth_view.dart';
import 'package:gestr/app/fixedpayments/application/view/create_fixed_paymentes_view.dart';
import 'package:gestr/app/fixedpayments/bloc/fixed_payment_provider.dart';
import 'package:gestr/app/invoices/bloc/invoice_provider.dart';
import 'package:gestr/app/incomes/bloc/income_provider.dart';
import 'package:gestr/app/incomes/application/view/create_income_page.dart';
import 'package:gestr/app/invoices/application/view/create_invoice_page.dart';
import 'package:gestr/home_page.dart';
import 'package:gestr/app/tax/bloc/tax_provider.dart';
import 'package:gestr/domain/errors/unknown_route_page.dart';
import 'package:provider/provider.dart';

import 'package:gestr/core/auth/bloc/user_provider.dart';
import 'package:gestr/core/config/remote/app_enviroment.dart';
import 'package:gestr/core/config/remote/endpoints.dart';
import 'package:gestr/core/utils/app_theme.dart';
import 'package:gestr/core/auth/application/widgets/auth_gate.dart';

// Importa tus pantallas aquí

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppEnvironment().init();
  Endpoints().init();

  if (kDebugMode) {
    debugPrint('🌍 Running in: ${AppEnvironment().releaseType.nameStr}');
    debugPrint('🏗️ Estamos en modo DEBUG');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', ''), Locale('es', '')],
      path: 'assets/jsons', // Ruta a tus archivos JSON
      fallbackLocale: const Locale('es', ''),
      useOnlyLangCode: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        myLightColorScheme; //myLightColorScheme O myDarkColorScheme
    return MultiProvider(
      providers: [
        ...UserProvider.get(),
        ...InvoiceProvider.get(),
        ...IncomeProvider.get(),
        ...FixedPaymentProvider.get(),
        ...TaxProvider.get(),
      ],
      child: MaterialApp(
        title: 'Gestr App',
        theme: getAppTheme(colorScheme),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),
          '/home': (context) => const HomePage(),
          '/login': (context) => const AuthView(),
          '/create-invoice': (context) => const CreateInvoicePage(),
          '/create-income': (context) => const CreateIncomePage(),
          '/create-fixed-payment': (context) => const CreateFixedPaymentPage(),
          // '/profile': (context) => const ProfileScreen(),
        },
        onUnknownRoute:
            (settings) =>
                MaterialPageRoute(builder: (_) => const UnknownRoutePage()),
      ),
    );
  }
}
