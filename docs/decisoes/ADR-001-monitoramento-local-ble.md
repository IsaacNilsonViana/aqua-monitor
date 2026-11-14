# ADR-001 — Monitoramento local por BLE e histórico no Android

- **Estado:** aceita e implementada no MVP.
- **Contexto:** o grupo queria acompanhar a qualidade da água com avisos rápidos, inclusive em locais sem internet. O [mapa ODS × tecnologia](../01-problema-e-ods.md) aponta falta de opções acessíveis para pequenas comunidades.

## Decisão

Usar ESP32 com notificações Bluetooth Low Energy para enviar leituras ao aplicativo Flutter no Android. Processar os pacotes e comparar os valores com limites configuráveis no próprio aparelho. Guardar o histórico em SQLite local e exportar CSV/JSON apenas por ação do usuário.

## Alternativas consideradas

- **Enviar tudo para um servidor:** permitiria acesso remoto e agregação entre aparelhos, mas dependeria de conectividade, infraestrutura e gestão de dados compartilhados.
- **Registrar apenas no ESP32:** simplificaria o aplicativo, mas dificultaria a leitura do histórico, os alertas e o compartilhamento dos dados.

## Consequências e impactos nos três eixos

| Eixo | Impacto positivo | Custo, limite e cuidado |
| --- | --- | --- |
| Computação | O app funciona offline; o fluxo BLE, parser, regras e SQLite pode ser testado separadamente. | BLE exige permissões e pode perder conexão; Android e firmware devem manter o mesmo contrato de pacotes. |
| Sociedade | A pessoa no local vê estado e histórico sem depender de internet; exportação é voluntária. | Exige celular Android e sensor; avisos podem ser mal interpretados como garantia de potabilidade. A interface deve mostrar horário, origem e limites. |
| Meio Ambiente | A detecção de alterações pode apoiar investigação de impactos em corpos d'água. | ESP32, sondas, bateria e celular consomem recursos; a amostragem e manutenção devem ser proporcionais ao uso. Leitura sem calibração pode levar a conclusão ambiental errada. |

## Evidência no repositório

[`firmware/esp32_example.ino`](../../firmware/esp32_example.ino), [`BleWaterService`](../../lib/services/ble_water_service.dart), [`WaterMonitorController`](../../lib/controllers/water_monitor_controller.dart), [`LocalDatabase`](../../lib/data/local_database.dart) e o [README](../../README.md) documentam e implementam esta decisão.
