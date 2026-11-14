# Arquitetura e canvas dos três eixos

## Arquitetura em três caixas

```text
┌──────────────────────────────┐    ┌─────────────────────────────────┐    ┌───────────────────────────────┐
│ ENTRADA                      │ -> │ PROCESSAMENTO                  │ -> │ SAÍDA                         │
│ Sondas + ESP32 via BLE       │    │ Parser, validação, classificação│    │ Painel, alerta, histórico,    │
│ ou modo Demonstração         │    │ por limites e SQLite no Android│    │ exportação CSV/JSON           │
└──────────────────────────────┘    └─────────────────────────────────┘    └───────────────────────────────┘
```

**Fluxo real:** o [`BleWaterService`](../lib/services/ble_water_service.dart) recebe pacotes BLE do [firmware](../firmware/esp32_example.ino); o parser os transforma em leituras; o [`WaterMonitorController`](../lib/controllers/water_monitor_controller.dart) aplica os limites de [`WaterQualitySettings`](../lib/models/water_quality_settings.dart); [`ReadingRepository`](../lib/data/reading_repository.dart) grava no SQLite; as telas mostram estado, valores e histórico; [`ExportService`](../lib/services/export_service.dart) gera CSV/JSON. O modo Demonstração produz dados simulados e deve ser identificado como tal.

## Canvas — eixo Computação

| Campo | Preenchimento |
| --- | --- |
| Entrada e contrato | ESP32 envia pH, turbidez, TDS e oxigênio dissolvido opcional em JSON ou CSV, terminado por quebra de linha, via característica BLE Notify. |
| Processamento | Parser rejeita pacote inválido; limites configuráveis produzem estado adequado, atenção ou alerta; uma amostra automática a cada cinco segundos pode ser gravada. |
| Armazenamento e saída | SQLite local, painel em tempo real, notificações e exportação CSV/JSON. |
| Requisito principal | Uso sem internet e leitura compreensível no Android. |
| Falhas e mitigação | Perda de BLE gera estado de conexão e até cinco tentativas de reconexão; horário da leitura ajuda a identificar dado antigo. Sensor sem calibração permanece risco. |
| Critério de verificação | `flutter test` e `flutter analyze`; em campo, testar pareamento, interrupção da conexão, alertas e exportação com sensor calibrado. |

## Canvas — eixo Sociedade

| Campo | Preenchimento |
| --- | --- |
| Público e necessidade | Responsável local por um ponto de água precisa de aviso rápido e histórico para solicitar investigação. |
| Benefício esperado | Facilitar o acompanhamento em locais com internet limitada e compartilhar evidências de alteração. |
| Acesso e inclusão | APK Android e modo offline ajudam no uso em campo; celular, ESP32 e sondas ainda representam custo. Verificar TalkBack, fonte ampliada e compreensão dos alertas. |
| Ética e dados | Histórico fica no aparelho e só é exportado por ação do usuário; quem compartilha deve contextualizar local, data e calibração. |
| Limite de comunicação | Estado “adequado” significa apenas dentro dos limites configurados para os parâmetros medidos; não é atestado de potabilidade. |
| Verificação com pessoas | Observar se usuários diferenciam Demonstração de leitura real e se entendem o que fazer após alerta. |

## Canvas — eixo Meio Ambiente

| Campo | Preenchimento |
| --- | --- |
| Relação com o ODS 14 | Acompanhar mudanças na água pode apoiar a investigação de poluição e proteger ecossistemas aquáticos. |
| Indicadores disponíveis | pH, turbidez, TDS e oxigênio dissolvido; não identificam sozinhos a causa ou todos os impactos ambientais. |
| Consumo de recursos | ESP32, sondas e celular consomem energia e têm vida útil; coleta e armazenamento frequentes aumentam consumo. |
| Redução de impacto | Salvar no máximo uma amostra automática a cada cinco segundos, permitir limpeza do histórico, manter hardware e calibrar em vez de descartar sondas sem avaliação. |
| Risco ambiental | Medição incorreta pode direcionar uma resposta inadequada; validar dados antes de atribuir fonte de contaminação. |
| Verificação | Medir autonomia do conjunto em uso real e comparar leituras com referências em pontos e períodos diferentes. |

## Decisão rastreável

A escolha por **BLE + processamento e histórico locais no Android** está registrada em [ADR-001](decisoes/ADR-001-monitoramento-local-ble.md), incluindo o impacto nos três eixos. O [mapa ODS × tecnologia](01-problema-e-ods.md) mostra de onde partiu a proposta.
