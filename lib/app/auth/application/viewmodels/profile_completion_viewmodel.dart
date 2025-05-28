import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestr/domain/entities/self_employed_user.dart';
import 'package:gestr/domain/errors/user_profile_failures.dart';
import 'package:gestr/domain/usecases/user/self_employed_user_usecases.dart';
import 'package:gestr/app/auth/application/widgets/self_employed_profile_dialog.dart';
import 'package:gestr/app/auth/bloc/self_employed_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin ProfileCompletionViewmodelMixin<T extends StatefulWidget> on State<T> {
  bool _isProfileIncomplete(SelfEmployedUser user) {
    return user.fullName.trim().isEmpty ||
        user.dni.trim().isEmpty ||
        user.activity.trim().isEmpty ||
        user.iban.trim().isEmpty;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfProfileCompletedAndShowDialog(context);
    });
  }

  Future<void> _checkIfProfileCompletedAndShowDialog(
    BuildContext context,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // ✅ Extraemos antes del await
    final useCases = context.read<SelfEmployedUserUseCases>();

    final prefs = await SharedPreferences.getInstance();
    final key = 'profile_completed_${currentUser.uid}';
    final isProfileCompleted = prefs.getBool(key) ?? false;

    if (!isProfileCompleted) {
      final result = await useCases.getUser(currentUser.uid);

      if (!mounted) return;

      result.fold(
        (failure) {
          debugPrint("❌ Error al obtener usuario: $failure");

          if (failure == const UserNotFound()) {
            _showProfileDialog(uid: currentUser.uid, prefsKey: key);
          }
        },
        (user) {
          final isIncomplete = _isProfileIncomplete(user);
          debugPrint("🟡 Perfil incompleto: $isIncomplete");

          if (isIncomplete) {
            _showProfileDialog(uid: currentUser.uid, prefsKey: key);
          } else {
            prefs.setBool(key, true);
          }
        },
      );
    }
  }

  void _showProfileDialog({required String uid, required String prefsKey}) {
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider(
          create:
              (_) => SelfEmployedBloc(context.read<SelfEmployedUserUseCases>()),
          child: SelfEmployedProfileDialog(
            uid: uid,
            onSave: (SelfEmployedUser user) async {
              debugPrint("📌 Perfil guardado: ${user.fullName}");
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(prefsKey, true);
            },
          ),
        );
      },
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }
}
