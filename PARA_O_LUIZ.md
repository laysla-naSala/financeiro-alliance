# Para o Luiz — como trazer este site para dentro do seu

> Da Laysla, 29/09/2026. A partir daqui **só você mexe** na junção. Este repositório fica congelado: a Laysla não altera mais nada nele até a junção terminar. O que ela precisar mudar passa por você.

## O que foi combinado

- O seu site é a base. **Vale o seu login** (o seu Supabase, a sua tela de entrada, o seu cadastro de perfis).
- Objetivo do grupo: **um site só**, onde cada financeiro vê só os módulos e as empresas (CNPJs) que lhe cabem. Ex.: Conciliação de Boletos só a Alliance usa; Envios à Contabilidade todas as casas usam, e cada pessoa cuida de CNPJs diferentes.
- Sugestão da Laysla para o formato (a decisão é sua, você sabe o que não pode quebrar): cada módulo dela como **página própria** (ex.: pasta `alliance/`), e o seu `index.html` ganha só um link para ela. Assim nenhum nome do código dela encontra os 516 nomes globais do seu.

## O que tem aqui

| Arquivo | O que é |
|---|---|
| `painel.html` | Meu Painel (resumo do mês) |
| `conciliacao.html` | Conciliação de Boletos (Alliance · Itaú) |
| `conciliacao-bancaria.html` | Situação de conciliação dos bancos, lida do Everest pelo n8n |
| `rendimentos.html` | Rendimentos Vermont / ContaMax (lê PDF) |
| `contas-receber.html` | Contas a Receber (importa relatório do Everest) |
| `contabilidade.html` | Envios à Contabilidade (extrato Santander + planilha → e-mail) |
| `index.html` | Tela de login — **sai**, fica a sua |
| `assets/sessao.js` | Sessão e perfil — **é o único ponto que precisa trocar** |
| `assets/config.js` | URL/chave pública do Supabase + endereço do fluxo n8n |
| `assets/layout.js` | Menu lateral e barra do topo |
| `assets/estilo.css` | Visual |
| `supabase/01…07_*.sql` | Tabelas, regras (RLS) e bucket, na ordem de execução |

Todas as páginas usam o login da mesma forma: `const r = await Sessao.exigirLogin()` e depois `Sessao.sb` para ler e gravar. Trocando o `sessao.js` (e o `config.js`), as seis páginas passam a usar o seu login sem mexer nelas.

## Levantamento de nomes (feito em 29/09 contra o seu commit 727bbda)

- **JS no escopo global:** todo o código dela está dentro de `(function(){ ... })()`. Só vazam `CONFIG`, `Sessao`, `Layout`, `__conc`, `__env`, `__cr`, `__rend`, mais `supabase`, `XLSX` e `pdfjsLib` (bibliotecas do CDN). **Nenhum** existe no seu `index.html`.
- **ids em comum com o seu:** `app` (conciliacao.html) e `vazio` (contabilidade.html).
- **Classes CSS definidas nos dois:** `abas, ativo, aviso, btn, cards, det, dica, erro, falta, filtros, legenda, logo, num, ok, quem, rodape, sub, t, tag, wrap`. Variável CSS em comum: `--bg`.
- As páginas dela repetem ids **entre si** (`toast`, `topo`, `corpo`, `cards`, `drop`, `fileInput`, `historico`, `slots`, `aviso`, `conteudoPagina`) e nomes internos (`$`, `fmt`, `sb`, `carregar`). Separadas, não tem problema; se forem para um arquivo só, colidem.

## O que precisa entrar no seu lado

1. **Banco (no seu Supabase):** as tabelas dos arquivos `supabase/` — `fechamentos_boletos`, `envios_contabilidade`, `contas_bancarias`, `conciliacao_bancos`, `rendimentos`, `configuracoes`, `titulos_receber`, `cobrancas`, `contatos_cobranca` — e o bucket privado `documentos`. **Não** rodar o trecho de `perfis` / `criar_perfil_novo_usuario` do `01_estrutura.sql`: ele cria outro cadastro de perfis e iria colidir com o seu.
2. **Regras de acesso:** hoje as regras dela usam `private.papel_atual()` com os papéis `admin` / `lanca` / `consulta`. No seu cadastro os papéis são `financeiro` / `responsavel` / `socio` + permissões avulsas. Precisa decidir com a Laysla o equivalente (quem vê, quem salva) e reescrever as políticas.
3. **Sessão:** o seu site guarda a sessão em `sessionStorage` (`tk`/`rtk`). O `sessao.js` novo pode aproveitar esse token. ⚠️ **Cuidado:** se as páginas dela renovarem a sessão por conta própria (o `supabase-js` faz isso sozinho por padrão), o `rtk` troca e a sua tela perde o login. Melhor as páginas dela só usarem o token e, quando ele vencer, voltarem para a sua tela.
4. **Integrações n8n** (instância `n8n-k5ro.srv1844289.hstgr.cloud`, da Laysla):
   - `alliance-envio-contabilidade`: a página manda o `access_token` e o fluxo **confere o login no Supabase dela**. Precisa passar a conferir no seu.
   - O fluxo que lê a conciliação do Everest grava em `conciliacao_bancos` com a chave secreta do Supabase **dela**. Precisa passar a gravar no seu.
   - A Laysla ajusta os fluxos quando você disser o dia.
5. **Dados já salvos** no Supabase dela (projeto `dvjeipnkxlvhfeuimacf`): a Laysla decide se vão junto ou se começa do zero.

## O que a Laysla deixa pronto para você

- Este repositório é público: você lê e copia sem precisar de convite.
- Você já tem acesso ao Supabase dela (projeto `dvjeipnkxlvhfeuimacf`) para ver as tabelas e exportar dados.
- As respostas sobre casas, CNPJs, módulos e quem acessa o quê, quando você precisar.
