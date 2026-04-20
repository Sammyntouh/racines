// ═══════════════════════════════════════════════════════════
// racines-config.js — Configuration Supabase RACINES
//
// INSTRUCTIONS :
// 1. Allez sur https://supabase.com → Votre projet → Settings → API
// 2. Copiez "Project URL" et collez-le dans SUPABASE_URL
// 3. Copiez "anon public" et collez-le dans SUPABASE_KEY
// 4. Ajoutez ce script dans vos pages AVANT les autres scripts :
//    <script src="racines-config.js"></script>
// ═══════════════════════════════════════════════════════════

const RACINES_CONFIG = {
  SUPABASE_URL: 'https://dpwgrdqbwpyepxovijhl.supabase.co',   // ex: https://abcdefgh.supabase.co
  SUPABASE_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwd2dyZHFid3B5ZXB4b3ZpamhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MzE5NjgsImV4cCI6MjA5MjIwNzk2OH0.s2bDpK4gqZL6eW0QVqjP3h6VcfbzUZkPI8aZd_TU9D8', // ex: eyJhbGciOiJIUzI1NiIsInR5cCI...
};

// ─── Initialisation automatique de Supabase ───────────────
// (nécessite @supabase/supabase-js chargé avant ce script)
let racinesDB;
if(typeof supabase !== 'undefined') {
  racinesDB = supabase.createClient(RACINES_CONFIG.SUPABASE_URL, RACINES_CONFIG.SUPABASE_KEY);
}
