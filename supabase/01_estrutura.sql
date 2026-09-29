-- Site financeiro naSala / Alliance — estrutura do banco (Supabase)
-- Rodar UMA vez no Supabase: SQL Editor → New query → colar tudo → Run.
-- Padrões seguidos da documentação oficial do Supabase:
--   perfis ligados a auth.users + gatilho de criação (guides/auth/managing-user-data)
--   RLS com (select auth.uid()) e função security definer com search_path = '' (guides/database/postgres/row-level-security)

-- ───────────────────────── Perfis de acesso ─────────────────────────
-- papel: 'admin'   = Laysla (vê e altera tudo, gerencia perfis)
--        'lanca'   = quem salva fechamentos (Jhulia, tesouraria)
--        'consulta'= quem só vê (contabilidade, comissões)
create table public.perfis (
  id         uuid not null references auth.users on delete cascade,
  email      text,
  nome       text,
  papel      text not null default 'consulta' check (papel in ('admin','lanca','consulta')),
  criado_em  timestamptz not null default now(),
  primary key (id)
);

-- Cria o perfil automaticamente quando um usuário é cadastrado no Supabase (entra como 'consulta')
create function public.criar_perfil_novo_usuario()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.perfis (id, email, nome)
  values (new.id, new.email, new.raw_user_meta_data ->> 'nome');
  return new;
end;
$$;

create trigger ao_criar_usuario
  after insert on auth.users
  for each row execute procedure public.criar_perfil_novo_usuario();

-- Papel de quem está logado (usada nas regras abaixo). Fica num schema que o site não enxerga.
create schema if not exists private;

create function private.papel_atual()
returns text
language sql
stable
security definer set search_path = ''
as $$
  select p.papel from public.perfis p where p.id = (select auth.uid());
$$;

grant usage on schema private to authenticated;
grant execute on function private.papel_atual() to authenticated;

alter table public.perfis enable row level security;

create policy "perfis: cada um vê o próprio"
  on public.perfis for select to authenticated
  using ( (select auth.uid()) = id );

create policy "perfis: admin vê todos"
  on public.perfis for select to authenticated
  using ( (select private.papel_atual()) = 'admin' );

create policy "perfis: admin altera"
  on public.perfis for update to authenticated
  using ( (select private.papel_atual()) = 'admin' )
  with check ( (select private.papel_atual()) = 'admin' );

grant select, update on public.perfis to authenticated;

-- ───────────────────── Fechamentos da conciliação de boletos ─────────────────────
-- Uma linha por empresa e dia de crédito. Valores em CENTAVOS (inteiros) para não haver erro de arredondamento.
create table public.fechamentos_boletos (
  empresa          text not null default 'alliance',
  data             date not null,
  status           text not null,          -- ok | pend | diverge | semextrato
  status_texto     text,
  pendencias       integer not null default 0,
  qtd_boletos      integer not null default 0,
  recebido         bigint  not null default 0,
  tarifa           bigint  not null default 0,
  mens_qtd         integer not null default 0,
  mens_recebido    bigint  not null default 0,
  mens_tarifa      bigint  not null default 0,
  prod_qtd         integer not null default 0,
  prod_recebido    bigint  not null default 0,
  prod_tarifa      bigint  not null default 0,
  semtipo_qtd      integer not null default 0,
  semtipo_recebido bigint  not null default 0,
  semtipo_tarifa   bigint  not null default 0,
  extrato_boletos  bigint,
  extrato_tarifa   bigint,
  projetos         jsonb not null default '[]'::jsonb,   -- [{projeto, descricao, tipo, qtd, bruto, tarifa}]
  arquivos         jsonb,
  salvo_por        uuid default auth.uid() references auth.users on delete set null,
  salvo_por_email  text,
  salvo_em         timestamptz not null default now(),
  primary key (empresa, data)
);

alter table public.fechamentos_boletos enable row level security;

create policy "fechamentos: quem tem perfil vê"
  on public.fechamentos_boletos for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );

create policy "fechamentos: lança e admin incluem"
  on public.fechamentos_boletos for insert to authenticated
  with check ( (select private.papel_atual()) in ('admin','lanca') and salvo_por = (select auth.uid()) );

create policy "fechamentos: lança e admin substituem"
  on public.fechamentos_boletos for update to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca') )
  with check ( (select private.papel_atual()) in ('admin','lanca') and salvo_por = (select auth.uid()) );

-- Sem regra de exclusão: apagar um fechamento só pelo painel do Supabase, pela Laysla.
grant select, insert, update on public.fechamentos_boletos to authenticated;
