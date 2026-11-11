import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration Supabase — projet o-forneau (UE / Frankfurt).
/// Clé anon PUBLIQUE (protégée par RLS `auth.uid()=id`), identique au web : sûre à embarquer.
class SupabaseConfig {
  SupabaseConfig._();
  static const url = 'https://kbxguxcfcsyhktjyeihu.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtieGd1eGNmY3N5aGt0anllaWh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxNjcyMzcsImV4cCI6MjEwOTc0MzIzN30.WlxWbBJis8GYtNeyrxN_FSjfNdYCThsw6C97OlgWrjU';
}

SupabaseClient get supabase => Supabase.instance.client;

Future<void> initSupabase() => Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
