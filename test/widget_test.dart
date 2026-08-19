import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisimba_pos/src/app.dart';
import 'package:kisimba_pos/src/auth/auth_store.dart';
import 'package:kisimba_pos/src/auth/phone_number.dart';

class MemoryAuthStore implements AuthStore {
  LocalAccount? value;
  RegistrationData? registration;
  @override
  Future<LocalAccount?> get account async => value;
  @override
  Future<void> lock() async {}
  @override
  Future<LocalAccount> register(RegistrationData data) async {
    registration = data;
    return value = LocalAccount(
      phoneNumber: normalizeCongolesePhone(data.phoneNumber)!,
      fullName: data.fullName,
      businessName: data.businessName,
    );
  }

  @override
  Future<bool> unlock(String phoneNumber, String pin) async => pin == '1234';
}

void main() {
  test('normalise les formats courants de la RDC', () {
    expect(normalizeCongolesePhone('082 491 6124'), '+243824916124');
    expect(normalizeCongolesePhone('+243 824 916 124'), '+243824916124');
    expect(normalizeCongolesePhone('824916124'), '+243824916124');
    expect(normalizeCongolesePhone('123'), isNull);
  });

  testWidgets('inscription en quatre étapes sans email', (tester) async {
    final store = MemoryAuthStore();
    await tester.pumpWidget(KisimbaApp(authStore: store));
    await tester.pumpAndSettle();
    expect(
      find.text('Pas besoin de Gmail ni d’adresse email.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('phone')), '0824916124');
    await tester.enterText(find.byKey(const Key('fullName')), 'Amina Mbayo');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('businessName')),
      'Boutique Amina',
    );
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer cette étape'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pin')), '1234');
    await tester.enterText(find.byKey(const Key('confirmPin')), '1234');
    await tester.tap(find.byKey(const Key('primaryAction')));
    await tester.pumpAndSettle();
    expect(find.text('Ajoutez votre premier produit'), findsOneWidget);
    expect(store.registration?.businessName, 'Boutique Amina');
  });

  testWidgets('espace professionnel sans contrainte de largeur infinie', (
    tester,
  ) async {
    final store = MemoryAuthStore()
      ..value = const LocalAccount(
        phoneNumber: '+243824916124',
        fullName: 'Amina Mbayo',
        businessName: 'Boutique Amina',
      );
    await tester.pumpWidget(KisimbaApp(authStore: store));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Ouvrir ma boutique'));
    await tester.pumpAndSettle();

    expect(find.text('Espace professionnel'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('tab_1')));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle vente'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab_2')));
    await tester.pumpAndSettle();
    expect(find.text('Mon stock'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab_3')));
    await tester.pumpAndSettle();
    expect(find.text('Mon équipe'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab_4')));
    await tester.pumpAndSettle();
    expect(find.text('Plus'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
