package com.example.city_navigation

import android.app.Application
import com.yandex.mapkit.MapKitFactory
import java.util.Properties

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        val apiKey = readApiKeyFromAssets()
        MapKitFactory.setLocale("ru_RU")
        MapKitFactory.setApiKey(apiKey)
    }
    
    private fun readApiKeyFromAssets(): String {
        return try {
            val properties = Properties()
            assets.open("config.properties").use { input ->
                properties.load(input)
            }
            properties.getProperty("yandex.maps.api.key", "")
        } catch (e: Exception) {
            e.printStackTrace()
            "" // Возвращаем пустую строку в случае ошибки
        }
    }
}