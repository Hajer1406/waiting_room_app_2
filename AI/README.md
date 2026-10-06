# 🤖 Utilisation de l'Intelligence Artificielle — TP3

Ce document décrit comment l'intelligence artificielle a été utilisée comme assistant pendant la réalisation du **TP3 — Gestion d'état scalable avec Provider & TDD** sur l'application **Waiting Room**.

---

## 1. Agent utilisé

| Champ         | Valeur                              |
| :------------ | :---------------------------------- |
| **Agent**     | Antigravity (Google DeepMind)       |
| **Modèle**    | Gemini Flash (High) → Claude Sonnet 4.6 (Thinking) *(changé en cours de session)* |
| **Interface** | Antigravity IDE (extension VS Code) |
| **Date**      | 6 octobre 2026                      |

---

## 2. Objectif de l'utilisation de l'IA

L'IA a été utilisée comme **assistant pédagogique et technique** pour comprendre et réaliser les différentes étapes du TP3 sur la gestion d'état scalable avec le package **Provider** et la classe **ChangeNotifier**, en appliquant la méthodologie **Test-Driven Development (TDD)**.

L'objectif global était de :
- Comprendre pourquoi et comment remplacer `setState()` par une architecture **Provider**.
- Implémenter `QueueProvider` en suivant le cycle TDD (Red → Green → Refactor).
- Connecter l'interface Flutter au `QueueProvider` avec `context.watch` et `context.read`.
- Écrire et valider des **tests unitaires** et des **tests de widgets**.
- Résoudre les erreurs de compilation et de comportement rencontrées.

---

## 3. Résumé des discussions

### 3.1 Compréhension de Provider et de ChangeNotifier

Nous avons expliqué pourquoi `Provider` est utilisé pour remplacer la gestion de l'état avec `setState()` utilisée dans les TP précédents.

Dans le TP2, l'état (liste des clients) était géré localement dans `WaitingRoomScreen` avec `setState()`. Dans le TP3, cette responsabilité est déplacée vers `QueueProvider` qui étend `ChangeNotifier`, permettant un découplage propre entre logique métier et interface.

### 3.2 Configuration du projet

- Ajout du package `provider: ^6.0.0` dans `pubspec.yaml`.
- Exécution de `flutter pub get` pour télécharger les dépendances.

### 3.3 Création de QueueProvider (cycle TDD — Phase Red)

Un test unitaire a d'abord été écrit dans `test/queue_provider_test.dart` pour définir le comportement attendu de `nextClient()`, **avant** que la classe n'existe. Le test échouait volontairement (phase 🔴 Red).

### 3.4 Implémentation de QueueProvider (cycle TDD — Phase Green)

Création du fichier `lib/queue_provider.dart` avec les méthodes :
- `addClient(String name)` — ajoute un client à la file.
- `removeClient(String name)` — supprime un client par son nom.
- `nextClient()` — retire le premier client de la file (`removeAt(0)`).

La méthode `notifyListeners()` notifie l'interface à chaque changement d'état.

### 3.5 Modification de l'interface (lib/main.dart)

`WaitingRoomScreen` a été transformé en `StatelessWidget`.  
L'injection du `QueueProvider` a été réalisée dans `main()` via `ChangeNotifierProvider`.  
L'application utilise :
- `context.watch<QueueProvider>()` — pour écouter les changements et reconstruire l'UI.
- `context.read<QueueProvider>()` — pour appeler les actions sans écoute permanente.

### 3.6 Résolution des erreurs de compilation

Plusieurs erreurs ont été rencontrées et résolues :

| Erreur | Cause | Solution |
| :--- | :--- | :--- |
| `Couldn't find constructor 'WaitingRoomApp'` | La classe racine avait été supprimée lors d'un copier-coller depuis le PDF du TP. | Restauration de la classe `WaitingRoomApp` comme racine `MaterialApp`. |
| `Expected ',' before this` / `Too many positional arguments` | Le numéro de page `5 / 6` du PDF s'était glissé dans le code `Expanded(5 / 6 child: …)`. | Nettoyage du code et suppression du texte parasite. |
| `Found 2 widgets with type "ElevatedButton"` | Le bouton *Next Client* était aussi un `ElevatedButton`, rendant `find.byType(ElevatedButton)` ambigu dans les tests. | Remplacement par un `IconButton` dans l'`AppBar` avec la clé `Key('nextClientButton')`. |
| Bouton *Next Client* masqué par le bandeau DEBUG | Le bandeau rouge recouvrait l'extrémité droite de l'`AppBar` en mode debug. | Ajout de `debugShowCheckedModeBanner: false` dans `MaterialApp`. |

### 3.7 Tests de widgets (cycle TDD — Phase Red puis Green)

Un test de widget a été rédigé pour simuler l'ajout de deux clients puis le clic sur *Next Client*, et vérifier que le premier client disparaît de l'interface.

### 3.8 Validation finale

Les commandes suivantes ont été utilisées pour valider le projet :

```bash
flutter test       # 00:04 +7: All tests passed!
flutter analyze    # No issues found! (ran in 3.1s)
flutter run -d chrome
```

---

## 4. Exemples de demandes faites à l'IA

- Comment configurer `provider` dans `pubspec.yaml` ?
- Pourquoi utiliser `ChangeNotifier` et `notifyListeners()` ?
- Comment écrire un **test unitaire** pour `nextClient()` avec la méthode TDD Red-Green-Refactor ?
- Comment transformer `WaitingRoomScreen` en `StatelessWidget` ?
- Quelle est la différence entre `context.watch<T>()` et `context.read<T>()` ?
- Comment écrire un **test de widget** pour simuler le clic sur *Next Client* ?
- Pourquoi l'erreur `Couldn't find constructor 'WaitingRoomApp'` apparaît-elle ?
- Pourquoi `find.byType(ElevatedButton)` échoue-t-il quand il y a deux boutons ?
- Comment masquer le bandeau DEBUG dans Flutter Web ?
- Comment résumer la conversation et créer un fichier `RESUME_TP3.md` en Markdown ?

---

## 5. Rôle de l'IA

L'IA a été utilisée pour :

- **Expliquer les concepts** de Provider, ChangeNotifier, TDD et les différences avec `setState()`.
- **Guider l'implémentation** étape par étape en suivant le cycle Red → Green → Refactor.
- **Diagnostiquer et corriger les erreurs** de compilation Flutter (erreurs syntaxiques issues du PDF, conflits de types de widgets).
- **Proposer des exemples de tests** unitaires et de widgets conformes aux bonnes pratiques Flutter.
- **Générer le fichier de résumé** `RESUME_TP3.md` à partir des échanges de la session.
- **Créer ce dossier** `AI/README.md` pour documenter l'usage de l'IA.

> **Note importante** : L'IA est un assistant. La compréhension des concepts, l'exécution des commandes, la vérification des résultats et les décisions de conception ont été réalisées par l'étudiant dans son environnement de développement local.

---

## 6. Structure du projet à l'issue du TP3

```
waiting_room_app/
│
├── AI/
│   └── README.md                        ← ce fichier (documentation IA)
│
├── lib/
│   ├── main.dart                        ← UI (StatelessWidget + Provider)
│   ├── queue_provider.dart              ← logique métier (ChangeNotifier)
│   └── waiting_room_card.dart           ← composant carte client
│
├── test/
│   ├── queue_provider_test.dart         ← tests unitaires (QueueProvider)
│   └── waiting_room_manager_test.dart   ← tests de widgets (UI)
│
├── RESUME_TP3.md                        ← résumé technique du TP3
├── pubspec.yaml
└── ...
```
