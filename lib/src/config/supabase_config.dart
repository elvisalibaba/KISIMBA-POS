abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hzhyhujeygflvsluxjtc.supabase.co',
  );

  // A publishable key is intentionally safe to ship in a client application.
  // Database security must still be enforced by Row Level Security policies.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_CLfPU2UeDVH60Eu8EW7jGw_Cn3AJM0A',
  );
}
