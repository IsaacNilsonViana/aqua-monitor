# Aqua Monitor

## Instalar no Android

[Baixar o APK da versao mais recente](https://github.com/IsaacNilsonViana/aqua-monitor/releases/latest/download/aqua-monitor-v1.3.0.apk)

Baixe o arquivo no celular e abra-o para instalar. Se o Android solicitar, autorize a instalacao de apps desta origem. O APK pode ser usado no modo **Demonstracao** sem o sensor; para leituras reais, e necessario um ESP32 compativel via Bluetooth.

Esta versao academica usa assinatura de debug para facilitar a instalacao direta. As medidas do firmware de exemplo exigem calibracao das sondas antes de qualquer uso pratico.

Aplicativo Android Flutter para monitoramento de pH, turbidez, TDS e oxigenio
dissolvido em tempo real por Bluetooth Low Energy (BLE). O projeto e
nativo/compilado; nao usa WebView e funciona sem internet.

## Arquitetura escolhida

Flutter foi escolhido porque gera um APK Android nativo a partir de uma unica
base, oferece uma UI consistente para uso em campo e possui bibliotecas maduras
para BLE e SQLite. A organizacao separa responsabilidades:

```text
ESP32 / Arduino (BLE notify)
            |
            v
BleWaterService -> WaterMonitorController -> telas Flutter
                              |
                              v
                    ReadingRepository -> SQLite
```

Pacotes principais:

- `flutter_reactive_ble`: busca, conexao, notificacoes e reconexao BLE;
- `permission_handler`: permissoes Bluetooth/localizacao por versao do Android;
- `sqflite` + `path`: banco de dados local;
- `provider`: estado reativo entre servicos e telas;
- `shared_preferences`: limites e preferencias de alerta persistentes;
- `flutter_local_notifications`: alertas Android por qualidade fora da faixa;
- `flutter_foreground_task`: servico Android persistente para manter a captura
  BLE ativa com a tela apagada ou o aplicativo minimizado;
- `path_provider` + `share_plus`: criacao e compartilhamento de CSV/JSON;
- `intl`: datas e horas em `pt_BR`.

## Estrutura

```text
lib/
  config/       UUIDs e contrato BLE
  controllers/  estado e regras do aplicativo
  data/         SQLite e repositorio
  models/       leitura, dispositivo e status
  services/     BLE, parser e exportacao
  theme/        cores e tema Material 3
  ui/
    screens/    Tempo Real, Pareamento e Historico
    widgets/    componentes reutilizaveis
android/        manifesto, permissoes e build nativo
firmware/       exemplo funcional para ESP32
scripts/        preparacao do Gradle e geracao do APK
test/           testes do parser e classificacao
```

## Contrato com o sensor

O ESP32 anuncia o nome `AquaSensor` e o servico BLE:

```text
Service: 6e400001-b5a3-f393-e0a9-e50e24dcca9e
Write:   6e400002-b5a3-f393-e0a9-e50e24dcca9e
Notify:  6e400003-b5a3-f393-e0a9-e50e24dcca9e
```

A caracteristica Notify envia UTF-8, sempre terminando em quebra de linha:

```json
{"ph":7.12,"turbidity":2.40,"tds":238.0,"oxygen":6.35}
```

Tambem e aceito CSV: `7.12,2.40,238.0,6.35\n`. `oxygen` representa oxigenio
dissolvido em mg/L e e opcional para compatibilidade com o firmware antigo. O
parser trata fragmentacao de pacotes BLE. Para trocar os UUIDs, altere
`lib/config/ble_config.dart` e o firmware ao mesmo tempo.

O exemplo [firmware/esp32_example.ino](firmware/esp32_example.ino) usa a
biblioteca NimBLE-Arduino. As formulas analogicas sao pontos de partida e
precisam ser calibradas com as sondas reais.

## Preparar o ambiente

1. Instale Git, JDK 17 e Android Studio. No Android Studio, instale Android SDK,
   Platform Tools e pelo menos uma plataforma Android recente.
2. Baixe o Flutter Stable pelo guia oficial e adicione `flutter/bin` ao `PATH`.
3. Aceite as licencas e confira o ambiente:

   ```bash
   flutter doctor
   flutter doctor --android-licenses
   ```

4. Na raiz deste projeto, prepare o Gradle Wrapper e baixe as dependencias:

   ```bash
   chmod +x scripts/*.sh
   ./scripts/bootstrap_android.sh
   flutter pub get
   ```

O bootstrap apenas copia o Gradle Wrapper oficial gerado pela versao instalada
do Flutter. Ele nao sobrescreve o manifesto ou o codigo deste app.

### Fedora

Uma base comum e:

```bash
sudo dnf install git java-17-openjdk-devel clang cmake ninja-build gtk3-devel
```

No Windows, instale Android Studio e Flutter, abra um PowerShell na pasta e rode
os comandos Flutter manualmente; o script Bash pode ser executado pelo Git Bash.

## Executar

Conecte um Android fisico com Depuracao USB (BLE nao funciona adequadamente no
emulador), confirme com `adb devices` e execute:

```bash
flutter run
```

No primeiro uso, autorize Dispositivos proximos e, em Android antigo,
Localizacao. Autorize tambem as notificacoes e permita que o Aqua Monitor ignore
a otimizacao de bateria; isso e especialmente importante em aparelhos Xiaomi,
Redmi e POCO. Na aba **Pareamento**, toque em **Buscar BLE**. Para apresentar o
app sem ESP32, toque em **Demonstracao**.

## Gerar e instalar o APK

O caminho automatizado roda analise e testes antes do build:

```bash
./scripts/build_apk.sh
```

O resultado fica em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Instalacao por cabo USB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Ou gere manualmente:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

O `release` academico esta assinado com a chave de debug para ser instalavel
imediatamente. Para publicar na Play Store, crie um keystore privado, configure
`android/key.properties` e troque `signingConfig` no `android/app/build.gradle`.
Para a loja, prefira `flutter build appbundle`.

## Comportamento do aplicativo

- Atualizacao instantanea a cada notificacao BLE;
- reconexao automatica com espera progressiva, ate cinco tentativas;
- servico Android do tipo `connectedDevice`, com captura mantida ao minimizar o
  app ou apagar a tela;
- notificacao fixa e silenciosa com tempo ativo, total de leituras e ultimos
  valores de pH/O2; o titulo muda ao conectar, perder sinal ou reconectar;
- controles nos Ajustes para ativar/desativar o servico em segundo plano,
  ocultar pH/O2 da notificacao fixa e revisar a restricao de bateria;
- aviso visual de conexao, erro ou modo demonstracao;
- salvamento automatico limitado a uma amostra a cada 5 segundos e botao de
  salvamento manual;
- historico SQLite ordenado do mais recente para o mais antigo;
- marcacao individual, em amarelo ou vermelho, dos parametros historicos que
  estiverem fora dos limites configurados;
- limpeza segura por antiguidade, preservando os ultimos 7, 30, 90 ou 180 dias,
  ou todas as leituras a partir de uma data escolhida;
- exclusao por gesto lateral e limpeza completa com confirmacao;
- exportacao CSV (compativel com Excel em UTF-8) e JSON pelo compartilhamento do
  Android;
- configuracao persistente de faixas ideais e criticas para cada parametro;
- notificacoes configuraveis para atencao/critico, com intervalo antirrepeticao;
- faixas iniciais: pH 6,5-8,5, turbidez ate 5 NTU, TDS ate 500 ppm e oxigenio
  dissolvido a partir de 5 mg/L (critico abaixo de 3 mg/L).

As faixas sao referencias didaticas configuradas em
`lib/models/water_quality_settings.dart` e podem ser alteradas na aba
**Ajustes**; potabilidade real depende da norma aplicavel, calibracao,
temperatura, metodo de coleta e analise laboratorial.

## Solucao de problemas

- **Nenhum sensor aparece:** ative Bluetooth/localizacao, conceda as permissoes,
  confirme o UUID no firmware e aproxime o ESP32.
- **Valores nao atualizam:** confirme que a caracteristica Notify esta ativa e
  que cada pacote termina com `\n`.
- **Build reclama do Java:** selecione JDK 17 no Android Studio/`JAVA_HOME`.
- **Gradle Wrapper ausente:** execute `./scripts/bootstrap_android.sh`.
- **Banco antigo durante desenvolvimento:** desinstale o app para recriar o
  SQLite ou aumente a versao/migracao em `local_database.dart`.
- **Captura para ao bloquear a tela:** nas configuracoes do Android, deixe a
  bateria do Aqua Monitor como **Sem restricoes** e autorize notificacoes. O
  comando **Forcar parada** sempre interrompe qualquer app e servico Android;
  nesse caso, abra o Aqua Monitor novamente.

