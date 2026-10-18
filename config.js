// Вставьте значения из Supabase → Project Settings → API.
// anon/publishable key можно использовать в браузере только вместе с RLS-политиками из supabase_setup.sql.
// Никогда не вставляйте сюда service_role key.
window.AEROFLOT_CONFIG = {
  url: "https://YOUR_PROJECT.supabase.co",
  anonKey: "YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY"
};
