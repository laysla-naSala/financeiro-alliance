-- Conciliação bancária — contas ativas e a situação de conciliação de cada uma (lida do Everest pelo n8n).
-- Rodar uma vez no SQL Editor, depois do 01 e do 02. Só cria; não altera nada existente.

-- Contas bancárias da empresa (a Laysla mantém pelo site)
create table public.contas_bancarias (
  id        uuid primary key default gen_random_uuid(),
  empresa   text not null default 'alliance',
  banco     text not null,
  agencia   text,
  conta     text,
  apelido   text,
  tipo      text not null default 'corrente' check (tipo in ('corrente','cobranca','aplicacao','pagamentos')),
  ativa     boolean not null default true,
  criado_em timestamptz not null default now()
);

-- Uma linha por conta e por dia de leitura. Quem grava é o fluxo do n8n (chave secreta, fora do site).
create table public.conciliacao_bancos (
  empresa          text not null default 'alliance',
  conta_id         uuid not null references public.contas_bancarias on delete cascade,
  data_leitura     date not null,
  conciliado       boolean not null,
  conciliado_ate   date,                 -- último dia conciliado no Everest
  pendencias       integer not null default 0,
  valor_pendente   bigint  not null default 0,   -- centavos
  detalhe          jsonb,
  lido_em          timestamptz not null default now(),
  primary key (conta_id, data_leitura)
);

alter table public.contas_bancarias   enable row level security;
alter table public.conciliacao_bancos enable row level security;

create policy "contas: quem tem perfil vê" on public.contas_bancarias for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );
create policy "contas: admin inclui" on public.contas_bancarias for insert to authenticated
  with check ( (select private.papel_atual()) = 'admin' );
create policy "contas: admin altera" on public.contas_bancarias for update to authenticated
  using ( (select private.papel_atual()) = 'admin' ) with check ( (select private.papel_atual()) = 'admin' );

create policy "conciliacao: quem tem perfil vê" on public.conciliacao_bancos for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );
-- sem regra de escrita para o site: só o n8n grava

grant select, insert, update on public.contas_bancarias to authenticated;
grant select on public.conciliacao_bancos to authenticated;

-- Contas já conhecidas (a Laysla completa ou corrige pelo site)
insert into public.contas_bancarias (banco, agencia, conta, apelido, tipo) values
  ('Santander', '4272', '130036433', 'Conta movimento', 'corrente'),
  ('Santander', '4272', '130036433', 'ContaMax (aplicação automática)', 'aplicacao'),
  ('Itaú', '4450', '19440-4', 'Recebimento de boletos (mensalidades)', 'cobranca'),
  ('Vermont', null, null, 'Aplicação', 'aplicacao');
