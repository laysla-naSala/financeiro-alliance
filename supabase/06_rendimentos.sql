-- Rendimentos das aplicações (Vermont, ContaMax) — um registro por aplicação e mês. Valores em centavos.
-- Rodar uma vez no SQL Editor. Só cria; não altera nada existente.

create table public.rendimentos (
  empresa        text not null default 'alliance',
  aplicacao      text not null check (aplicacao in ('vermont','contamax')),
  competencia    text not null check (competencia ~ '^\d{4}-\d{2}$'),
  saldo_ini      bigint,
  aplicacoes     bigint not null default 0,
  resgates       bigint not null default 0,
  impostos       bigint not null default 0,
  rendimento     bigint not null default 0,
  saldo_fim      bigint,
  pct_mes        numeric,          -- rendimento do mês em %
  carteira_ano   numeric,          -- acumulado no ano em %
  cdi_ano        numeric,          -- CDI acumulado no ano em %
  acumulado      bigint,           -- rendimento desde o início da gestão
  tabela_anos    jsonb,            -- histórico por ano/mês (vem no relatório Vermont)
  arquivo        text,
  atualizado_por uuid default auth.uid() references auth.users on delete set null,
  atualizado_por_email text,
  atualizado_em  timestamptz not null default now(),
  primary key (empresa, aplicacao, competencia)
);

-- Ajustes que a Laysla define pelo site (ex.: % mínimo do CDI para alertar)
create table public.configuracoes (
  empresa text not null default 'alliance',
  chave   text not null,
  valor   jsonb not null,
  primary key (empresa, chave)
);

alter table public.rendimentos   enable row level security;
alter table public.configuracoes enable row level security;

create policy "rendimentos: quem tem perfil vê" on public.rendimentos for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );
create policy "rendimentos: lança e admin incluem" on public.rendimentos for insert to authenticated
  with check ( (select private.papel_atual()) in ('admin','lanca') and atualizado_por = (select auth.uid()) );
create policy "rendimentos: lança e admin alteram" on public.rendimentos for update to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca') )
  with check ( (select private.papel_atual()) in ('admin','lanca') and atualizado_por = (select auth.uid()) );

create policy "configuracoes: quem tem perfil vê" on public.configuracoes for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );
create policy "configuracoes: admin inclui" on public.configuracoes for insert to authenticated
  with check ( (select private.papel_atual()) = 'admin' );
create policy "configuracoes: admin altera" on public.configuracoes for update to authenticated
  using ( (select private.papel_atual()) = 'admin' ) with check ( (select private.papel_atual()) = 'admin' );

grant select, insert, update on public.rendimentos, public.configuracoes to authenticated;

insert into public.configuracoes (chave, valor) values ('rendimento_min_pct_cdi', '100'::jsonb);
