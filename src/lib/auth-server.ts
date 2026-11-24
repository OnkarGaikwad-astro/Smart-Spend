import { NextRequest } from 'next/server';
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { cookies } from 'next/headers';

export interface AuthVerificationResult {
  authenticated: boolean;
  user: any | null;
  error?: string;
}

/**
 * Verifies that the incoming request is from an authenticated user.
 * Supports both browser cookie sessions (@supabase/ssr) and Bearer authorization tokens.
 */
export async function verifyAuth(req: NextRequest): Promise<AuthVerificationResult> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseAnonKey) {
    // If env vars are not set, fail closed in production
    if (process.env.NODE_ENV === 'production') {
      return { authenticated: false, user: null, error: 'Database configuration missing' };
    }
    return { authenticated: true, user: null };
  }

  // 1. Check Bearer token in Authorization header (Mobile App / API clients)
  const authHeader = req.headers.get('authorization');
  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.substring(7).trim();
    if (token) {
      const { createClient } = await import('@supabase/supabase-js');
      const sb = createClient(supabaseUrl, supabaseAnonKey);
      const { data: { user }, error } = await sb.auth.getUser(token);
      if (!error && user) {
        return { authenticated: true, user };
      }
    }
  }

  // 2. Check Cookie session (Web app)
  try {
    const cookieStore = await cookies();
    const supabase = createServerClient(supabaseUrl, supabaseAnonKey, {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options });
          } catch {
            // Can occur in read-only route contexts
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.delete({ name, ...options });
          } catch {
            // Can occur in read-only route contexts
          }
        },
      },
    });

    const { data: { user }, error } = await supabase.auth.getUser();
    if (!error && user) {
      return { authenticated: true, user };
    }
  } catch (err: any) {
    return { authenticated: false, user: null, error: err.message };
  }

  return { authenticated: false, user: null, error: 'Unauthorized' };
}
