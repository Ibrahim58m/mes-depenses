# Guide d'installation — Mes Dépenses

## Pré-requis

1. **Installer Flutter** : https://docs.flutter.dev/get-started/install/windows
2. **Installer Android Studio** : https://developer.android.com/studio
3. **Configurer un émulateur** ou connecter un téléphone Android

## Lancer l'application

```bash
# 1. Aller dans le dossier du projet
cd C:\Users\moumi\expense_tracker

# 2. Installer les dépendances
flutter pub get

# 3. Lancer sur Android
flutter run
```

## Première utilisation

1. Ouvrir l'application
2. Accepter la permission d'accès aux SMS
3. Appuyer sur l'icône **Sync** (↻) en haut à droite
4. L'app importe tous les SMS de CAC Bank, Waafi et D-Money
5. Catégoriser vos transactions en appuyant sur "+ Catégorie"

## Fonctionnalités

- **Accueil** : Total dépenses + graphiques journaliers et par catégorie
- **Transactions** : Liste complète avec filtre par période
- **Bénéficiaires** : Qui vous avez envoyé de l'argent et combien
- **Catégories** : Répartition de vos dépenses par type

## SMS supportés

| Service      | Type                    |
|-------------|------------------------|
| CAC Bank    | Paiements ePOS/USSD    |
| Waafi       | Transferts vers contacts |
| D-Money     | Virement + crédit tél. |
