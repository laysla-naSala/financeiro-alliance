-- Subcontas: um banco pode ter várias contas por dentro (ex.: SGPAY, uma por turma).
-- No site aparece uma linha só, com a soma das subcontas. Só acrescenta; não altera dados existentes.

alter table public.contas_bancarias
  add column conta_pai uuid references public.contas_bancarias(id) on delete cascade;

-- SGPAY com as turmas que aparecem no Contas a Receber de 25/09/2026 (a lista se completa com o Everest)
with pai as (
  insert into public.contas_bancarias (banco, apelido, tipo)
  values ('SGPAY', 'Recebimentos por turma (soma de todas)', 'pagamentos')
  returning id
)
insert into public.contas_bancarias (banco, apelido, tipo, conta_pai)
select 'SGPAY', t.apelido, 'pagamentos', pai.id
from pai, (values
  ('PUC T18 · Medicina 2026'),
  ('PUC · Direito 2026'),
  ('CSAG Central · 3º ano 2026'),
  ('Vendas CSAG 26'),
  ('UFMG 191 · Direito 2030'),
  ('Bernoulli · 9º ano 2026'),
  ('Loyola · 9º ano 2026')
) as t(apelido);
