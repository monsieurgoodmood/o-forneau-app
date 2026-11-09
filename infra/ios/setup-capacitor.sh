#!/usr/bin/env bash
# Crée un wrapper iOS (Capacitor) autour de la PWA web/, prêt pour l'App Store.
# Node requis ; le build Xcode final se fait sur macOS ou via Codemagic (infra/ios/codemagic.yaml).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
APP="$HERE/app"

rm -rf "$APP" && mkdir -p "$APP"
cd "$APP"
npm init -y >/dev/null
npm i @capacitor/core @capacitor/cli @capacitor/ios --registry=https://registry.npmjs.org

# Les assets web servis par l'app = contenu de la PWA (embarqués → hors-ligne, meilleur pour la revue Apple).
# Build local (Mac) : copie web/ local. Build CI (dépôt sans web/) : clone le site déjà déployé.
mkdir -p www
if [ -d "$ROOT/web" ]; then
  cp -r "$ROOT/web/." www/
else
  git clone --depth 1 https://github.com/monsieurgoodmood/o-forneau-web.git /tmp/ofweb
  cp -r /tmp/ofweb/. www/
fi
rm -rf www/.git www/CNAME www/.well-known www/.nojekyll www/preflight.js 2>/dev/null || true

npx cap init "Ô Forneau !" "com.maisonforneau.oforneau" --web-dir=www
npx cap add ios
npx cap sync ios

# ---- Info.plist : autorisations nécessaires au partage de photo du plat (input file/caméra) ----
PLIST="$APP/ios/App/App/Info.plist"
if [ -f "$PLIST" ]; then
  /usr/libexec/PlistBuddy -c "Add :NSCameraUsageDescription string 'Pour prendre en photo votre plat et l’ajouter à votre avis sur une recette.'" "$PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :NSCameraUsageDescription 'Pour prendre en photo votre plat et l’ajouter à votre avis sur une recette.'" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :NSPhotoLibraryUsageDescription string 'Pour choisir une photo de votre plat à joindre à votre avis.'" "$PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :NSPhotoLibraryUsageDescription 'Pour choisir une photo de votre plat à joindre à votre avis.'" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :NSPhotoLibraryAddUsageDescription string 'Pour enregistrer une photo si vous le souhaitez.'" "$PLIST" 2>/dev/null || true
fi

# ---- Privacy manifest (Apple l'exige) : on déclare ce qu'on collecte VRAIMENT (comptes + photos) ----
PRIV="$APP/ios/App/App/PrivacyInfo.xcprivacy"
cat > "$PRIV" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict><key>NSPrivacyCollectedDataType</key><string>NSPrivacyCollectedDataTypeEmailAddress</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/><key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key><array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array></dict>
    <dict><key>NSPrivacyCollectedDataType</key><string>NSPrivacyCollectedDataTypeName</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/><key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key><array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array></dict>
    <dict><key>NSPrivacyCollectedDataType</key><string>NSPrivacyCollectedDataTypePhoneNumber</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/><key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key><array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array></dict>
    <dict><key>NSPrivacyCollectedDataType</key><string>NSPrivacyCollectedDataTypePhotosorVideos</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/><key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key><array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array></dict>
    <dict><key>NSPrivacyCollectedDataType</key><string>NSPrivacyCollectedDataTypeOtherUserContent</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/><key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key><array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array></dict>
  </array>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict><key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key><array><string>CA92.1</string></array></dict>
  </array>
</dict>
</plist>
XML

# ---- Icône App Store 1024 (si présente) ----
ICON="$ROOT/web/store/icon-1024.png"
ASSET="$APP/ios/App/App/Assets.xcassets/AppIcon.appiconset"
if [ -f "$ICON" ] && [ -d "$ASSET" ]; then cp "$ICON" "$ASSET/AppIcon-512@2x.png" 2>/dev/null || true; fi

echo
echo "Projet iOS prêt : $APP/ios/App/App.xcworkspace"
echo "Info.plist (autorisations photo) + PrivacyInfo.xcprivacy (collecte déclarée) injectés."
echo "Build via Codemagic (infra/ios/codemagic.yaml) ou Xcode (macOS)."
