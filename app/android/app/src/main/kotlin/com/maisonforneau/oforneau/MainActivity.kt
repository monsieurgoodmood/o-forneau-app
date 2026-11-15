package com.maisonforneau.oforneau

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Un seul canal, nommé dans la langue du téléphone par Android lui-même côté réglages.
        // FCM y range toutes nos notifications (default_notification_channel_id du manifeste) ;
        // sans canal existant, Android les mettrait dans « Divers », que l'on ne peut pas régler.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = NotificationChannel("forneau", "Ô Forneau", NotificationManager.IMPORTANCE_DEFAULT)
            canal.description = "Idées de recettes, nouveautés et accès"
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(canal)
        }
    }
}
