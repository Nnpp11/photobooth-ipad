# Photobooth iPad — Guide d'installation

## Ce que contient ce projet

Application iPadOS complète pour photobooth événementiel.
- Écran d'accueil animé (noir & or)
- Capture caméra avant avec compte à rebours
- Modes : photo simple, bande 3 poses, grille 4 poses, GIF
- Prévisualisation avec retake
- Consentement RGPD + galerie
- Partage : QR code, WhatsApp, email, sauvegarde photos
- Impression Canon SELPHY via AirPrint
- Administration avec PIN (5 taps coin haut droit)

---

## Étape 1 — Créer un compte GitHub (gratuit)

1. Va sur https://github.com
2. Clique sur "Sign up"
3. Crée un compte avec ton email

---

## Étape 2 — Déposer le code sur GitHub

1. Sur GitHub, clique sur le "+" en haut à droite → "New repository"
2. Nomme-le "photobooth-ipad"
3. Laisse tout le reste par défaut, clique "Create repository"
4. Télécharge GitHub Desktop : https://desktop.github.com
5. Installe-le sur ton PC Windows
6. Connecte-toi avec ton compte GitHub
7. Clique "Add an Existing Repository from your Hard Drive"
8. Sélectionne le dossier "Photobooth" que tu as reçu
9. Clique "Publish repository" → choisis le dépôt que tu viens de créer

---

## Étape 3 — Créer un compte Codemagic (build cloud gratuit)

1. Va sur https://codemagic.io
2. Clique "Start for free"
3. Connecte-toi avec GitHub (bouton "Continue with GitHub")
4. Autorise l'accès à ton dépôt "photobooth-ipad"
5. Codemagic détecte automatiquement le projet Xcode

### Configurer le build dans Codemagic

1. Clique sur ton projet "photobooth-ipad"
2. Va dans "Settings" → "iOS"
3. Dans "Code signing" : choisis "Apple Developer Portal" → entre ton Apple ID
4. Dans "Distribution" : sélectionne "Development" (pas App Store)
5. Dans "Build triggers" : tu peux déclencher manuellement
6. Clique "Start new build"

Le build prend environ 10-15 minutes.
À la fin, tu télécharges un fichier **Photobooth.ipa**

---

## Étape 4 — Installer AltServer sur ton PC Windows

1. Va sur https://altstore.io
2. Télécharge "AltServer for Windows"
3. Installe-le (c'est un .exe standard)
4. Lance AltServer — une icône apparaît dans la barre des tâches

---

## Étape 5 — Installer AltStore sur l'iPad

1. Branche l'iPad sur le PC en USB
2. Fais confiance à l'ordinateur sur l'iPad si demandé
3. Clique sur l'icône AltServer dans la barre des tâches Windows
4. Sélectionne "Install AltStore" → choisis ton iPad
5. Entre ton Apple ID quand demandé
6. AltStore s'installe sur l'iPad

**Sur l'iPad :** Réglages → Général → Gestion des apps → ton Apple ID → Faire confiance

---

## Étape 6 — Installer l'app Photobooth

1. Ouvre l'icône AltServer sur le PC (barre des tâches)
2. Clique "Sideload .ipa"
3. Sélectionne le fichier **Photobooth.ipa** téléchargé depuis Codemagic
4. Entre ton Apple ID
5. L'app s'installe sur l'iPad

**Sur l'iPad :** Réglages → Général → Gestion des apps → ton Apple ID → Faire confiance

---

## Renouvellement tous les 7 jours

AltStore renouvelle automatiquement la signature si :
- Le PC est allumé
- L'iPad est sur le même Wi-Fi que le PC
- AltServer tourne dans la barre des tâches

Tu n'as rien à faire manuellement tant que ces conditions sont remplies.
Si l'app expire quand même : répète l'étape 6.

---

## Utilisation de l'app

### Accès Admin
5 taps rapides dans le coin supérieur droit de l'écran d'accueil.
PIN par défaut : **1234** (à changer dans Admin → Réglages)

### Avant un événement
1. Ouvre l'admin
2. Onglet "Événement" : configure nom, sous-titre, hashtag, mode capture
3. Onglet "Pré-vol" : vérifie batterie, réseau, imprimante
4. Ferme l'admin → l'app est prête

### Impression Canon SELPHY
- L'iPad et la SELPHY doivent être sur le même réseau Wi-Fi
- La SELPHY CP1300/CP1500 est compatible AirPrint nativement
- Si réseau mobile actif sur l'iPad : connecte l'iPad en Wi-Fi sur le réseau de la SELPHY pour imprimer

---

## Structure du code

```
Photobooth/
├── PhotoboothApp.swift          # Point d'entrée
├── DesignSystem.swift           # Couleurs, typo, animations (noir & or)
├── Models/
│   └── Models.swift             # Event, Session, Media, PrintJob...
├── ViewModels/
│   └── AppState.swift           # Navigation, état global, EventStore
├── Services/
│   ├── CameraService.swift      # AVFoundation, caméra avant
│   ├── ImageComposer.swift      # Composition bandes, grilles, GIF
│   ├── PrintService.swift       # AirPrint → Canon SELPHY
│   └── ShareService.swift       # QR code, WhatsApp, email, photos
└── Views/
    ├── RootView.swift            # Navigation entre écrans
    ├── WelcomeView.swift         # Écran d'accueil animé
    ├── CaptureView.swift         # Caméra + compte à rebours
    ├── PreviewView.swift         # Validation / retake
    ├── ConsentView.swift         # RGPD + galerie + infos invité
    ├── ShareView.swift           # QR + partage + retour auto
    ├── PrintView.swift           # Impression AirPrint
    └── AdminView.swift           # Admin PIN + config événement
```
