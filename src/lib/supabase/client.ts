import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  // Use fake urls if env vars are missing so the app doesn't crash during UI development
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://fake-project.supabase.co'
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'fake-anon-key'

  return createBrowserClient(
    supabaseUrl,
    supabaseAnonKey
  )
}
