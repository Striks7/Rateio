-- Rateio da Fatura: tabela e regras do banco de dados (Supabase).
-- Como usar: no painel do Supabase, abra "SQL Editor", cole este arquivo inteiro e clique em "Run".
-- Pode rodar de novo quando quiser: nada é apagado.

-- 1) Os dados de cada conta (pessoas e faturas) ficam numa linha só, em JSON.
create table if not exists public.rateio (
  user_id    uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  dados      jsonb not null,
  atualizado timestamptz not null default now()
);

-- 2) Cada conta só enxerga e altera a própria linha. Sem login, ninguém vê nada.
alter table public.rateio enable row level security;

drop policy if exists "dono le" on public.rateio;
create policy "dono le" on public.rateio
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "dono cria" on public.rateio;
create policy "dono cria" on public.rateio
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "dono altera" on public.rateio;
create policy "dono altera" on public.rateio
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- 3) Lista de contas (tela "Contas"): o dono do sistema vê todas; os outros, só a própria.
create or replace function public.listar_contas()
returns table (id uuid, email text, nome text, confirmada boolean, criada timestamptz)
language sql stable security definer set search_path = '' as $$
  select u.id, u.email::text, coalesce(u.raw_user_meta_data ->> 'name', u.email)::text,
         u.email_confirmed_at is not null, u.created_at
    from auth.users u
   where u.id = auth.uid()
      or coalesce(auth.jwt() ->> 'email', '') = 'nicolasrenan10@gmail.com'
   order by 3;
$$;

-- 4) Excluir conta: cada um pode excluir a própria; o dono do sistema pode excluir qualquer uma.
--    Apagar a conta apaga também os dados dela (on delete cascade acima).
create or replace function public.excluir_conta(alvo uuid)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'É preciso estar conectado.';
  end if;
  if alvo <> auth.uid() and coalesce(auth.jwt() ->> 'email', '') <> 'nicolasrenan10@gmail.com' then
    raise exception 'Sem permissão para excluir essa conta.';
  end if;
  delete from auth.users where id = alvo;
end;
$$;

revoke execute on function public.listar_contas() from public, anon;
revoke execute on function public.excluir_conta(uuid) from public, anon;
grant execute on function public.listar_contas() to authenticated;
grant execute on function public.excluir_conta(uuid) to authenticated;
