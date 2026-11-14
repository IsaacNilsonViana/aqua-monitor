# Análise ética e relatório de vieses

## Análise ética

| Risco | Consequência possível | Medida adotada ou necessária |
| --- | --- | --- |
| Tratar limites didáticos como garantia de potabilidade | Falsa sensação de segurança | O README explicita que são referências configuráveis e que potabilidade depende de norma, calibração e análise laboratorial. |
| Falha ou falta de calibração da sonda | Alarme falso ou alteração não percebida | O firmware de exemplo pede calibração; antes de uso prático, comparar com método de referência e registrar manutenção. |
| Leitura antiga após perda de conexão | Decisão baseada em dado desatualizado | A interface mostra estado de conexão e horário da leitura; a reconexão é tentada automaticamente. |
| Compartilhamento indiscriminado de dados | Exposição de rotinas e locais de coleta, se agregados a outras informações | Histórico fica no aparelho; exportação é acionada pelo usuário. Orientar compartilhamento apenas com quem precisa analisar. |
| Coleta de dados mais frequente que o necessário | Maior armazenamento e gasto de energia | Salvamento automático limitado a uma amostra a cada cinco segundos; limpeza do histórico disponível. |

O projeto não usa modelo de inteligência artificial para classificar água. O estado de qualidade vem de regras e limites ajustáveis em [`water_quality_settings.dart`](../lib/models/water_quality_settings.dart). Isso torna a decisão inspecionável, mas não a torna universal ou clinicamente válida.

## Relatório de vieses

| Fonte de viés | Quem ou o que pode ser prejudicado | Como verificar e reduzir |
| --- | --- | --- |
| **Ponto de coleta:** um sensor representa apenas o local e momento medidos. | Comunidades com fontes ou trechos diferentes. | Registrar local e condições de coleta fora do app, repetir medições em vários pontos antes de generalizar. |
| **Parâmetros disponíveis:** pH, turbidez, TDS e oxigênio não cobrem contaminantes microbiológicos e químicos específicos. | Pessoas que interpretam todos os valores “adequados” como água potável. | Manter aviso de limite da solução e encaminhar para análise laboratorial quando houver suspeita. |
| **Limites padrão:** faixas didáticas podem não servir a todos os usos da água ou normas. | Usuários em contextos diferentes do previsto. | Permitir ajuste de faixas com orientação técnica; documentar os valores usados em cada avaliação. |
| **Hardware e calibração:** sondas baratas, envelhecidas ou mal calibradas podem produzir desvio sistemático. | Regiões com menos recursos para manutenção. | Comparar periodicamente com referência e registrar data de calibração; não usar o resultado como única evidência. |
| **Acesso digital:** o produto exige Android e, para leitura real, sensor BLE. | Pessoas sem aparelho compatível ou orçamento para sensores. | Compartilhar resultados por meios acessíveis e avaliar custo total antes de implantação comunitária. |

## Estado da evidência

Este documento identifica riscos do desenho atual; não registra validação de campo, auditoria de acessibilidade ou comparação laboratorial concluída. Esses passos estão no [diário](diario/aula-06.md) como próximos trabalhos.
