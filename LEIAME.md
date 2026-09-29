# Site Financeiro naSala · Alliance

Site com login e senha, no visual do Alliance P.O.. Hoje tem **Meu Painel** e **Conciliação de Boletos** (Alliance · Itaú). Os envios à contabilidade entram depois como outro módulo, no mesmo login.

| Parte | Onde fica |
|---|---|
| Páginas (este repositório) | GitHub Pages |
| Login, perfis e histórico | Supabase |
| Arquivos do banco e extrato | Só no navegador de quem usa: não são enviados a lugar nenhum |

## Arquivos

- `index.html`: login e recuperação de senha (visual no padrão do Alliance P.O.); depois do login vai para o Meu Painel
- `painel.html`: Meu Painel, com os recebimentos de boletos do mês a partir dos fechamentos salvos
- `conciliacao.html`: conciliação de boletos e histórico de fechamentos
- `conciliacao-bancaria.html`: Conciliação Bancária: bancos ativos (a Laysla cadastra e desativa), situação de conciliação lida do Everest pelo n8n e alerta de segunda às 18h
- `rendimentos.html`: Rendimentos: lê os relatórios da Vermont e do ContaMax (PDF), com conferência antes de salvar; gráfico mês × CDI, histórico por ano e alertas
- `contabilidade.html`: Envios à Contabilidade: lê o extrato do Santander (PDF ou OFX), cruza com a planilha de pagamentos, exige os dados por categoria e gera a planilha para a contabilidade
- `assets/layout.js`: menu lateral e barra do topo das páginas internas. Um módulo novo entra acrescentando um item em `MENU`
- `assets/config.js`: URL e chave **pública** do Supabase
- `assets/sessao.js`: sessão e perfil, usados por todas as páginas
- `assets/estilo.css`: visual
- `supabase/01_estrutura.sql`, `02_envios_contabilidade.sql` e `03_conciliacao_bancaria.sql` e `04_subcontas.sql`, `05_documentos.sql`, `06_rendimentos.sql`: tabelas e regras de acesso (rodar uma vez, nessa ordem)

## Configurar o Supabase (uma vez, feito pela Laysla)

1. Crie o projeto em supabase.com e guarde a senha do banco com você.
2. **SQL Editor → New query**: cole todo o `supabase/01_estrutura.sql` e clique em **Run**.
3. **Authentication → Sign In / Providers**: desligue **"Allow new users to sign up"**. Só a Laysla cadastra pessoas.
4. **Authentication → URL Configuration**: em *Site URL*, coloque o endereço do site no GitHub Pages.
5. **Project Settings → API**: copie a *Project URL* e a chave pública (*anon* / *publishable*) para `assets/config.js`. Nunca use a chave *service_role* / *secret*.

## Cadastrar uma pessoa

1. **Authentication → Users → Add user → Create new user**: e-mail + senha provisória (marque *Auto Confirm User*).
2. Ela entra como **consulta** (só vê). Para liberar o salvamento: **Table Editor → perfis**, troque `papel` para `lanca`.
3. A Laysla deve ter `papel = admin`.
4. A pessoa pode trocar a senha em **Esqueci a senha**, na tela de login.

| Papel | Pode |
|---|---|
| `admin` | Tudo, e ver todos os perfis |
| `lanca` | Conciliar e salvar fechamentos |
| `consulta` | Conciliar e ver o histórico, sem salvar |

Para tirar o acesso de alguém: **Authentication → Users → Delete user**.

## Segurança

- A chave pública pode ficar no site. Quem protege os dados são as regras do banco (RLS): sem login, nenhuma tabela responde.
- Fechamentos só são apagados pelo painel do Supabase, e só a Laysla tem acesso a ele.
- O histórico guarda só os totais por projeto e tipo, sem nome de pagador.
