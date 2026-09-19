-- Supabase Free Project Keep-Alive
--
-- Creates a harmless RPC function that executes SELECT 1.
-- This function does not modify application data.

create or replace function public.keep_alive()
returns integer
language sql
security definer
set search_path = ''
as $$
  select 1;
$$;

-- Do not grant general table access.
-- Only allow execution of this specific function.
revoke all on function public.keep_alive() from public;

grant execute on function public.keep_alive() to anon;
