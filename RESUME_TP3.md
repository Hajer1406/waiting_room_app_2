# 📋 Résumé du Workshop 3 — Provider & Scalable State Management with TDD

Ce document récapitule l'ensemble des étapes, concepts et résolutions de problèmes réalisés pour réussir le **Workshop 3** sur l'application **Waiting Room**.

---

## 🎯 1. Objectifs du Workshop 3

- **Gestion d'état scalable** : Remplacer l'état local basé sur `setState()` par une architecture centralisée avec le package **Provider** et la classe `ChangeNotifier`.
- **Découplage** : Éviter le *prop-drilling* et les reconstructions d'arbres inutiles (*unnecessary rebuilds*).
- **Méthodologie TDD** : Appliquer rigoureusement le cycle **Test-Driven Development** :
  1. 🔴 **Red** : Écrire un test qui échoue d'abord pour définir le besoin.
  2. 🟢 **Green** : Écrire le code minimal nécessaire pour satisfaire le test.
  3. 🔵 **Refactor** : Optimiser et nettoyer le code en toute sécurité grâce au filet de sécurité des tests.

---

## 📦 2. Étape 1 : Configuration et Dépendances

1. **Fichier modifié** : `pubspec.yaml`
2. **Ajout du package Provider** :
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     cupertino_icons: ^1.0.8
     provider: ^6.0.0
   ```
3. **Installation des dépendances** :
   ```bash
   flutter pub get
   ```

---

## 🧠 3. Étape 2 : Logique Métier avec TDD (Tests Unitaires)

### 🔴 Phase Red (Test unitaire)
Ajout d'un test unitaire pour la méthode `nextClient()` dans `test/waiting_room_manager_test.dart` (ou `test/queue_provider_test.dart`) :
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
  test('should remove the first client when nextClient() is called', () {
    // ARRANGE
    final manager = QueueProvider();
    manager.addClient('Client A');
    manager.addClient('Client B');

    // ACT
    manager.nextClient();

    // ASSERT
    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Client B');
  });
}
```
*Résultat initial* : Le test échoue (`Compilation failed` ou méthode introuvable).

### 🟢 Phase Green (Création du Provider)
Création du fichier `lib/queue_provider.dart` étendant `ChangeNotifier` :
```dart
import 'package:flutter/foundation.dart';

class QueueProvider extends ChangeNotifier {
  final List<String> _clients = [];
  List<String> get clients => _clients;

  void addClient(String name) {
    _clients.add(name);
    notifyListeners(); // Notifie les widgets abonnés
  }

  void removeClient(String name) {
    _clients.remove(name);
    notifyListeners();
  }

  void nextClient() {
    if (_clients.isNotEmpty) {
      _clients.removeAt(0);
      notifyListeners();
    }
  }
}
```
*Validation* : Exécution de `flutter test`, le test unitaire passe avec succès.

---

## 🎨 4. Étape 3 : Connexion de l'UI avec TDD (Tests de Widgets)

### 🔴 Phase Red (Test de widget)
Ajout d'un test dans `test/waiting_room_widget_test.dart` simulant l'interaction utilisateur :
```dart
testWidgets('should remove the first client from the list when "Next Client" is tapped',
    (WidgetTester tester) async {
  // ARRANGE
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (context) => QueueProvider(),
      child: const WaitingRoomApp(),
    ),
  );

  // Ajout de deux clients
  await tester.enterText(find.byType(TextField), 'Client A');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  await tester.enterText(find.byType(TextField), 'Client B');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // ACT : Clic sur le bouton Next Client
  await tester.tap(find.byKey(const Key('nextClientButton')));
  await tester.pump();

  // ASSERT
  expect(find.text('Client A'), findsNothing);
  expect(find.text('Client B'), findsOneWidget);
  expect(find.text('Clients in Queue: 1'), findsOneWidget);
});
```
*Résultat initial* : Le test échoue car le bouton `nextClientButton` n'existe pas encore.

### 🟢 Phase Green (Refactorisation de `lib/main.dart`)
1. **Injection globale** dans `main()` avec `ChangeNotifierProvider` :
   ```dart
   void main() {
     runApp(
       ChangeNotifierProvider(
         create: (context) => QueueProvider(),
         child: const WaitingRoomApp(),
       ),
     );
   }
   ```
2. **Transformation en `StatelessWidget`** : `WaitingRoomScreen` ne conserve plus d'état local (`setState()` supprimé).
3. **Consommation de l'état** :
   - `final queueProvider = context.watch<QueueProvider>();` pour lire l'état et reconstruire l'interface à chaque notification.
   - `context.read<QueueProvider>().action()` pour appeler les méthodes sans abonnement inutile.
4. **Bouton Next Client** :
   - Ajouté avec la clé `key: const Key('nextClientButton')` appelant `context.read<QueueProvider>().nextClient()`.

---

## 🛠️ 5. Problèmes Rencontrés & Solutions Apportées

| Problème rencontré | Cause | Solution apportée |
| :--- | :--- | :--- |
| **`Couldn't find constructor 'WaitingRoomApp'`** | Lors d'un copier-coller depuis le PDF, la classe `WaitingRoomApp` avait été effacée. | Restauration de la classe `WaitingRoomApp` comme racine MaterialApp. |
| **`Expected ',' before this` / `Too many positional arguments`** | Le numéro de page `5 / 6` du PDF s'était glissé dans `Expanded( 5 / 6 child: ListView... )`. | Nettoyage du code et suppression du fragment de texte `5 / 6`. |
| **`Found 2 widgets with type "ElevatedButton"`** | Si "Next Client" est un `ElevatedButton`, le test `find.byType(ElevatedButton)` devient ambigu. | Utilisation d'un `IconButton` ou `OutlinedButton` pour "Next Client", gardant "Add" comme unique `ElevatedButton`. |
| **Bouton Next Client masqué en haut à droite** | Le bandeau de débogage rouge `DEBUG` recouvrait l'extrémité droite de l'AppBar. | Ajout de `debugShowCheckedModeBanner: false` dans `MaterialApp`. |

---

## ✅ 6. Validation et Résultats Finaux

1. **Tests Flutter (`flutter test`)** :
   ```text
   00:04 +7: All tests passed!
   ```
   - 3 tests unitaires validés pour la logique métier (`QueueProvider`).
   - 4 tests de widgets validés pour l'interface utilisateur.

2. **Analyse statique (`flutter analyze`)** :
   ```text
   Analyzing waiting_room_app...
   No issues found! (ran in 3.1s)
   ```

3. **Exécution Web (`flutter run -d chrome`)** :
   - L'application permet d'ajouter des clients, d'en supprimer individuellement et de faire avancer la file avec **Next Client** de façon réactive et fluide.
