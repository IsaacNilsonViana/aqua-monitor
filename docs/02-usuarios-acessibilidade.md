# Mapa de usuários e acessibilidade

## Usuário primário

Pessoa ou equipe que acompanha um ponto de água em pequena comunidade, escola ou projeto local. Precisa perceber mudanças, consultar o histórico e saber quando solicitar uma verificação mais confiável. Pode trabalhar em local sem internet; precisa de celular Android e sensor compatível para leituras reais.

## Mapa de usuários

| Pessoa ou grupo | Necessidade | Uso previsto | Limite ou risco |
| --- | --- | --- | --- |
| Responsável local pelo monitoramento | Observar leituras e desvios com rapidez | Parear o ESP32, consultar painel e alertas, salvar leituras | Pode interpretar um indicador como laudo de potabilidade. |
| Equipe de saúde, escola ou comunidade | Comunicar alteração e planejar nova coleta | Receber histórico exportado em CSV/JSON | Dados podem ser repassados sem contexto de calibração, local e data. |
| Pessoa que faz análise técnica | Investigar tendências e validar medições | Comparar histórico com nova coleta e método de referência | Sensor de baixo custo pode ter deriva e erro sistemático. |
| Pessoas afetadas pela água monitorada | Receber informação compreensível e no tempo certo | Benefício indireto por meio do responsável | Um único ponto de medição pode não representar toda a área. |

## Jornada principal

1. O responsável instala o [APK](../README.md#instalar-no-android) e concede as permissões necessárias.
2. Pareia um ESP32 compatível ou usa o modo **Demonstração** para conhecer o aplicativo.
3. Confere o estado de conexão, a hora da leitura e os valores com unidades no painel.
4. Ajusta limites conforme o contexto técnico, observa alertas, consulta o histórico e exporta os dados quando necessário.

## Acessibilidade e inclusão

- O painel combina texto, valores e estado; a leitura não deve depender apenas de cor. A implementação atual mostra rótulos de qualidade e estados de conexão, mas ainda precisa de avaliação com leitores de tela e pessoas com baixa visão.
- O funcionamento sem internet reduz uma barreira em campo, mas não elimina o custo de celular, ESP32, sondas e calibração.
- Unidades e limites devem ser explicados em linguagem simples; notificações precisam indicar qual parâmetro mudou, sem afirmar que a água é segura ou imprópria para consumo.
- Os testes com usuários devem incluir diferentes níveis de familiaridade com tecnologia, tamanhos de tela e condições de conectividade.

**Próximo teste de acessibilidade:** verificar navegação por TalkBack, ampliação de fonte, contraste e compreensão dos alertas com usuários reais. Essas verificações ainda não foram registradas como concluídas.
