-- Contas a Receber — títulos importados do Everest (e depois do SGE), cobranças e contatos.
-- Rodar uma vez no SQL Editor. Só cria; não altera nada existente.

-- Títulos em aberto (uma linha por título; reimportar substitui pelo número do título)
create table public.titulos_receber (
  empresa        text not null default 'alliance',
  origem         text not null default 'everest' check (origem in ('everest','sge')),
  titulo         text not null,             -- número do título no sistema de origem
  serie          text,
  parcela        text,
  cliente        text,
  cliente_cod    text,
  nota           text,                      -- número da NF
  descricao      text,
  carteira       text not null default 'notas' check (carteira in ('notas','sgpay','mutuo','mensalidade','outros')),
  vencimento     date,
  competencia    date,
  lancamento     date,
  valor_original bigint not null default 0, -- centavos
  saldo          bigint not null default 0,
  situacao       text,
  portador       text,
  observacao     text,
  gestor_email   text,                      -- quem acompanha (definido pelo site)
  baixado_em     date,                      -- quando o site viu o pagamento no extrato
  baixa_ref      text,                      -- lançamento do extrato que casou
  importado_em   timestamptz not null default now(),
  importado_por_email text,
  primary key (empresa, origem, titulo, parcela)
);

-- Histórico de cobranças e contatos por título
create table public.cobrancas (
  id             uuid primary key default gen_random_uuid(),
  empresa        text not null default 'alliance',
  origem         text not null,
  titulo         text not null,
  parcela        text,
  tipo           text not null check (tipo in ('aviso_gestor','cobranca_cliente','contato','acordo','anotacao')),
  canal          text,                      -- email | whatsapp | telefone | presencial
  para           text,
  mensagem       text,
  resposta       text,
  feito_por_email text,
  feito_em       timestamptz not null default now()
);

-- Contatos de cobrança (cliente → e-mail/telefone) e gestores
create table public.contatos_cobranca (
  empresa   text not null default 'alliance',
  chave     text not null,                  -- nome do cliente (como vem do Everest) ou 'gestor:<nome>'
  nome      text,
  email     text,
  telefone  text,
  papel     text not null default 'cliente' check (papel in ('cliente','gestor')),
  primary key (empresa, chave)
);

alter table public.titulos_receber  enable row level security;
alter table public.cobrancas        enable row level security;
alter table public.contatos_cobranca enable row level security;

create policy "titulos: quem tem perfil vê" on public.titulos_receber for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );
create policy "titulos: lança e admin incluem" on public.titulos_receber for insert to authenticated
  with check ( (select private.papel_atual()) in ('admin','lanca') );
create policy "titulos: lança e admin alteram" on public.titulos_receber for update to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca') ) with check ( (select private.papel_atual()) in ('admin','lanca') );
create policy "titulos: lança e admin removem" on public.titulos_receber for delete to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca') );

create policy "cobrancas: quem tem perfil vê" on public.cobrancas for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );
create policy "cobrancas: lança e admin incluem" on public.cobrancas for insert to authenticated
  with check ( (select private.papel_atual()) in ('admin','lanca') );

create policy "contatos: quem tem perfil vê" on public.contatos_cobranca for select to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca','consulta') );
create policy "contatos: lança e admin incluem" on public.contatos_cobranca for insert to authenticated
  with check ( (select private.papel_atual()) in ('admin','lanca') );
create policy "contatos: lança e admin alteram" on public.contatos_cobranca for update to authenticated
  using ( (select private.papel_atual()) in ('admin','lanca') ) with check ( (select private.papel_atual()) in ('admin','lanca') );

grant select, insert, update, delete on public.titulos_receber to authenticated;
grant select, insert on public.cobrancas to authenticated;
grant select, insert, update on public.contatos_cobranca to authenticated;

-- Régua de cobrança padrão (dias de atraso): a Laysla ajusta pelo site
insert into public.configuracoes (chave, valor) values ('regua_cobranca', '{"lembrete":3,"cobranca":10,"firme":30,"escalar":45}'::jsonb);
