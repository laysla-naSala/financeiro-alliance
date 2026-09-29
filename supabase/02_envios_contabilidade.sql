-- Envios à Contabilidade — uma linha por empresa e competência (mês).
-- Rodar uma vez no SQL Editor, depois do 01_estrutura.sql. Só cria; não altera nada existente.
-- Mesmo padrão de acesso dos fechamentos: quem tem perfil vê; 'lanca' e 'admin' gravam.

create table public.envios_contabilidade (
  empresa               text not null default 'alliance',
  competencia           text not null check (competencia ~ '^\d{4}-\d{2}$'),   -- AAAA-MM
  status                text not null default 'rascunho' check (status in ('rascunho','enviado')),
  linhas                jsonb not null default '[]'::jsonb,   -- um item por movimento do extrato
  aplicacoes            jsonb not null default '[]'::jsonb,   -- Vermont, ContaMax: saldos, aplicações, resgates, rendimento, IR
  extrato               jsonb,                                -- arquivo, conta, saldo inicial e final
  resumo                jsonb,                                -- totais e contagens, para o histórico
  atualizado_por        uuid default auth.uid() references auth.users on delete set null,
  atualizado_por_email  text,
  atualizado_em         timestamptz not null default now(),
  enviado_por_email     text,
  enviado_em            timestamptz,
  primary key (empresa, competencia)
);

alter table public.envios_contabilidade enable row level security;

create policy "envios: quem tem perfil vê"
  on public.envios_contabilidade for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );

create policy "envios: lança e admin incluem"
  on public.envios_contabilidade for insert to authenticated
  with check ( (select private.papel_atual()) in ('admin','lanca') and atualizado_por = (select auth.uid()) );

create policy "envios: lança e admin alteram"
  on public.envios_contabilidade for update to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca') )
  with check ( (select private.papel_atual()) in ('admin','lanca') and atualizado_por = (select auth.uid()) );

grant select, insert, update on public.envios_contabilidade to authenticated;
