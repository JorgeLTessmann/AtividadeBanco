# Dicionário de Dados — Cotações da NVIDIA (NVDA)

## 1. Visão geral

A tabela `COTACOES_NVDA` armazena dados históricos diários de mercado da ação da NVIDIA, identificada pelo ticker `NVDA`. O conjunto utilizado no script SQL contém 75 registros selecionados do CSV original, abrangendo o período de 22/01/1999 a 21/09/2026.

- **Tabela:** `COTACOES_NVDA`
- **Banco de dados:** MySQL
- **Mecanismo:** InnoDB
- **Chave primária:** `ID`
- **Chave única:** combinação de `TICKER` e `DATA_COTACAO`
- **Granularidade:** um registro por ativo e data de negociação

## 2. Dicionário de colunas

| Coluna | Tipo de dado | Nulo? | Descrição |
|---|---|---:|---|
| `ID` | `INT` | Não | Identificador numérico único do registro. Gerado automaticamente (`AUTO_INCREMENT`) e utilizado como chave primária. |
| `DATA_COTACAO` | `DATE` | Não | Data do pregão ao qual as informações da cotação se referem. |
| `TICKER` | `VARCHAR(10)` | Não | Código de negociação do ativo na bolsa. Neste conjunto de dados, o valor é `NVDA`. |
| `OPEN` | `DECIMAL(20,15)` | Não | Preço de abertura da ação no pregão. |
| `HIGH` | `DECIMAL(20,15)` | Não | Maior preço atingido pela ação durante o pregão. |
| `LOW` | `DECIMAL(20,15)` | Não | Menor preço atingido pela ação durante o pregão. |
| `CLOSE` | `DECIMAL(20,15)` | Não | Preço de fechamento da ação no pregão. |
| `VOLUME` | `BIGINT` | Não | Quantidade de ações negociadas durante o pregão. |
| `DAILY_RETURN_PCT` | `DECIMAL(20,15)` | Sim | Retorno percentual diário, calculado pela variação do preço de fechamento em relação ao fechamento do pregão anterior. |
| `LOG_RETURN` | `DECIMAL(20,15)` | Sim | Retorno logarítmico diário, normalmente calculado pelo logaritmo natural da razão entre o fechamento atual e o fechamento anterior. É armazenado em formato decimal, não em percentual. |
| `INTRADAY_RETURN_PCT` | `DECIMAL(20,15)` | Não | Variação percentual entre o preço de abertura e o preço de fechamento do mesmo pregão. |
| `DAILY_RANGE_PCT` | `DECIMAL(20,15)` | Não | Amplitude percentual do pregão, representando a diferença entre o preço máximo e o mínimo em relação ao preço de abertura. |
| `OVERNIGHT_GAP_PCT` | `DECIMAL(20,15)` | Sim | Variação percentual entre a abertura do pregão atual e o fechamento do pregão anterior. |
| `SMA_20` | `DECIMAL(20,15)` | Sim | Média móvel simples dos preços de fechamento considerando uma janela de 20 pregões. |
| `SMA_50` | `DECIMAL(20,15)` | Sim | Média móvel simples dos preços de fechamento considerando uma janela de 50 pregões. |
| `VOLATILITY_20_PCT` | `DECIMAL(20,15)` | Sim | Indicador de volatilidade percentual calculado com base em uma janela de 20 pregões. A forma exata de cálculo e eventual anualização dependem da metodologia usada na preparação do CSV. |
| `VOLUME_SMA_20` | `BIGINT` | Sim | Média móvel do volume negociado considerando uma janela de 20 pregões. |
| `DRAWDOWN_PCT` | `DECIMAL(20,15)` | Não | Queda percentual do preço de fechamento em relação ao maior fechamento acumulado até a data considerada. Valores negativos indicam que o preço está abaixo desse máximo. |
| `YEAR` | `SMALLINT` | Não | Ano da data de cotação, no formato numérico de quatro dígitos. |
| `MONTH` | `TINYINT` | Não | Mês da data de cotação, variando de 1 a 12. |
| `DAY_OF_WEEK` | `VARCHAR(10)` | Não | Dia da semana correspondente à data de cotação, armazenado em inglês (por exemplo: `Monday`, `Tuesday`). |

## 3. Regras e observações

- A combinação `TICKER` + `DATA_COTACAO` não pode se repetir, devido à restrição `UK_COTACAO_TICKER_DATA`.
- A coluna `ID` é criada no banco e não existe entre as colunas originais do CSV.
- Os campos marcados como anuláveis podem receber `NULL`. Isso ocorre, por exemplo, quando não há pregão anterior para calcular retornos ou quando ainda não existe histórico suficiente para uma média móvel.
- Os campos terminados em `_PCT` representam valores percentuais. Por exemplo, `2.5` representa 2,5%, não 0,025%.
- `LOG_RETURN` é uma medida logarítmica e não deve ser interpretada diretamente como percentual.
- Os valores de preço são mantidos na escala numérica fornecida pelo CSV. O arquivo não possui uma coluna específica para identificar a moeda.
- `YEAR`, `MONTH` e `DAY_OF_WEEK` são informações derivadas da data de cotação e facilitam agrupamentos e consultas por período.

## 4. Resumo dos tipos de dados

| Tipo | Utilização na tabela |
|---|---|
| `INT` | Identificador do registro. |
| `DATE` | Data do pregão. |
| `VARCHAR` | Ticker e nome do dia da semana. |
| `DECIMAL(20,15)` | Preços, retornos, médias e indicadores com casas decimais. |
| `BIGINT` | Volume negociado e média móvel do volume. |
| `SMALLINT` | Ano. |
| `TINYINT` | Mês. |
