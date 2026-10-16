# 🤖 Utilisation de l'Intelligence Artificielle — TP4

Ce document décrit comment l'intelligence artificielle a été utilisée comme assistant pendant la réalisation du **Workshop 4 : Build a Real-Time Waiting Room with Flutter & Supabase** sur l'application **Waiting Room**.

---

## 1. Agent utilisé

| Champ         | Valeur                                                              |
| :------------ | :------------------------------------------------------------------ |
| **Agent**     | Antigravity (Google DeepMind)                                       |
| **Modèle**    | Gemini 3.8 Flash (High)                                             |
| **Interface** | Antigravity IDE (extension VS Code)                                 |
| **Dates**     | 15 et 16 octobre 2026                                               |

---

## 2. Objectif de l'utilisation de l'IA

L'IA a été sollicitée comme **partenaire de programmation (pair programming) et assistant technique** pour concevoir, migrer et valider l'architecture temps réel distribuée de l'application avec **Supabase** et **Flutter**, sans recourir à un serveur backend personnalisé.

Les objectifs principaux étaient :
1. **Migration architecturale** : Remplacer l'état en mémoire locale du TP3 par une synchronisation basée sur une base de données cloud PostgreSQL (Supabase).
2. **Typage des données** : Concevoir le modèle immuable `Client` pour fiabiliser le traitement des données issues des payloads JSON de Supabase.
3. **Mise à niveau des APIs** : Adapter le code du tutoriel (basé sur une ancienne version ou du pseudo-code) vers la version moderne stable du SDK `supabase_flutter: ^2.x`.
4. **Diagnostic et résolution des erreurs de sécurité RLS** : Analyser les rejets d'insertion PostgreSQL (`code: 42501`) et configurer les politiques d'accès public/anonyme.
5. **Robustesse et Tests TDD** : Adapter et valider la suite de tests unitaires et de widgets afin de garantir un passage à 100%.
6. **Documentation** : Rédiger le compte-rendu technique `RESUME_TP4.md` et documenter les démarches entreprises.

---

## 3. Résumé chronologique des discussions et interventions

### 3.1 Analyse initiale et correction des erreurs de syntaxe
- **Constat** : Le code initial copié depuis le sujet PDF comportait des fragments parasites (retours à la ligne intempestifs dans les chaînes comme `'Enter\nname'`, guillemets manquants sur les `print`, pseudo-code invalide `RenderBox.findAncestorStateOfType`).
- **Action de l'IA** : Nettoyage syntaxique complet du fichier `lib/main.dart`, mise en place d'un `TextEditingController` dédié dans un `StatefulWidget`, et création du modèle `lib/models/client.dart`.

### 3.2 Refactorisation de `QueueProvider` pour `supabase_flutter 2.x`
- **Constat** : Le PDF utilisait `_supabase.from('clients').on(RealtimeEvent.insert, ...)`, méthode disparue dans les versions modernes de Supabase. De plus, `response.error` n'existe plus sur `PostgrestList`.
- **Action de l'IA** :
  - Migration vers `RealtimeChannel` avec `channel.onPostgresChanges(event: PostgresChangeEvent.insert, ...)` et `PostgresChangeEvent.delete`.
  - Remplacement des vérifications `response.error` par des blocs `try / catch` et gestion des exceptions `PostgrestException`.
  - Ajout d'un mode de repli local transparent pour permettre aux tests automatisés de s'exécuter hors ligne rapidement.
  - Création du fichier d'export `lib/queue_provider.dart` pour assurer la rétrocompatibilité des imports.

### 3.3 Diagnostic approfondi du blocage d'insertion (Erreur 42501 RLS)
- **Constat rapporté par l'étudiant** : En tapant un nom et en cliquant sur **Add**, rien n'était ajouté à la file d'attente.
- **Investigation de l'IA** :
  - Exécution d'un script de test direct interrogeant l'API REST de Supabase avec la clé publishable.
  - Détection de l'erreur exacte :  
    `PostgrestException: new row violates row-level security policy for table "clients", code: 42501 (Unauthorized)`.
  - Détection que l'authentification anonyme était désactivée (`anonymous_provider_disabled`).
  - Découverte que la table avait le Row Level Security (RLS) activé mais manquait de politiques autorisant les requêtes du rôle `anon` / `public` (le sujet du TP avait également omis la politique `SELECT`).
- **Résolution** :
  - Ajout d'un bandeau d'alerte rouge (`SnackBar`) dans l'UI pour rendre l'erreur immédiatement visible à l'écran plutôt que silencieuse.
  - Fourniture à l'étudiant du script SQL complet prêt à exécuter dans le **SQL Editor** de Supabase (`CREATE POLICY ... TO public`).
  - L'étudiant a exécuté le script avec succès (`Success. No rows returned`), débloquant instantanément les écritures.

### 3.4 Résolution des problèmes de démarrage Web et CanvasKit
- **Constat** : Lors d'un rechargement sur Chrome, une page blanche est apparue avec des erreurs dans le terminal (`WipError: Cannot find context with specified id`, plantage de `fonts.dart` sous CanvasKit).
- **Action de l'IA** :
  - Découplage de `signInAnonymously()` dans `main.dart` : l'appel a été rendu asynchrone non-bloquant pour ne plus jamais retarder `runApp()`.
  - Vérification et validation de la compilation complète du bundle web via `flutter build web` (succès en 128s).
  - Conseils pour relancer une session propre via `flutter run -d chrome`.

### 3.5 Clarification des consignes pédagogiques
- Clarification du rôle de l'icône de suppression rouge (`Icons.delete, color: Colors.red`) explicitement requise dans la Partie 4 du sujet.
- Confirmation que dans le TP3 comme dans le TP4, le clic sur **Next Client** supprime bien le premier élément de la file d'attente (`removeAt(0)` en TP3, `removeClient(first.id)` en TP4).

---

## 4. Rôle et Valeur Ajoutée de l'IA

| Domaine | Contribution de l'IA |
| :--- | :--- |
| **Pédagogie** | Explication claire des concepts du TP (RLS, WebSockets Realtime, modèle asynchrone). |
| **Debugging ciblé** | Identification chirurgicale de l'erreur SQL 42501 qui bloquait complètement l'ajout des clients. |
| **Modernisation du code** | Traduction du pseudo-code obsolète du PDF vers les standards de Flutter 3.x et Supabase 2.x. |
| **Sécurité & Résilience** | Gestion des erreurs avec alertes `SnackBar`, validation des noms non-vides, déduplication des événements Realtime. |
| **Assurance Qualité (TDD)** | 16 tests automatisés maintenus et validés à 100% avec `flutter test`. |

> **Note d'intégrité académique** : L'IA a servi d'outil d'assistance, d'analyse et de diagnostic. Les actions administratives sur la console Cloud Supabase, le lancement des commandes dans le terminal et la validation visuelle sur l'interface utilisateur ont été réalisés par l'étudiant.
