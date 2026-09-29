# Para o Luiz — as regras que vão para o seu site

> Da Laysla, 29/09/2026. **Layout, login e formato são seus.** O que vai são só as regras de três módulos. As páginas deste repositório servem de referência: o código está em `conciliacao.html`, `contabilidade.html` e `contas-receber.html`, e as tabelas em `supabase/`.
>
> A partir daqui **só você mexe** na junção. Este repositório fica congelado.

**Vão:** Conciliação de Boletos · Envios à Contabilidade · Contas a Receber.
**Não vão:** login, layout, Meu Painel, Conciliação Bancária, Rendimentos.

Convenções do código dela: todo valor em **centavos (inteiro)**, datas em `AAAA-MM-DD`, e comparação de texto sem acento e sem caixa (`norm`).

---

## 1. Conciliação de Boletos (Alliance · Itaú)

**Para que serve:** separar por projeto (turma) e por tipo (mensalidade ou produto) o que entrou de boleto num dia, e provar que bate com o extrato.

### Entradas (todas do mesmo dia de crédito)
| Arquivo | Obrigatório | Como reconhece |
|---|---|---|
| Retorno Itaú CNAB 400 (`.RET`) | sim | 1ª linha começa com `02RETORNO`; banco `341` nas posições 77–79 |
| Contas a Receber do SGE — mensalidades (`.xlsx`) | sim | tem coluna "Valor Pago"; o nome do arquivo com "mensal" diz o tipo |
| Contas a Receber do SGE — produtos (`.xlsx`) | sim | idem; o nome com "produt", "venda" ou "loja" diz o tipo. Sem nome claro, o site pergunta |
| Extrato Itaú (PDF) | não (dá para digitar os 2 valores) | linhas `DD/MM/AAAA descrição valor` |
| Lista de projetos do SGE (`.xlsx`) | não | tem "Meta de adesão" ou "Fase"; só dá nome aos projetos |

### Leitura do retorno (registro tipo 1)
- Seu número (pos. 38–62) = `Cód.do formando.parcela`. Cód. sem zeros à esquerda.
- Ocorrência (109–110). **Pago = 06, 07 ou 08** (liquidação normal, parcial ou em cartório).
- Valor principal (254–266), tarifa (176–188), juros (267–279), desconto (241–253), vencimento (147–152), data de crédito (296–301), pagador (325–354).
- **Valor recebido do boleto = principal + tarifa** (só nos pagos).
- Registros não pagos com tarifa > 0 entram só pela tarifa.

### Regras
1. **Dia de crédito:** o arquivo pode ter mais de uma data. O padrão é a mais recente, e o usuário pode trocar.
2. **Projeto do boleto**, em ordem: escolha manual → Cód. achado no SGE → memória (Cód.→Projeto de importações anteriores, hoje guardada no navegador). Sem projeto vira pendência.
3. **Casamento boleto × SGE**, nesta ordem, cada linha do SGE usada uma vez só:
   - mesmo Cód. + mesmo valor + mesma data de crédito → **Confere**
   - mesmo Cód. + mesmo valor → **SGE com outra data de crédito**
   - mesmo Cód. + mesma data → **Valor diferente no SGE** (costuma ser juros ou multa não lançados)
   - nada → **Pago no banco e não baixado no SGE**
4. **Tipo** (mensalidade ou produto) = a planilha em que o boleto casou. Se casar nas duas, o usuário escolhe. Se não casar, usa o tipo do Cód. quando ele só aparece em uma planilha. A **tarifa acompanha o tipo do boleto**.
5. **Sobra:** linhas do SGE com crédito no dia, meio "boleto" e conta destino contendo `19440`, que não vieram no retorno, viram pendência ("baixado no SGE e fora do retorno").
6. **Extrato:** soma as linhas `BOLETOS RECEBIDOS DD/MM` do dia e `TAR…CUSTAS…COBRAN` do dia.
7. **Situação do dia:**
   - arquivos de dias diferentes → bloqueia salvar
   - sem valor do extrato
   - **Conciliado**: extrato = retorno, tarifa bate e zero pendências
   - "Valor bate · N pendências"
   - "Não bate com o extrato"

### Saída
- Tabela por projeto e tipo: boletos, recebido, tarifa, líquido.
- Excel com 4 abas: Por projeto · Boletos · Conferência · Pendências.
- **Salvar o fechamento do dia:** tabela `fechamentos_boletos`, uma linha por `(empresa, data)`. Salvar de novo pede confirmação e substitui.
- O histórico guarda **só totais** por projeto e tipo, sem nome de pagador.
- Histórico por mês com Excel: Dias · Por projeto · Mês por projeto.

**Quem pode:** ver e conciliar, qualquer perfil do módulo; salvar, só quem lança.

---

## 2. Envios à Contabilidade

**Para que serve:** transformar o extrato do mês numa planilha completa para a contabilidade (cada saída com fornecedor, NF e tipo de serviço) e enviar por e-mail com os anexos.

**Hoje está preso à Alliance**: CNPJ `17999990000116`, conta Santander ag. 4272 cc 130036433, e-mails da contabilidade fixos no n8n. Para servir todas as empresas, esses três viram **dados por empresa**.

### Entradas
| Arquivo | Regra |
|---|---|
| Extrato Santander, PDF ou OFX | **Define o mês** (o mês com mais movimentos). No PDF, cada movimento começa com a data e termina com "valor saldo" |
| Planilha de pagamentos, modelo `Envio_Contabilidade` (`.xlsx`, opcional) | Colunas por prefixo: Data baixa, Razão social/Fornecedor, Nº nota, Valor da NF (ou Valor FT), Valor baixa/Valor pago, Descrição/Tipo de serviço, Obs |
| Qualquer outro arquivo (PDF sem movimentos etc.) | Vira **anexo do e-mail**, guardado no bucket privado `documentos`, em `alliance/contabilidade/AAAA-MM/`. Se o nome indicar outro mês, avisa |

### Regras
1. **Prova de leitura completa (PDF):** saldo anterior + valor = saldo da linha, movimento a movimento. Se quebrar, **bloqueia o envio** e sugere o OFX. Também confere saldo inicial + movimentos = saldo final.
2. **Categoria sugerida pelo histórico do banco** (a primeira regra que bater vale):
   - entrada com o CNPJ da própria empresa → Transferência do Itaú (borderô)
   - `PIX DEVOLVIDO` ou `ESTORNO` → Devolução
   - começa com `TARIFA` → Tarifa
   - `DARF`, `TRIBUTOS`, `FGTS`, `INSS`, `GPS` ou `ISS` → Imposto (município → "ISS / tributo municipal"; DARF → "tributo federal")
   - `APLICACAO`, `RESGATE` ou `CONTAMAX` → Aplicação
   - começa com `TED ENVIADA` → Empréstimo
   - `NS EVENTOS` ou `NASALA` → Empresa do grupo
   - começa com `PAGAMENTO` → Conta/boleto
   - começa com `PIX ENVIADO` → Fornecedor
   - o resto → Outros
3. **O que cada categoria exige** para a linha ficar completa:
   | Categoria | Exige |
   |---|---|
   | Fornecedor (com NF) | fornecedor, nº NF, valor bruto NF, valor líquido NF, tipo de serviço |
   | Conta/boleto, Folha/comissão | fornecedor, tipo de serviço |
   | Imposto | tipo de serviço |
   | Empréstimo, Empresa do grupo, Outros | fornecedor, observação |
   | Devolução | observação |
   | Transferência, Tarifa, Aplicação | nada |

   Marcar **"NF a emitir"** dispensa os campos de NF, e a linha segue como pendente para o mês seguinte.
4. **Fornecedor inicial** = nome do favorecido tirado do histórico do banco (sem o prefixo "Pix Enviado", "Pagamento De Boleto"… e sem números).
5. **Casamento planilha × extrato:** mesmo valor pago, data mais próxima, até 10 dias; cada movimento usado uma vez. Preenche fornecedor, NF, valor NF, serviço e obs.
   - Obs com "A SER EMITIDA", "AGUARDANDO NF" ou "A EMITIR" → NF a emitir.
   - Boleto com NF vira Fornecedor; Fornecedor sem NF com "BOLETO" na obs vira Conta/boleto.
6. **Valor líquido da NF sugerido:** se o pago fica entre 85% e 100% do bruto (retenções), o pago é o líquido.
7. **Avisos, que não bloqueiam:**
   - pago maior que 101% da NF
   - linhas em "Outros"
   - empréstimos do mês
   - posição de aplicações não preenchida
8. **Memória:** fornecedor, categoria e serviço usados nos últimos 12 meses para o mesmo favorecido (3 primeiras palavras do nome) são aplicados sozinhos.
   - Ao preencher o serviço de uma linha, ele é copiado para as outras do mesmo fornecedor que estão vazias.
9. **Aplicações** (Vermont e Santander ContaMax): saldo inicial, aplicações, resgates, rendimento, IR/IOF e saldo final.
   - Hoje vêm do módulo Rendimentos, que **não vai**. No seu site ficam para digitar, ou você traz os dados.
10. **Bloqueia o envio:** sem extrato, com linha incompleta ou com a cadeia de saldos quebrada.

### Saída
- Planilha `Envio_Contabilidade MM-AAAA.xlsx` com as abas:
  - movimentos, com Situação por linha
  - Resumo por categoria e saldos
  - Aplicações
  - Empréstimos e grupo
  - Pendências
- **Salvar:** tabela `envios_contabilidade`, uma linha por `(empresa, competencia)`, com status `rascunho` ou `enviado`, as linhas, as aplicações e um resumo.
- **Botões:**
  - "Enviar teste para mim": o e-mail vai só para quem pediu
  - "Enviar para a contabilidade": pede confirmação, envia e marca como enviado
  - "Já enviei por fora": só marca como enviado

### E-mail (fluxo n8n "Alliance · Envio à contabilidade", **hoje desativado**)
- O site manda `{ token, competencia, teste, arquivos:[{nome, mime, b64}], resumo }` como `text/plain`, para evitar a checagem de CORS.
- O fluxo:
  1. confere o token e o perfil **no Supabase da Laysla** (só `admin` ou `lanca` envia);
  2. monta o e-mail;
  3. envia pela caixa da Jhulia.
- Destinatários: a contabilidade, com cópia para a Laysla. No teste, só quem pediu. Limite de cerca de 20 MB.
- **Para funcionar no seu site precisa mudar:** o Supabase conferido (o seu), a regra de perfil (a sua), a origem permitida (hoje só `laysla-nasala.github.io`, entra o seu domínio) e os destinatários por empresa. **A Laysla ajusta o fluxo quando você disser o domínio e a regra de perfil.**

**Quem pode:** ver, qualquer perfil do módulo; editar, salvar e enviar, só quem lança.

---

## 3. Contas a Receber

**Para que serve:** a carteira de títulos em aberto separada por tipo, o que já entrou no extrato e o controle de cobrança.

### Entradas
| Arquivo | Regra |
|---|---|
| Everest › "Manutenção de Títulos a Receber" (`.xlsx`) | Colunas: Fantasia Cliente, Cliente, Título, Série, Parcela, D. Vencimento, D. Competência, D. Lançamento, D. Liquidação, V. Original, V. Saldo, Situação, Descrição do Portador, N. Fiscal, Observação. O título está na linha com `-` na col. A e `S` na col. B; a descrição fica 2 linhas abaixo, col. T |
| Extrato Santander, PDF ou OFX | Só para apontar o que já foi pago |

### Regras
1. **Só entra** título não liquidado e com saldo > 0.
2. **Carteira de cada título:**
   - descrição ou observação com `SGPAY` → SGPay (aguardando repasse)
   - `EMPRESTAD`, `EMPRESTIMO` ou `MUTUO`, **ou** cliente NS Eventos/naSala → Mútuos
   - cliente exatamente "Alliance" ou "Receitas Alliance" → Outros (lançamento interno)
   - o resto → Notas emitidas
   - Existe a carteira "Mensalidades (SGE)", **mas nada a alimenta ainda**.
3. **Importar substitui a carteira inteira** (apaga os títulos de origem Everest da empresa e insere os novos), mas **mantém a baixa e o gestor** já anotados no mesmo título + parcela.
4. **Pago no extrato:** uma entrada com valor igual ao saldo do título. Havendo mais de uma, prefere a que tem no histórico as 2 primeiras palavras (com mais de 3 letras) do nome do cliente. Grava `baixado_em` e a referência, e o título aparece como "pago no extrato · falta baixar no Everest".
5. **Atraso e faixas:** a vencer, 1–30, 31–60, 61–90, mais de 90 dias.
6. **Régua de cobrança**, configurável por empresa, com dias em ordem crescente. Padrão: lembrete 3 · cobrança 10 · cobrança firme 30 · escalar ao gestor 45. Mostra o passo sugerido por título.
   - Só entram na cobrança as carteiras Notas e Mensalidades.
7. **Registro de ação por título:**
   - tipo: contato, cobrança ao cliente, aviso ao gestor, acordo ou anotação
   - canal, para quem, mensagem e resposta
   - histórico em `cobrancas`, com a última ação exibida no título
8. **Gestor por título** (e-mail). Gestores e contatos de cliente ficam em `contatos_cobranca`.

### Totais
- Em aberto
- Vencido (só Notas e Mensalidades)
- A vencer
- Pago no extrato

### Tabelas
- `titulos_receber`, chave `(empresa, origem, titulo, parcela)`
- `cobrancas`
- `contatos_cobranca`, chave `(empresa, chave)`
- `configuracoes`, chave `(empresa, chave)`; a régua fica em `regua_cobranca`. A tabela é criada no `06_rendimentos.sql`: pegar só esse trecho

**Quem pode:**
- ver: qualquer perfil do módulo
- importar e registrar: quem lança
- mudar a régua: admin

---

## Para os três módulos

- **Todas as tabelas já têm a coluna `empresa`** (hoje sempre `alliance`). É o que permite a mesma tela servir outras empresas, cada uma vendo só a sua.
- Dados já salvos no Supabase da Laysla (`dvjeipnkxlvhfeuimacf`): você já tem acesso. Levar ou não é decisão dela.
- **Não** rodar a parte de `perfis` / `criar_perfil_novo_usuario` do `supabase/01_estrutura.sql`: o cadastro de perfis é o seu.
- As regras de acesso (RLS) dos arquivos `supabase/` usam os papéis dela (`admin` / `lanca` / `consulta`). Precisam ser reescritas com o seu modelo de perfil.
