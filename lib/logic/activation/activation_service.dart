// logic/activation/activation_service.dart
// ──────────────────────────────────────────────────────────────────────────────
// Service de gestion de la clé d'activation de l'application.
//
// Format attendu : XXXX-XXXX (8 caractères alphanum + tiret)
// Exemple : A9F2-K8L3
//
// La clé validée est stockée dans SharedPreferences pour ne pas re-demander
// à chaque lancement.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  static const String _keyActivated = 'app_activated';
  static const String _keyStoredKey = 'activation_key';

  // ── Liste des clés valides (hardcodées côté app) ───────────────────────────
  // Dans une vraie implémentation, on pourrait appeler un endpoint distant.
  // Pour une appli offline, on stocke les clés autorisées en dur.
  static const List<String> _validKeys = [
    'A9F2-K8L3',
    'TAL1-2026',
    'TAL2-2026',
    'TAL3-2026',
    'TAL4-2026',
    'TAL5-2026',
    'TAL6-2026',
    'TAL7-2026',
    'TAL8-2026',
    'TAL9-2026',
    'PRO1-2026',
    'PRO2-2026',
    'B2J8-M5N1',
    'C7P4-Q9R2',
    'D1H6-K3L8',
    'E5F9-G2H4',
    'F8J1-N6M3',
    'G3K7-P5R9',
    'H2L4-Q1N7',
    'J6M9-B3C5',
    'K4N1-D8F2',
    'L7R5-G9H1',
    'M2P3-K6J8',
    'N5Q8-F1D4',
    'P9B2-L7M6',
    'Q1H4-R3K9',
    'R6N7-C2B5',
    'T3K8-D5F1',
    'V9L2-M6N4',
    'W4P7-G1H3',
];

  // ── Vérifie si l'application est déjà activée ────────────────────────────
  static Future<bool> isActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyActivated) ?? false;
  }

  // ── Valide une clé et la sauvegarde si correcte ──────────────────────────
  // Retourne true si la clé est valide, false sinon.
  static Future<bool> activate(String key) async {
    final normalized = key.trim().toUpperCase();

    // Vérification du format XXXX-XXXX
    if (!_isValidFormat(normalized)) return false;

    // Vérification si la clé est dans la liste autorisée
    if (!_validKeys.contains(normalized)) return false;

    // Sauvegarde de l'activation
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyActivated, true);
    await prefs.setString(_keyStoredKey, normalized);
    return true;
  }

  // ── Vérifie le format XXXX-XXXX ──────────────────────────────────────────
  static bool _isValidFormat(String key) {
    // Regex : 4 caractères alphanumériques, tiret, 4 caractères alphanum
    final regex = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$');
    return regex.hasMatch(key);
  }

  // ── Retourne la clé enregistrée ──────────────────────────────────────────
  static Future<String?> getStoredKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStoredKey);
  }

  // ── Réinitialise l'activation (pour les tests ou reset factory) ──────────
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActivated);
    await prefs.remove(_keyStoredKey);
  }
}
