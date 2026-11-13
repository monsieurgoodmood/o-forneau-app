import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
    Locale('pt')
  ];

  /// No description provided for @creerMonCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get creerMonCompte;

  /// No description provided for @jAiDejaUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'J’ai déjà un compte'**
  String get jAiDejaUnCompte;

  /// No description provided for @cuisinerAvecMonFrigo.
  ///
  /// In fr, this message translates to:
  /// **'Cuisiner avec mon frigo'**
  String get cuisinerAvecMonFrigo;

  /// No description provided for @oForneau.
  ///
  /// In fr, this message translates to:
  /// **'Ô FORNEAU !'**
  String get oForneau;

  /// No description provided for @monFoyer.
  ///
  /// In fr, this message translates to:
  /// **'Mon foyer'**
  String get monFoyer;

  /// No description provided for @activerMonAccesOffert.
  ///
  /// In fr, this message translates to:
  /// **'Activer mon accès offert'**
  String get activerMonAccesOffert;

  /// No description provided for @programmeNutritionnel.
  ///
  /// In fr, this message translates to:
  /// **'Programme nutritionnel'**
  String get programmeNutritionnel;

  /// No description provided for @listeDeCourses.
  ///
  /// In fr, this message translates to:
  /// **'Liste de courses'**
  String get listeDeCourses;

  /// No description provided for @monCompte.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get monCompte;

  /// No description provided for @mesCreateursPreferes.
  ///
  /// In fr, this message translates to:
  /// **'Mes créateurs préférés'**
  String get mesCreateursPreferes;

  /// No description provided for @parMaisonForneau1974.
  ///
  /// In fr, this message translates to:
  /// **'PAR MAISON FORNEAU · 1974'**
  String get parMaisonForneau1974;

  /// No description provided for @icAssistant.
  ///
  /// In fr, this message translates to:
  /// **'ic-assistant'**
  String get icAssistant;

  /// No description provided for @leProgrammeNutritionnel.
  ///
  /// In fr, this message translates to:
  /// **'Le programme nutritionnel'**
  String get leProgrammeNutritionnel;

  /// No description provided for @programme.
  ///
  /// In fr, this message translates to:
  /// **'Programme'**
  String get programme;

  /// No description provided for @proteines.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get proteines;

  /// No description provided for @jeVousEcoute.
  ///
  /// In fr, this message translates to:
  /// **'Je vous écoute'**
  String get jeVousEcoute;

  /// No description provided for @laListeDeCourses.
  ///
  /// In fr, this message translates to:
  /// **'La liste de courses'**
  String get laListeDeCourses;

  /// No description provided for @faisabilite.
  ///
  /// In fr, this message translates to:
  /// **'Faisabilité'**
  String get faisabilite;

  /// No description provided for @eMailD.
  ///
  /// In fr, this message translates to:
  /// **'e-mail d'**
  String get eMailD;

  /// No description provided for @eMailDuCompteC.
  ///
  /// In fr, this message translates to:
  /// **'e-mail du compte : c'**
  String get eMailDuCompteC;

  /// No description provided for @monAccesOffert.
  ///
  /// In fr, this message translates to:
  /// **'Mon accès offert'**
  String get monAccesOffert;

  /// No description provided for @dejaActive.
  ///
  /// In fr, this message translates to:
  /// **'Déjà activé'**
  String get dejaActive;

  /// No description provided for @chaqueNouvelleCommandeRepousseVotreAcces.
  ///
  /// In fr, this message translates to:
  /// **'Chaque nouvelle commande repousse votre accès.'**
  String get chaqueNouvelleCommandeRepousseVotreAcces;

  /// No description provided for @commencerACuisiner.
  ///
  /// In fr, this message translates to:
  /// **'Commencer à cuisiner'**
  String get commencerACuisiner;

  /// No description provided for @creezVotreCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte'**
  String get creezVotreCompte;

  /// No description provided for @vosMoisOffertsSontRattachesA.
  ///
  /// In fr, this message translates to:
  /// **'Vos mois offerts sont rattachés à un compte, pour vous suivre sur tous vos appareils.'**
  String get vosMoisOffertsSontRattachesA;

  /// No description provided for @jusquA12MoisOfferts.
  ///
  /// In fr, this message translates to:
  /// **'JUSQU’À 12 MOIS OFFERTS'**
  String get jusquA12MoisOfferts;

  /// No description provided for @saisissezVotreNumeroDeCommandeEt.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre numéro de commande et l’e-mail utilisé lors de l’achat. Les deux figurent sur votre e-mail de confirmation.'**
  String get saisissezVotreNumeroDeCommandeEt;

  /// No description provided for @ceQueVousObtenez.
  ///
  /// In fr, this message translates to:
  /// **'CE QUE VOUS OBTENEZ'**
  String get ceQueVousObtenez;

  /// No description provided for @touteCommandeDonneAuMoins1.
  ///
  /// In fr, this message translates to:
  /// **'Toute commande donne au moins 1 mois.'**
  String get touteCommandeDonneAuMoins1;

  /// No description provided for @numeroDeCommande.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de commande'**
  String get numeroDeCommande;

  /// No description provided for @eMailDeLaCommande.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de la commande'**
  String get eMailDeLaCommande;

  /// No description provided for @uneCommandeNActiveQuUn.
  ///
  /// In fr, this message translates to:
  /// **'Une commande n’active qu’un seul compte. Si vous avez plusieurs commandes, chacune repousse votre accès.'**
  String get uneCommandeNActiveQuUn;

  /// No description provided for @abonnementTroisVoiesDansCetOrdre.
  ///
  /// In fr, this message translates to:
  /// **'abonnement. Trois voies, dans cet ordre d'**
  String get abonnementTroisVoiesDansCetOrdre;

  /// No description provided for @oForneauPremium.
  ///
  /// In fr, this message translates to:
  /// **'Ô FORNEAU PREMIUM'**
  String get oForneauPremium;

  /// No description provided for @cuisinezAccompagne.
  ///
  /// In fr, this message translates to:
  /// **'Cuisinez accompagné'**
  String get cuisinezAccompagne;

  /// No description provided for @vousAvezCommandeChezForneau.
  ///
  /// In fr, this message translates to:
  /// **'VOUS AVEZ COMMANDÉ CHEZ FORNEAU ?'**
  String get vousAvezCommandeChezForneau;

  /// No description provided for @jusquA12MoisOfferts2.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à 12 mois offerts'**
  String get jusquA12MoisOfferts2;

  /// No description provided for @selonLeMontantDeVotreCommande.
  ///
  /// In fr, this message translates to:
  /// **'Selon le montant de votre commande : 1 mois pour toute commande, 3 mois dès 70 €, 6 mois dès 100 €, 12 mois dès 150 €. Renouvelés à chaque commande.'**
  String get selonLeMontantDeVotreCommande;

  /// No description provided for @jAiCommandeChezForneau.
  ///
  /// In fr, this message translates to:
  /// **'J’ai commandé chez Forneau'**
  String get jAiCommandeChezForneau;

  /// No description provided for @essayer1MoisGratuitement.
  ///
  /// In fr, this message translates to:
  /// **'Essayer 1 mois gratuitement'**
  String get essayer1MoisGratuitement;

  /// No description provided for @sansCarteBancaireRienNeSe.
  ///
  /// In fr, this message translates to:
  /// **'Sans carte bancaire. Rien ne se déclenche à la fin.'**
  String get sansCarteBancaireRienNeSe;

  /// No description provided for @sAbonner.
  ///
  /// In fr, this message translates to:
  /// **'S’ABONNER'**
  String get sAbonner;

  /// No description provided for @creezUnComptePourVousAbonner.
  ///
  /// In fr, this message translates to:
  /// **'Créez un compte pour vous abonner et retrouver votre accès sur tous vos appareils.'**
  String get creezUnComptePourVousAbonner;

  /// No description provided for @lAbonnementNEstPasEncore.
  ///
  /// In fr, this message translates to:
  /// **'L’abonnement n’est pas encore disponible sur cet appareil. Vous pouvez activer vos 12 mois offerts si vous avez commandé chez Forneau.'**
  String get lAbonnementNEstPasEncore;

  /// No description provided for @restaurerUnAchat.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer un achat'**
  String get restaurerUnAchat;

  /// No description provided for @sansEngagementResiliableAToutMoment.
  ///
  /// In fr, this message translates to:
  /// **'Sans engagement, résiliable à tout moment depuis votre compte Apple ou Google. La consultation des recettes reste toujours accessible.'**
  String get sansEngagementResiliableAToutMoment;

  /// No description provided for @modeCuisineVocal.
  ///
  /// In fr, this message translates to:
  /// **'Mode cuisine vocal'**
  String get modeCuisineVocal;

  /// No description provided for @passezLesEtapesALaVoix.
  ///
  /// In fr, this message translates to:
  /// **'Passez les étapes à la voix, les mains sales.'**
  String get passezLesEtapesALaVoix;

  /// No description provided for @vosBesoinsEtUnMenuDu.
  ///
  /// In fr, this message translates to:
  /// **'Vos besoins et un menu du jour pour tout le foyer.'**
  String get vosBesoinsEtUnMenuDu;

  /// No description provided for @lesRecettesFaisablesAvecCeQue.
  ///
  /// In fr, this message translates to:
  /// **'Les recettes faisables avec ce que vous avez.'**
  String get lesRecettesFaisablesAvecCeQue;

  /// No description provided for @lesIngredientsManquantsRassembles.
  ///
  /// In fr, this message translates to:
  /// **'Les ingrédients manquants, rassemblés.'**
  String get lesIngredientsManquantsRassembles;

  /// No description provided for @lePlusAvantageux.
  ///
  /// In fr, this message translates to:
  /// **'Le plus avantageux'**
  String get lePlusAvantageux;

  /// No description provided for @sansEngagement.
  ///
  /// In fr, this message translates to:
  /// **'Sans engagement'**
  String get sansEngagement;

  /// No description provided for @abonnementD.
  ///
  /// In fr, this message translates to:
  /// **'abonnement d'**
  String get abonnementD;

  /// No description provided for @assurerD.
  ///
  /// In fr, this message translates to:
  /// **'assurer d'**
  String get assurerD;

  /// No description provided for @entreeCompteConnecteOuInviteL.
  ///
  /// In fr, this message translates to:
  /// **'entrée : compte connecté OU invité → l'**
  String get entreeCompteConnecteOuInviteL;

  /// No description provided for @identiteRevenuecatSurLeCompteL.
  ///
  /// In fr, this message translates to:
  /// **'identité RevenueCat sur le compte : l'**
  String get identiteRevenuecatSurLeCompteL;

  /// No description provided for @estLuiQuiPermetAuWebhook.
  ///
  /// In fr, this message translates to:
  /// **'est lui qui permet au webhook de retrouver l'**
  String get estLuiQuiPermetAuWebhook;

  /// No description provided for @accesClientActif.
  ///
  /// In fr, this message translates to:
  /// **'Accès client actif'**
  String get accesClientActif;

  /// No description provided for @abonnementActif.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif'**
  String get abonnementActif;

  /// No description provided for @resiliableAToutMomentDepuisVotre.
  ///
  /// In fr, this message translates to:
  /// **'Résiliable à tout moment depuis votre compte Apple ou Google.'**
  String get resiliableAToutMomentDepuisVotre;

  /// No description provided for @essaiEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Essai en cours'**
  String get essaiEnCours;

  /// No description provided for @accesLimite.
  ///
  /// In fr, this message translates to:
  /// **'Accès limité'**
  String get accesLimite;

  /// No description provided for @vousPouvezParcourirToutesLesRecettes.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez parcourir toutes les recettes. Les fonctions premium demandent un accès.'**
  String get vousPouvezParcourirToutesLesRecettes;

  /// No description provided for @voirLesOptions.
  ///
  /// In fr, this message translates to:
  /// **'Voir les options'**
  String get voirLesOptions;

  /// No description provided for @votreAcces.
  ///
  /// In fr, this message translates to:
  /// **'VOTRE ACCÈS'**
  String get votreAcces;

  /// No description provided for @vousNaviguezEnInvite.
  ///
  /// In fr, this message translates to:
  /// **'Vous naviguez en invité'**
  String get vousNaviguezEnInvite;

  /// No description provided for @creezUnComptePourRetrouverVos.
  ///
  /// In fr, this message translates to:
  /// **'Créez un compte pour retrouver vos favoris, votre frigo, votre programme et vos avis sur tous vos appareils.'**
  String get creezUnComptePourRetrouverVos;

  /// No description provided for @votreProfil.
  ///
  /// In fr, this message translates to:
  /// **'VOTRE PROFIL'**
  String get votreProfil;

  /// No description provided for @vosFavorisVotreFrigoVotreListe.
  ///
  /// In fr, this message translates to:
  /// **'Vos favoris, votre frigo, votre liste de courses, votre programme et votre foyer sont synchronisés avec ce compte (données hébergées en Europe).'**
  String get vosFavorisVotreFrigoVotreListe;

  /// No description provided for @meDeconnecter.
  ///
  /// In fr, this message translates to:
  /// **'Me déconnecter'**
  String get meDeconnecter;

  /// No description provided for @supprimerMonCompteEtMesDonnees.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte et mes données'**
  String get supprimerMonCompteEtMesDonnees;

  /// No description provided for @politiqueDeConfidentialite.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get politiqueDeConfidentialite;

  /// No description provided for @votrePrenomEstRequis.
  ///
  /// In fr, this message translates to:
  /// **'Votre prénom est requis.'**
  String get votrePrenomEstRequis;

  /// No description provided for @compteCreeVerifiezVosEMails.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé. Vérifiez vos e-mails si une confirmation est demandée, puis connectez-vous.'**
  String get compteCreeVerifiezVosEMails;

  /// No description provided for @invalidLogin.
  ///
  /// In fr, this message translates to:
  /// **'Invalid login'**
  String get invalidLogin;

  /// No description provided for @eMailOuMotDePasse.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect.'**
  String get eMailOuMotDePasse;

  /// No description provided for @alreadyRegistered.
  ///
  /// In fr, this message translates to:
  /// **'already registered'**
  String get alreadyRegistered;

  /// No description provided for @unCompteExisteDejaAvecCet.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet e-mail.'**
  String get unCompteExisteDejaAvecCet;

  /// No description provided for @passwordShould.
  ///
  /// In fr, this message translates to:
  /// **'Password should'**
  String get passwordShould;

  /// No description provided for @motDePasseTropCourt6.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop court (6 caractères minimum).'**
  String get motDePasseTropCourt6;

  /// No description provided for @uneErreurEstSurvenueReessayez.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get uneErreurEstSurvenueReessayez;

  /// No description provided for @connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get connexion;

  /// No description provided for @nomFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Nom (facultatif)'**
  String get nomFacultatif;

  /// No description provided for @motDePasse.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get motDePasse;

  /// No description provided for @telephoneFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (facultatif)'**
  String get telephoneFacultatif;

  /// No description provided for @jeSouhaiteRecevoirLesRecettesEt.
  ///
  /// In fr, this message translates to:
  /// **'Je souhaite recevoir les recettes et nouveautés par e-mail.'**
  String get jeSouhaiteRecevoirLesRecettesEt;

  /// No description provided for @seConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get seConnecter;

  /// No description provided for @creerUnCompte.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get creerUnCompte;

  /// No description provided for @creezVotreCompte2.
  ///
  /// In fr, this message translates to:
  /// **'CRÉEZ VOTRE COMPTE'**
  String get creezVotreCompte2;

  /// No description provided for @unCompteEtOnCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Un compte, et on cuisine'**
  String get unCompteEtOnCuisine;

  /// No description provided for @parcourirLesRecettesResteraToujoursLibre.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir les recettes restera toujours libre. Le compte sert à garder ce qui vous appartient : vos portions, votre foyer, vos favoris, votre accès.'**
  String get parcourirLesRecettesResteraToujoursLibre;

  /// No description provided for @gratuitEnTrenteSecondesVosDonnees.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit, en trente secondes. Vos données restent en Europe.'**
  String get gratuitEnTrenteSecondesVosDonnees;

  /// No description provided for @surTousVosAppareils.
  ///
  /// In fr, this message translates to:
  /// **'Sur tous vos appareils'**
  String get surTousVosAppareils;

  /// No description provided for @vosFavorisEtVosReglagesVous.
  ///
  /// In fr, this message translates to:
  /// **'Vos favoris et vos réglages vous suivent.'**
  String get vosFavorisEtVosReglagesVous;

  /// No description provided for @vosMoisOfferts.
  ///
  /// In fr, this message translates to:
  /// **'Vos mois offerts'**
  String get vosMoisOfferts;

  /// No description provided for @uneCommandeForneauOuvreLApp.
  ///
  /// In fr, this message translates to:
  /// **'Une commande Forneau ouvre l’app, jusqu’à 12 mois.'**
  String get uneCommandeForneauOuvreLApp;

  /// No description provided for @adapteAVotreFoyer.
  ///
  /// In fr, this message translates to:
  /// **'Adapté à votre foyer'**
  String get adapteAVotreFoyer;

  /// No description provided for @lesQuantitesEtLaNutritionSuivent.
  ///
  /// In fr, this message translates to:
  /// **'Les quantités et la nutrition suivent qui mange.'**
  String get lesQuantitesEtLaNutritionSuivent;

  /// No description provided for @creezUnComptePourRetrouverVos2.
  ///
  /// In fr, this message translates to:
  /// **'Créez un compte pour retrouver vos favoris, vos réglages et vos recettes sur tous vos appareils.'**
  String get creezUnComptePourRetrouverVos2;

  /// No description provided for @continuerSansCompte.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans compte'**
  String get continuerSansCompte;

  /// No description provided for @cEstNoteOnRegardeCe.
  ///
  /// In fr, this message translates to:
  /// **'C’est noté. On regarde ce compte.'**
  String get cEstNoteOnRegardeCe;

  /// No description provided for @mesCreateurs.
  ///
  /// In fr, this message translates to:
  /// **'Mes créateurs'**
  String get mesCreateurs;

  /// No description provided for @vosComptesPreferes.
  ///
  /// In fr, this message translates to:
  /// **'VOS COMPTES PRÉFÉRÉS'**
  String get vosComptesPreferes;

  /// No description provided for @quelsCreateursVoulezVousRetrouver.
  ///
  /// In fr, this message translates to:
  /// **'Quels créateurs voulez-vous retrouver ?'**
  String get quelsCreateursVoulezVousRetrouver;

  /// No description provided for @collezLeLienDeSonProfil.
  ///
  /// In fr, this message translates to:
  /// **'Collez le lien de son profil Instagram ou TikTok, ou tapez simplement son pseudo. Plus un compte est demandé, plus vite on s’en occupe.'**
  String get collezLeLienDeSonProfil;

  /// No description provided for @lienDuProfilOuPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Lien du profil ou pseudo'**
  String get lienDuProfilOuPseudo;

  /// No description provided for @instagramComSoncompteOuSoncompte.
  ///
  /// In fr, this message translates to:
  /// **'instagram.com/soncompte  ou  @soncompte'**
  String get instagramComSoncompteOuSoncompte;

  /// No description provided for @tiktokComSoncompteOuSoncompte.
  ///
  /// In fr, this message translates to:
  /// **'tiktok.com/@soncompte  ou  @soncompte'**
  String get tiktokComSoncompteOuSoncompte;

  /// No description provided for @proposerCeCreateur.
  ///
  /// In fr, this message translates to:
  /// **'Proposer ce créateur'**
  String get proposerCeCreateur;

  /// No description provided for @vosPropositions.
  ///
  /// In fr, this message translates to:
  /// **'VOS PROPOSITIONS'**
  String get vosPropositions;

  /// No description provided for @listeIndisponiblePourLeMoment.
  ///
  /// In fr, this message translates to:
  /// **'Liste indisponible pour le moment.'**
  String get listeIndisponiblePourLeMoment;

  /// No description provided for @vousNAvezEncoreProposePersonne.
  ///
  /// In fr, this message translates to:
  /// **'Vous n’avez encore proposé personne.'**
  String get vousNAvezEncoreProposePersonne;

  /// No description provided for @lesRecettesSontToujoursReecritesPar.
  ///
  /// In fr, this message translates to:
  /// **'Les recettes sont toujours réécrites par nos soins, avec nos propres photos. Nous ne reprenons ni les textes ni les images des créateurs.'**
  String get lesRecettesSontToujoursReecritesPar;

  /// No description provided for @decocherTout.
  ///
  /// In fr, this message translates to:
  /// **'Décocher tout'**
  String get decocherTout;

  /// No description provided for @listeVide.
  ///
  /// In fr, this message translates to:
  /// **'Liste vide'**
  String get listeVide;

  /// No description provided for @aAcheter.
  ///
  /// In fr, this message translates to:
  /// **'À ACHETER'**
  String get aAcheter;

  /// No description provided for @monFrigo.
  ///
  /// In fr, this message translates to:
  /// **'Mon frigo'**
  String get monFrigo;

  /// No description provided for @cuisinerAvecMonFrigo2.
  ///
  /// In fr, this message translates to:
  /// **'CUISINER AVEC MON FRIGO'**
  String get cuisinerAvecMonFrigo2;

  /// No description provided for @estCeQueJ.
  ///
  /// In fr, this message translates to:
  /// **'est-ce que j'**
  String get estCeQueJ;

  /// No description provided for @ajoutezVosIngredientsOnClasseLes.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos ingrédients : on classe les recettes par ce que vous avez déjà.'**
  String get ajoutezVosIngredientsOnClasseLes;

  /// No description provided for @unIngredientExTomate.
  ///
  /// In fr, this message translates to:
  /// **'Un ingrédient (ex. tomate)…'**
  String get unIngredientExTomate;

  /// No description provided for @suggestions.
  ///
  /// In fr, this message translates to:
  /// **'SUGGESTIONS'**
  String get suggestions;

  /// No description provided for @toutEstLa.
  ///
  /// In fr, this message translates to:
  /// **'Tout est là'**
  String get toutEstLa;

  /// No description provided for @petitDej.
  ///
  /// In fr, this message translates to:
  /// **'petit-dej'**
  String get petitDej;

  /// No description provided for @pourBienDemarrerLaJournee.
  ///
  /// In fr, this message translates to:
  /// **'Pour bien démarrer la journée'**
  String get pourBienDemarrerLaJournee;

  /// No description provided for @desIdeesPourLeDejeuner.
  ///
  /// In fr, this message translates to:
  /// **'Des idées pour le déjeuner'**
  String get desIdeesPourLeDejeuner;

  /// No description provided for @unePauseGourmande.
  ///
  /// In fr, this message translates to:
  /// **'Une pause gourmande ?'**
  String get unePauseGourmande;

  /// No description provided for @desIdeesPourCeSoir.
  ///
  /// In fr, this message translates to:
  /// **'Des idées pour ce soir'**
  String get desIdeesPourCeSoir;

  /// No description provided for @unPetitCreux.
  ///
  /// In fr, this message translates to:
  /// **'Un petit creux ?'**
  String get unPetitCreux;

  /// No description provided for @bienMangerSimplement.
  ///
  /// In fr, this message translates to:
  /// **'Bien manger, simplement'**
  String get bienMangerSimplement;

  /// No description provided for @parMaisonForneau.
  ///
  /// In fr, this message translates to:
  /// **'par Maison Forneau'**
  String get parMaisonForneau;

  /// No description provided for @desRecettesAuTitaneAdapteesA.
  ///
  /// In fr, this message translates to:
  /// **'Des recettes au titane, adaptées à votre régime, votre appareil et votre temps. Par où commencer ?'**
  String get desRecettesAuTitaneAdapteesA;

  /// No description provided for @trouverUneRecette.
  ///
  /// In fr, this message translates to:
  /// **'Trouver une recette'**
  String get trouverUneRecette;

  /// No description provided for @toutesLesRecettesFiltreesCommeVous.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les recettes, filtrées comme vous voulez.'**
  String get toutesLesRecettesFiltreesCommeVous;

  /// No description provided for @icProgramme.
  ///
  /// In fr, this message translates to:
  /// **'ic-programme'**
  String get icProgramme;

  /// No description provided for @monProgrammeNutritionnel.
  ///
  /// In fr, this message translates to:
  /// **'Mon programme nutritionnel'**
  String get monProgrammeNutritionnel;

  /// No description provided for @unObjectifUneJourneeDeRepas.
  ///
  /// In fr, this message translates to:
  /// **'Un objectif, une journée de repas équilibrée.'**
  String get unObjectifUneJourneeDeRepas;

  /// No description provided for @icFoyer.
  ///
  /// In fr, this message translates to:
  /// **'ic-foyer'**
  String get icFoyer;

  /// No description provided for @pourQuiJeCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Pour qui je cuisine ?'**
  String get pourQuiJeCuisine;

  /// No description provided for @soloOuFamilleQuantitesEtNutrition.
  ///
  /// In fr, this message translates to:
  /// **'Solo ou famille — quantités et nutrition adaptées.'**
  String get soloOuFamilleQuantitesEtNutrition;

  /// No description provided for @icFrigo.
  ///
  /// In fr, this message translates to:
  /// **'ic-frigo'**
  String get icFrigo;

  /// No description provided for @ceQueVousPouvezFaireAvec.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous pouvez faire, avec ce que vous avez.'**
  String get ceQueVousPouvezFaireAvec;

  /// No description provided for @ditesNousQuiSuivreOnVa.
  ///
  /// In fr, this message translates to:
  /// **'Dites-nous qui suivre, on va chercher leurs recettes.'**
  String get ditesNousQuiSuivreOnVa;

  /// No description provided for @proposerUnCreateur.
  ///
  /// In fr, this message translates to:
  /// **'Proposer un créateur'**
  String get proposerUnCreateur;

  /// No description provided for @pourQuiCuisinezVous.
  ///
  /// In fr, this message translates to:
  /// **'Pour qui cuisinez-vous ?'**
  String get pourQuiCuisinezVous;

  /// No description provided for @onAdapteLesQuantitesDesRecettes.
  ///
  /// In fr, this message translates to:
  /// **'On adapte les quantités des recettes, et si vous le souhaitez les valeurs nutritionnelles, à votre foyer. Tout est optionnel : commencez simple.'**
  String get onAdapteLesQuantitesDesRecettes;

  /// No description provided for @jeCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Je cuisine…'**
  String get jeCuisine;

  /// No description provided for @justePourMoi.
  ///
  /// In fr, this message translates to:
  /// **'Juste pour moi'**
  String get justePourMoi;

  /// No description provided for @pourPlusieurs.
  ///
  /// In fr, this message translates to:
  /// **'Pour plusieurs'**
  String get pourPlusieurs;

  /// No description provided for @combienDePersonnes.
  ///
  /// In fr, this message translates to:
  /// **'Combien de personnes ?'**
  String get combienDePersonnes;

  /// No description provided for @affinerLaNutrition.
  ///
  /// In fr, this message translates to:
  /// **'Affiner la nutrition '**
  String get affinerLaNutrition;

  /// No description provided for @renseignezAgeTaillePoidsActiviteEt.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez âge, taille, poids, activité et régime — on calcule les besoins de chacun et le menu du jour convient à tous.'**
  String get renseignezAgeTaillePoidsActiviteEt;

  /// No description provided for @votreProgrammeSurMesure.
  ///
  /// In fr, this message translates to:
  /// **'Votre programme sur mesure'**
  String get votreProgrammeSurMesure;

  /// No description provided for @renseignezVotreProfilEtVotreObjectif.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez votre profil et votre objectif : on calcule vos besoins et on compose une journée adaptée. Estimation indicative, pas un avis médical.'**
  String get renseignezVotreProfilEtVotreObjectif;

  /// No description provided for @votreProfil2.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil'**
  String get votreProfil2;

  /// No description provided for @renseignezTailleEtPoidsPourUn.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez taille et poids pour un calcul personnalisé.'**
  String get renseignezTailleEtPoidsPourUn;

  /// No description provided for @votreObjectif.
  ///
  /// In fr, this message translates to:
  /// **'Votre objectif'**
  String get votreObjectif;

  /// No description provided for @vosBesoins.
  ///
  /// In fr, this message translates to:
  /// **'Vos besoins'**
  String get vosBesoins;

  /// No description provided for @bonsGras.
  ///
  /// In fr, this message translates to:
  /// **'bons gras'**
  String get bonsGras;

  /// No description provided for @menuDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Menu du jour'**
  String get menuDuJour;

  /// No description provided for @autreMenu.
  ///
  /// In fr, this message translates to:
  /// **'Autre menu'**
  String get autreMenu;

  /// No description provided for @ajouterUnGouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un goûter'**
  String get ajouterUnGouter;

  /// No description provided for @renseignezTailleEtPoidsPourUne.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez taille et poids pour une cible personnelle.'**
  String get renseignezTailleEtPoidsPourUne;

  /// No description provided for @microIndisponibleAutorisezLeDansLes.
  ///
  /// In fr, this message translates to:
  /// **'Micro indisponible. Autorisez-le dans les réglages.'**
  String get microIndisponibleAutorisezLeDansLes;

  /// No description provided for @modeVocalActiveDitesEtapeSuivante.
  ///
  /// In fr, this message translates to:
  /// **'Mode vocal activé. Dites : étape suivante, précédent, répète, minuteur, ou terminé.'**
  String get modeVocalActiveDitesEtapeSuivante;

  /// No description provided for @pasDeMinuteurPourCetteEtape.
  ///
  /// In fr, this message translates to:
  /// **'Pas de minuteur pour cette étape.'**
  String get pasDeMinuteurPourCetteEtape;

  /// No description provided for @minuteurEnPause.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur en pause.'**
  String get minuteurEnPause;

  /// No description provided for @minuteurRepris.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur repris.'**
  String get minuteurRepris;

  /// No description provided for @minuteurArrete.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur arrêté.'**
  String get minuteurArrete;

  /// No description provided for @bonAppetit.
  ///
  /// In fr, this message translates to:
  /// **'Bon appétit.'**
  String get bonAppetit;

  /// No description provided for @cEtaitLaDerniereEtapeBon.
  ///
  /// In fr, this message translates to:
  /// **'C’était la dernière étape. Bon appétit.'**
  String get cEtaitLaDerniereEtapeBon;

  /// No description provided for @minuteurTermine.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur terminé.'**
  String get minuteurTermine;

  /// No description provided for @desactiverLeVocal.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver le vocal'**
  String get desactiverLeVocal;

  /// No description provided for @activerLeVocal.
  ///
  /// In fr, this message translates to:
  /// **'Activer le vocal'**
  String get activerLeVocal;

  /// No description provided for @relancerLeMinuteur.
  ///
  /// In fr, this message translates to:
  /// **'Relancer le minuteur'**
  String get relancerLeMinuteur;

  /// No description provided for @reprendreLeMinuteur.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre le minuteur'**
  String get reprendreLeMinuteur;

  /// No description provided for @mettreLeMinuteurEnPause.
  ///
  /// In fr, this message translates to:
  /// **'Mettre le minuteur en pause'**
  String get mettreLeMinuteurEnPause;

  /// No description provided for @arreterLeMinuteur.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le minuteur'**
  String get arreterLeMinuteur;

  /// No description provided for @precedent.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get precedent;

  /// No description provided for @etapeSuivante.
  ///
  /// In fr, this message translates to:
  /// **'Étape suivante'**
  String get etapeSuivante;

  /// No description provided for @mesFavoris.
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get mesFavoris;

  /// No description provided for @aucunFavoriPourLInstant.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori pour l’instant'**
  String get aucunFavoriPourLInstant;

  /// No description provided for @touchezLeCUrSurUne.
  ///
  /// In fr, this message translates to:
  /// **'Touchez le cœur sur une recette pour la retrouver ici.'**
  String get touchezLeCUrSurUne;

  /// No description provided for @etapeSuivantePuisEnRevenantLe.
  ///
  /// In fr, this message translates to:
  /// **'étape suivante puis en revenant, le décompte repartait de zéro : quelqu'**
  String get etapeSuivantePuisEnRevenantLe;

  /// No description provided for @origineDesQu.
  ///
  /// In fr, this message translates to:
  /// **'origine des qu'**
  String get origineDesQu;

  /// No description provided for @ingredients.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get ingredients;

  /// No description provided for @preparation.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get preparation;

  /// No description provided for @valeursParPortion.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs par portion'**
  String get valeursParPortion;

  /// No description provided for @recetteRepereeDansLesTendancesCulinaires.
  ///
  /// In fr, this message translates to:
  /// **'Recette repérée dans les tendances culinaires, puis réécrite par Maison Forneau : nos mots, nos quantités, nos photos. Les temps et les proportions sont adaptés à la cuisson en poêle titane.'**
  String get recetteRepereeDansLesTendancesCulinaires;

  /// No description provided for @ustensileForneau.
  ///
  /// In fr, this message translates to:
  /// **'USTENSILE FORNEAU'**
  String get ustensileForneau;

  /// No description provided for @voirLeProduit.
  ///
  /// In fr, this message translates to:
  /// **'Voir le produit'**
  String get voirLeProduit;

  /// No description provided for @leModeCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Le mode cuisine'**
  String get leModeCuisine;

  /// No description provided for @modeCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Mode cuisine'**
  String get modeCuisine;

  /// No description provided for @lesRecettes.
  ///
  /// In fr, this message translates to:
  /// **'Les recettes'**
  String get lesRecettes;

  /// No description provided for @aucuneRecetteNeCorrespond.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette ne correspond.'**
  String get aucuneRecetteNeCorrespond;

  /// No description provided for @rechercherUneRecetteUnIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une recette, un ingrédient…'**
  String get rechercherUneRecetteUnIngredient;

  /// No description provided for @exclureUnAllergene.
  ///
  /// In fr, this message translates to:
  /// **'Exclure un allergène'**
  String get exclureUnAllergene;

  /// No description provided for @lesAllergenesSontDeduitsDesIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Les allergènes sont déduits des ingrédients. Une recette est écartée même en cas de doute. Nous ne connaissons pas les traces de fabrication : vérifiez toujours les étiquettes de vos produits.'**
  String get lesAllergenesSontDeduitsDesIngredients;

  /// No description provided for @mieuxNotees.
  ///
  /// In fr, this message translates to:
  /// **'Mieux notées'**
  String get mieuxNotees;

  /// No description provided for @toutEffacer.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get toutEffacer;

  /// No description provided for @voirLesRecettes.
  ///
  /// In fr, this message translates to:
  /// **'Voir les recettes'**
  String get voirLesRecettes;

  /// No description provided for @soyezLePremierANoter.
  ///
  /// In fr, this message translates to:
  /// **'Soyez le premier à noter'**
  String get soyezLePremierANoter;

  /// No description provided for @notezCetteRecetteLaissezUnCommentaire.
  ///
  /// In fr, this message translates to:
  /// **'Notez cette recette, laissez un commentaire et partagez la photo de votre plat.'**
  String get notezCetteRecetteLaissezUnCommentaire;

  /// No description provided for @creerMonCompteOuMeConnecter.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte ou me connecter'**
  String get creerMonCompteOuMeConnecter;

  /// No description provided for @merciVotreAvisEstPublie.
  ///
  /// In fr, this message translates to:
  /// **'Merci, votre avis est publié.'**
  String get merciVotreAvisEstPublie;

  /// No description provided for @publicationImpossibleReessayez.
  ///
  /// In fr, this message translates to:
  /// **'Publication impossible. Réessayez.'**
  String get publicationImpossibleReessayez;

  /// No description provided for @votreAvis.
  ///
  /// In fr, this message translates to:
  /// **'VOTRE AVIS'**
  String get votreAvis;

  /// No description provided for @unCommentaireFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Un commentaire ? (facultatif)'**
  String get unCommentaireFacultatif;

  /// No description provided for @publierMonAvis.
  ///
  /// In fr, this message translates to:
  /// **'Publier mon avis'**
  String get publierMonAvis;

  /// No description provided for @lesPlatsDeLaCommunaute.
  ///
  /// In fr, this message translates to:
  /// **'LES PLATS DE LA COMMUNAUTÉ'**
  String get lesPlatsDeLaCommunaute;

  /// No description provided for @touchezUnePhotoPourLAgrandir.
  ///
  /// In fr, this message translates to:
  /// **'Touchez une photo pour l’agrandir.'**
  String get touchezUnePhotoPourLAgrandir;

  /// No description provided for @supprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get supprimer;

  /// No description provided for @photoSignaleeMerci.
  ///
  /// In fr, this message translates to:
  /// **'Photo signalée. Merci.'**
  String get photoSignaleeMerci;

  /// No description provided for @commentaires.
  ///
  /// In fr, this message translates to:
  /// **'COMMENTAIRES'**
  String get commentaires;

  /// No description provided for @unGourmand.
  ///
  /// In fr, this message translates to:
  /// **'Un gourmand'**
  String get unGourmand;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'nl',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return LDe();
    case 'en':
      return LEn();
    case 'es':
      return LEs();
    case 'fr':
      return LFr();
    case 'it':
      return LIt();
    case 'nl':
      return LNl();
    case 'pt':
      return LPt();
  }

  throw FlutterError(
      'L.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
