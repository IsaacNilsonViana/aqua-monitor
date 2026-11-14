/*
 * Firmware de referencia para ESP32 + Arduino Core.
 * Biblioteca: NimBLE-Arduino (instale pelo Library Manager da Arduino IDE).
 *
 * IMPORTANTE: as conversoes abaixo sao exemplos. Calibre cada sonda com
 * solucoes padrao e ajuste PH_OFFSET/TDS_FACTOR/curva de turbidez.
 */
#include <Arduino.h>
#include <NimBLEDevice.h>

static const char *DEVICE_NAME = "AquaSensor";
static const char *SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
static const char *COMMAND_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
static const char *DATA_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

constexpr int PH_PIN = 34;
constexpr int TURBIDITY_PIN = 35;
constexpr int TDS_PIN = 32;
constexpr int DO_PIN = 33;
constexpr float ADC_REFERENCE = 3.3f;
constexpr float ADC_MAX = 4095.0f;
constexpr float PH_OFFSET = 0.0f;
constexpr float TDS_FACTOR = 0.5f;

NimBLECharacteristic *dataCharacteristic = nullptr;

float readVoltage(int pin) {
  // Media simples para reduzir ruido instantaneo do ADC.
  uint32_t total = 0;
  for (int i = 0; i < 20; i++) {
    total += analogRead(pin);
    delay(2);
  }
  return (total / 20.0f) * ADC_REFERENCE / ADC_MAX;
}

float readPh() {
  const float voltage = readVoltage(PH_PIN);
  // Exemplo de modulo analogico com 2,5 V em pH 7 e ~0,18 V/pH.
  return 7.0f + ((2.5f - voltage) / 0.18f) + PH_OFFSET;
}

float readTurbidityNtu() {
  const float voltage = readVoltage(TURBIDITY_PIN);
  // Aproximacao para demonstracao; substitua pela curva do seu sensor.
  const float ntu = (3.0f - voltage) * 100.0f;
  return max(0.0f, ntu);
}

float readTdsPpm() {
  const float voltage = readVoltage(TDS_PIN);
  // Formula comum para sonda TDS analogica a 25 C.
  const float compensated = voltage;
  const float value = (133.42f * pow(compensated, 3) -
                       255.86f * pow(compensated, 2) +
                       857.39f * compensated) * TDS_FACTOR;
  return max(0.0f, value);
}

float readDissolvedOxygenMgL() {
  const float voltage = readVoltage(DO_PIN);
  // Exemplo linear para modulo analogico de oxigenio dissolvido. Calibre o
  // zero e a saturacao com a sonda real e compense pela temperatura da agua.
  constexpr float ZERO_VOLTAGE = 0.15f;
  constexpr float SATURATION_VOLTAGE = 2.0f;
  constexpr float SATURATION_MG_L = 8.26f; // aproximacao a 25 C
  const float oxygen =
      (voltage - ZERO_VOLTAGE) * SATURATION_MG_L /
      (SATURATION_VOLTAGE - ZERO_VOLTAGE);
  return max(0.0f, oxygen);
}

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  NimBLEDevice::init(DEVICE_NAME);
  NimBLEServer *server = NimBLEDevice::createServer();
  NimBLEService *service = server->createService(SERVICE_UUID);

  service->createCharacteristic(
      COMMAND_UUID,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
  dataCharacteristic = service->createCharacteristic(
      DATA_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);

  service->start();
  NimBLEAdvertising *advertising = NimBLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setName(DEVICE_NAME);
  advertising->enableScanResponse(true);
  advertising->start();

  Serial.println("AquaSensor BLE pronto.");
}

void loop() {
  const float ph = constrain(readPh(), 0.0f, 14.0f);
  const float turbidity = readTurbidityNtu();
  const float tds = readTdsPpm();
  const float oxygen = readDissolvedOxygenMgL();

  // O '\n' e obrigatorio: o app o usa para separar pacotes BLE fragmentados.
  char payload[128];
  snprintf(payload, sizeof(payload),
           "{\"ph\":%.2f,\"turbidity\":%.2f,\"tds\":%.1f,"
           "\"oxygen\":%.2f}\n",
           ph, turbidity, tds, oxygen);

  dataCharacteristic->setValue(
      reinterpret_cast<const uint8_t *>(payload), strlen(payload));
  dataCharacteristic->notify();
  Serial.print(payload);
  delay(2000);
}

