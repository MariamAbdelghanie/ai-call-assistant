import 'package:material_ui/material_ui.dart';

import 'app_controller.dart';
import 'models/call_record.dart';

void main() => runApp(const CallAssistantApp());

class CallAssistantApp extends StatefulWidget {
  const CallAssistantApp({super.key});

  @override
  State<CallAssistantApp> createState() => _CallAssistantAppState();
}

class _CallAssistantAppState extends State<CallAssistantApp> {
  final AppController controller = AppController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_update);
  }

  @override
  void dispose() {
    controller.removeListener(_update);
    controller.dispose();
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Çağrı Asistanı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1d4ed8)),
        useMaterial3: true,
      ),
      home: controller.isSignedIn
          ? HomeShell(controller: controller)
          : LoginScreen(controller: controller),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final TextEditingController _url;
  late final TextEditingController _token;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.controller.serverUrl);
    _token = TextEditingController(text: widget.controller.adminToken);
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.controller.serverUrl = _url.text.trim();
    widget.controller.adminToken = _token.text.trim();
    await widget.controller.signIn(_name.text);
    await widget.controller.connectAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.support_agent, size: 72, color: Color(0xff1d4ed8)),
                    const SizedBox(height: 16),
                    Text('Telefon sahibi hesabı', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text('Çağrı asistanını ve kayıtlarını yönetmek için giriş yapın.', textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Adınız', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Ad alanı zorunludur.' : null,
                    ),
                    const SizedBox(height: 12),
                    ExpansionTile(
                      title: const Text('Sunucu bağlantısı (isteğe bağlı)'),
                      subtitle: const Text('Bağlantı yoksa güvenli demo verileri gösterilir.'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _url,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(labelText: 'Backend adresi', hintText: 'http://10.0.2.2:8080', border: OutlineInputBorder()),
                          ),
                        ),
                        TextFormField(
                          controller: _token,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Yönetim anahtarı', border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                    if (widget.controller.error != null) ...[
                      const SizedBox(height: 12),
                      Text(widget.controller.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: widget.controller.loading ? null : _continue,
                      icon: widget.controller.loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                      label: Text(widget.controller.loading ? 'Bağlanılıyor…' : 'Devam et'),
                    ),
                    const SizedBox(height: 14),
                    const Text('Not: Bu ilk sürümde ad alanı yerel oturum içindir. Gerçek parola/SSO girişi, kimlik sağlayıcısı (ör. Firebase Auth) bağlandığında etkinleştirilir.', style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(controller: widget.controller, showCalls: () => setState(() => index = 1)),
      CallHistoryScreen(controller: widget.controller),
      AppointmentScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
      PrivacyScreen(controller: widget.controller),
    ];
    final titles = ['Genel bakış', 'Çağrı geçmişi', 'Randevular', 'Ayarlar', 'Gizlilik'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: widget.controller.loading ? null : widget.controller.connectAndLoad,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana sayfa'),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Çağrılar'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Randevu'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ayarlar'),
          NavigationDestination(icon: Icon(Icons.privacy_tip_outlined), selectedIcon: Icon(Icons.privacy_tip), label: 'Gizlilik'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller, required this.showCalls});
  final AppController controller;
  final VoidCallback showCalls;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: controller.assistantEnabled ? const Color(0xffdcfce7) : const Color(0xffffe4e6),
          child: SwitchListTile(
            value: controller.assistantEnabled,
            onChanged: (value) => controller.saveAssistantSettings(enabled: value, greetingText: controller.greeting, start: controller.workStart, end: controller.workEnd),
            title: Text(controller.assistantEnabled ? 'Asistan aktif' : 'Asistan pasif'),
            subtitle: Text(controller.assistantEnabled ? 'Çağrılar çalışma saatlerinde yanıtlanır.' : 'Yeni çağrılar asistan tarafından yanıtlanmaz.'),
          ),
        ),
        if (controller.urgentCount > 0) ...[
          const SizedBox(height: 12),
          Card(
            color: const Color(0xffffe4e6),
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Color(0xffbe123c), size: 36),
              title: Text('${controller.urgentCount} acil çağrı bildirimi'),
              subtitle: const Text('Bu çağrılar için arama geçmişini hemen inceleyin. Hayati riskte 112 yönlendirmesi yapılır.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: showCalls,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(icon: Icons.phone_callback, label: 'Geri dönüş bekleyen', value: '${controller.pendingCallbackCount}')),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(icon: Icons.event_available, label: 'Randevu', value: '${controller.appointments.length}')),
          ],
        ),
        const SizedBox(height: 20),
        Text('Bugünkü ayarlar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.schedule),
            title: Text('${controller.workStart} – ${controller.workEnd}'),
            subtitle: Text('Karşılama: ${controller.greeting}'),
          ),
        ),
        if (controller.useDemoData) ...[
          const SizedBox(height: 16),
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Demo verileri gösteriliyor. Ayarlar > API bağlantısı ile yerel backend’e bağlanabilirsin.'))),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ]),
        ),
      );
}

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.calls.isEmpty) return const Center(child: Text('Henüz çağrı kaydı yok.'));
    return RefreshIndicator(
      onRefresh: controller.connectAndLoad,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: controller.calls.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final call = controller.calls[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: call.urgent ? const Color(0xffffe4e6) : null,
                child: Icon(call.urgent ? Icons.warning_amber_rounded : Icons.person, color: call.urgent ? const Color(0xffbe123c) : null),
              ),
              title: Text(call.callerName),
              subtitle: Text('${call.summary}\n${_dateTime(call.createdAt)}${call.calledBack ? ' • Geri arandı' : call.callbackRequested ? ' • Geri dönüş bekleniyor' : ''}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallDetailScreen(controller: controller, call: call))),
            ),
          );
        },
      ),
    );
  }
}

class CallDetailScreen extends StatelessWidget {
  const CallDetailScreen({super.key, required this.controller, required this.call});
  final AppController controller;
  final CallRecord call;

  @override
  Widget build(BuildContext context) {
    final current = controller.calls.firstWhere((item) => item.id == call.id, orElse: () => call);
    return Scaffold(
      appBar: AppBar(title: const Text('Çağrı detayı')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (current.urgent) const Card(color: Color(0xffffe4e6), child: ListTile(leading: Icon(Icons.warning_amber_rounded, color: Color(0xffbe123c)), title: Text('Acil çağrı bildirimi'), subtitle: Text('Hayati tehlike içeren durumlarda 112 yönlendirmesi önceliklidir.'))),
          _DetailRow(label: 'Arayan', value: current.callerName),
          _DetailRow(label: 'Telefon', value: current.phone.isEmpty ? 'Belirtilmedi' : current.phone),
          _DetailRow(label: 'Tarih', value: _dateTime(current.createdAt)),
          _DetailRow(label: 'Özet', value: current.summary),
          if (current.appointmentAt != null) _DetailRow(label: 'Randevu', value: _dateTime(current.appointmentAt!)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: current.calledBack ? null : () async {
              final ok = await controller.setCalledBack(current, true);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Geri arandı olarak işaretlendi.' : controller.error ?? 'İşlem tamamlanamadı.')));
            },
            icon: const Icon(Icons.phone_callback),
            label: Text(current.calledBack ? 'Geri arandı' : 'Geri arandı olarak işaretle'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 4), Text(value)]),
      );
}

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final appointments = controller.appointments;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Randevu kaynağı'), subtitle: Text('Çağrıdan alınan randevu notları burada gösterilir. Google Calendar bağlantısı geldiğinde takvimle eşitlenir.'))),
        const SizedBox(height: 12),
        if (appointments.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Yaklaşan randevu yok.'))),
        ...appointments.map((call) => Card(child: ListTile(leading: const Icon(Icons.event), title: Text(call.callerName), subtitle: Text('${_dateTime(call.appointmentAt!)}\n${call.summary}'), isThreeLine: true))),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool enabled;
  late final TextEditingController greeting;
  late final TextEditingController start;
  late final TextEditingController end;
  late final TextEditingController url;
  late final TextEditingController token;

  @override
  void initState() {
    super.initState();
    enabled = widget.controller.assistantEnabled;
    greeting = TextEditingController(text: widget.controller.greeting);
    start = TextEditingController(text: widget.controller.workStart);
    end = TextEditingController(text: widget.controller.workEnd);
    url = TextEditingController(text: widget.controller.serverUrl);
    token = TextEditingController(text: widget.controller.adminToken);
  }

  @override
  void dispose() { greeting.dispose(); start.dispose(); end.dispose(); url.dispose(); token.dispose(); super.dispose(); }

  Future<void> _save() async {
    widget.controller.serverUrl = url.text.trim();
    widget.controller.adminToken = token.text.trim();
    final ok = await widget.controller.saveAssistantSettings(enabled: enabled, greetingText: greeting.text, start: start.text, end: end.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Ayarlar kaydedildi.' : widget.controller.error ?? 'Ayarlar kaydedilemedi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(value: enabled, onChanged: (value) => setState(() => enabled = value), title: const Text('Asistan aktif'), subtitle: const Text('Kapalıyken asistan yeni çağrıları yanıtlamaz.')),
          const SizedBox(height: 12),
          TextField(controller: greeting, maxLines: 3, decoration: const InputDecoration(labelText: 'Karşılama mesajı', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: TextField(controller: start, decoration: const InputDecoration(labelText: 'Başlangıç', hintText: '09:00', border: OutlineInputBorder()))), const SizedBox(width: 12), Expanded(child: TextField(controller: end, decoration: const InputDecoration(labelText: 'Bitiş', hintText: '18:00', border: OutlineInputBorder())))]),
          const SizedBox(height: 24),
          Text('API bağlantısı', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: url, decoration: const InputDecoration(labelText: 'Backend adresi', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: token, obscureText: true, decoration: const InputDecoration(labelText: 'Yönetim anahtarı', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: widget.controller.connectAndLoad, icon: const Icon(Icons.sync), label: const Text('Sunucudan ayarları al')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Ayarları kaydet')),
        ],
      );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(child: ListTile(leading: Icon(Icons.shield_outlined), title: Text('Kayıt ve onay'), subtitle: Text('Arayanın kayıt izni yoksa yalnızca geri dönüş talebi saklanır. Çağrı özeti teyit edilmeden kayıt tamamlanmaz.'))),
          const Card(child: ListTile(leading: Icon(Icons.lock_outline), title: Text('Erişim'), subtitle: Text('Backend yalnızca yerel bağlantı veya yönetim anahtarıyla erişime izin verir. Üretimde gerçek kullanıcı oturumu eklenmelidir.'))),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Demo çağrı verilerini sil'),
            onPressed: () async {
              final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Veriler silinsin mi?'), content: const Text('Bu işlem demo çağrı kayıtlarını geri alınamaz şekilde siler.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil'))]));
              if (confirmed != true) return;
              final ok = await controller.deleteAllData();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Demo verileri silindi.' : controller.error ?? 'Silme tamamlanamadı.')));
            },
          ),
        ],
      );
}

String _dateTime(DateTime value) => '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
