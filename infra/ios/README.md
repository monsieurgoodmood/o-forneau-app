# iOS — Ô Forneau !

Apple refuse les builds hors macOS et exige un compte **Apple Developer** (99 $/an). Deux voies :

## A. Sans Mac — Codemagic (recommandé)
1. Pousser le repo sur un Git accessible à Codemagic.
2. Dans Codemagic : connecter **App Store Connect** (clé API) et créer le groupe de variables
   `forneau_ios`.
3. Utiliser `infra/ios/codemagic.yaml` (déjà prêt) → il génère le wrapper Capacitor, récupère les
   certificats, builde l'IPA et l'envoie sur **TestFlight**. (Pas de soumission App Store automatique :
   validation humaine, règle §2.6.)

## B. Avec un Mac
```bash
cd infra/ios && ./setup-capacitor.sh         # crée app/ios/App/App.xcworkspace
open app/ios/App/App.xcworkspace             # Xcode
```
Dans Xcode : équipe de signature, bundle id `com.maisonforneau.oforneau`, icône 1024
(`web/store/icon-1024.png`), écran de lancement. Archiver → App Store Connect → TestFlight → soumettre.

## Points de revue Apple à préparer
- `PrivacyInfo.xcprivacy` : **injecté par setup-capacitor.sh** — déclare la collecte réelle (e-mail,
  nom, téléphone, photos, contenu utilisateur), finalité *App Functionality*, **aucun tracking**.
- **App Privacy (ASC)** : l'app **collecte des données** (compte client optionnel + photos d'avis).
  Déclarer, comme sur Google Play : e-mail, nom, téléphone (facultatif), photos, contenu utilisateur —
  liés à l'utilisateur, non utilisés pour le suivi. Lien de confidentialité :
  `https://app.forneau.com/legal/privacy.html`. Suppression de compte : in-app + `…/legal/suppression.html`.
- **Autorisations** : `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` (photo du plat) —
  injectées par setup-capacitor.sh.
- **Pas de reconnaissance vocale sur iOS** (WKWebView ne la fournit pas) : le mode cuisine vocal se
  désactive proprement ; ne rien promettre de vocal sur la fiche iOS.
- **Règle 4.2 « minimum functionality »** : dans la note de revue, insister sur le hors-ligne embarqué,
  le programme nutritionnel personnalisé, le mode cuisine anti-veille + minuteurs, les avis/photos de
  la communauté, les comptes — c'est une vraie app, pas un simple signet web.

Le wrapper **embarque** la PWA (`web/` copié dans `www/`) pour fonctionner hors-ligne ; les appels réseau
(Supabase UE pour comptes/avis) partent à la demande.
