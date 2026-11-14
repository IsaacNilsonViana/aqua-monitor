import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/water_monitor_controller.dart';
import '../../models/water_quality_settings.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  bool _loaded = false;
  bool _notificationsEnabled = true;
  bool _notifyAttention = true;
  bool _backgroundMonitoringEnabled = true;
  bool _backgroundNotificationDetailsEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _load(context.read<WaterMonitorController>().settings);
      _loaded = true;
    }
  }

  void _load(WaterQualitySettings settings) {
    final values = <String, num>{
      'phIdealMin': settings.phIdealMin,
      'phIdealMax': settings.phIdealMax,
      'phCriticalMin': settings.phCriticalMin,
      'phCriticalMax': settings.phCriticalMax,
      'turbidityIdealMax': settings.turbidityIdealMax,
      'turbidityCriticalMax': settings.turbidityCriticalMax,
      'tdsIdealMax': settings.tdsIdealMax,
      'tdsCriticalMax': settings.tdsCriticalMax,
      'oxygenIdealMin': settings.oxygenIdealMin,
      'oxygenCriticalMin': settings.oxygenCriticalMin,
      'cooldown': settings.notificationCooldownMinutes,
    };
    for (final entry in values.entries) {
      final text = entry.value is int
          ? entry.value.toString()
          : (entry.value as double).toStringAsFixed(2);
      (_fields[entry.key] ??= TextEditingController()).text = text;
    }
    _notificationsEnabled = settings.notificationsEnabled;
    _notifyAttention = settings.notifyAttention;
    _backgroundMonitoringEnabled = settings.backgroundMonitoringEnabled;
    _backgroundNotificationDetailsEnabled =
        settings.backgroundNotificationDetailsEnabled;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _doubleValue(String key) =>
      double.parse(_fields[key]!.text.trim().replaceAll(',', '.'));

  int _intValue(String key) => int.parse(_fields[key]!.text.trim());

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final settings = WaterQualitySettings(
      phIdealMin: _doubleValue('phIdealMin'),
      phIdealMax: _doubleValue('phIdealMax'),
      phCriticalMin: _doubleValue('phCriticalMin'),
      phCriticalMax: _doubleValue('phCriticalMax'),
      turbidityIdealMax: _doubleValue('turbidityIdealMax'),
      turbidityCriticalMax: _doubleValue('turbidityCriticalMax'),
      tdsIdealMax: _doubleValue('tdsIdealMax'),
      tdsCriticalMax: _doubleValue('tdsCriticalMax'),
      oxygenIdealMin: _doubleValue('oxygenIdealMin'),
      oxygenCriticalMin: _doubleValue('oxygenCriticalMin'),
      notificationsEnabled: _notificationsEnabled,
      notifyAttention: _notifyAttention,
      notificationCooldownMinutes: _intValue('cooldown'),
      backgroundMonitoringEnabled: _backgroundMonitoringEnabled,
      backgroundNotificationDetailsEnabled:
          _backgroundNotificationDetailsEnabled,
    );
    final error =
        await context.read<WaterMonitorController>().updateSettings(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Configuracoes salvas.'),
        backgroundColor: error == null ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _reset() async {
    final controller = context.read<WaterMonitorController>();
    await controller.resetSettings();
    if (!mounted) return;
    setState(() => _load(controller.settings));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Limites padrao restaurados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WaterMonitorController>();
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _InfoCard(),
          const SizedBox(height: 14),
          _ParameterCard(
            title: 'pH',
            icon: Icons.science_outlined,
            children: [
              _numberField('phIdealMin', 'Ideal minimo'),
              _numberField('phIdealMax', 'Ideal maximo'),
              _numberField('phCriticalMin', 'Critico minimo'),
              _numberField('phCriticalMax', 'Critico maximo'),
            ],
          ),
          const SizedBox(height: 12),
          _ParameterCard(
            title: 'Turbidez (NTU)',
            icon: Icons.opacity,
            children: [
              _numberField('turbidityIdealMax', 'Maximo ideal'),
              _numberField('turbidityCriticalMax', 'Maximo critico'),
            ],
          ),
          const SizedBox(height: 12),
          _ParameterCard(
            title: 'TDS (ppm)',
            icon: Icons.grain,
            children: [
              _numberField('tdsIdealMax', 'Maximo ideal'),
              _numberField('tdsCriticalMax', 'Maximo critico'),
            ],
          ),
          const SizedBox(height: 12),
          _ParameterCard(
            title: 'Oxigenio dissolvido (mg/L)',
            icon: Icons.air,
            children: [
              _numberField('oxygenIdealMin', 'Minimo ideal'),
              _numberField('oxygenCriticalMin', 'Minimo critico'),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    controller.backgroundMonitoringRunning
                        ? Icons.sync
                        : Icons.sync_disabled,
                    color: controller.backgroundMonitoringRunning
                        ? AppColors.success
                        : Colors.blueGrey,
                  ),
                  title: Text(
                    controller.backgroundMonitoringRunning
                        ? 'Servico de segundo plano ativo'
                        : 'Servico de segundo plano parado',
                  ),
                  subtitle: const Text(
                    'Mantem a captura ao minimizar o app ou apagar a tela',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _backgroundMonitoringEnabled,
                  onChanged: (value) => setState(() {
                    _backgroundMonitoringEnabled = value;
                    if (!value) {
                      _backgroundNotificationDetailsEnabled = false;
                    }
                  }),
                  title: const Text('Monitoramento em segundo plano'),
                  subtitle: const Text(
                    'A alteracao e aplicada ao salvar as configuracoes',
                  ),
                  secondary: const Icon(Icons.settings_input_antenna),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _backgroundNotificationDetailsEnabled,
                  onChanged: _backgroundMonitoringEnabled
                      ? (value) => setState(
                            () => _backgroundNotificationDetailsEnabled = value,
                          )
                      : null,
                  title: const Text('Valores na notificacao fixa'),
                  subtitle: const Text(
                    'Mostrar pH e oxigenio junto do tempo e total de leituras',
                  ),
                  secondary: const Icon(Icons.notifications_outlined),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final configured = await context
                            .read<WaterMonitorController>()
                            .configureBackgroundBattery();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              configured
                                  ? 'Bateria configurada sem restricoes.'
                                  : 'Revise a permissao de bateria do Aqua Monitor.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.battery_saver_outlined),
                      label: const Text('Configurar uso da bateria'),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'O Android exige uma notificacao fixa enquanto o servico '
                    'esta ativo. Ela e silenciosa e informa perda ou retorno da '
                    'conexao.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                  title: const Text('Notificacoes Android'),
                  subtitle:
                      const Text('Alertar quando os limites forem atingidos'),
                  secondary: const Icon(Icons.notifications_active_outlined),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _notifyAttention,
                  onChanged: _notificationsEnabled
                      ? (value) => setState(() => _notifyAttention = value)
                      : null,
                  title: const Text('Notificar tambem em atencao'),
                  subtitle: const Text(
                      'Desative para receber apenas alertas criticos'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: _numberField(
                    'cooldown',
                    'Intervalo minimo entre alertas (minutos)',
                    integer: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _notificationsEnabled
                          ? () async {
                              final sent = await context
                                  .read<WaterMonitorController>()
                                  .sendTestNotification();
                              if (context.mounted && !sent) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Permita notificacoes nas configuracoes do Android.',
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.notifications_none),
                      label: const Text('Testar notificacao'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Salvar configuracoes'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar valores padrao'),
          ),
        ],
      ),
    );
  }

  Widget _numberField(String key, String label, {bool integer = false}) {
    return TextFormField(
      controller: _fields[key],
      keyboardType: TextInputType.numberWithOptions(
        decimal: !integer,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          integer ? RegExp(r'[0-9]') : RegExp(r'[0-9,.]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Informe um valor';
        final normalized = value.trim().replaceAll(',', '.');
        if (integer
            ? int.tryParse(normalized) == null
            : double.tryParse(normalized) == null) {
          return 'Valor invalido';
        }
        return null;
      },
    );
  }
}

class _ParameterCard extends StatelessWidget {
  const _ParameterCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.blue),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tune, color: AppColors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verde indica a faixa ideal, amarelo fica entre o ideal e o '
                'critico, e vermelho indica que o limite critico foi ultrapassado.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
