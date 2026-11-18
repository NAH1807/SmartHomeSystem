import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../models/automation.dart';
import '../providers/device.dart';

class AutomationScreen extends StatefulWidget {
  final int deviceId;

  const AutomationScreen({super.key, required this.deviceId});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  bool _enabled = false;
  bool _saving = false;
  bool _loading = true;

  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _selectedOffTime = const TimeOfDay(hour: 22, minute: 0);

  final List<bool> _selectedDays = List<bool>.filled(7, false);

  // Fan profile
  double _temperatureOn = 30;
  double _temperatureOff = 25;

  int _defaultFanLevel = 1;
  bool _autoEnabled = false;
  String _autoMode = 'both';

  // Relay profile lấy từ backend.
  List<RelayAutomationChannel> _relayChannels = [];

  int? _profileVersion;

  final List<String> _dayNames = const [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> _shortDayNames = const [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAutomation();
    });
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadAutomation() async {
    try {
      final provider = context.read<DeviceProvider>();
      final automation = await provider.getAutomation(widget.deviceId);

      if (!mounted) return;

      final device = provider.getDeviceById(widget.deviceId);

      setState(() {
        if (automation != null) {
          _enabled = automation.enabled;
          if (device?.type == DeviceType.fan) {
            _defaultFanLevel =
                automation.defaultLevel ?? automation.fanLevel ?? 1;
            _autoEnabled = automation.autoEnabled;
            _autoMode = automation.autoMode;
            _defaultFanLevel = automation.defaultLevel!;
            _temperatureOn = automation.temperatureOn!;
            _temperatureOff = automation.temperatureOff!;
          }

          _profileVersion = automation.profileVersion;
          _setTimeFromString(automation.timeOn, isOffTime: false);
          _setTimeFromString(automation.timeOff, isOffTime: true);
          _selectedDays.fillRange(0, _selectedDays.length, false);

          for (final day in automation.daysOnWeek) {
            if (day >= 1 && day <= 7) {
              _selectedDays[day - 1] = true;
            }
          }

          // Lấy danh sách kênh thật từ profile backend.
          _relayChannels = List<RelayAutomationChannel>.from(
            automation.relayChannels,
          );
        }

        // Nếu chưa có profile Relay, tạo các mục hiển thị
        // dựa trên số kênh trạng thái mà Device đang có.
        // Không cố định danh sách 4 đèn trong giao diện.
        if (_relayChannels.isEmpty && device?.type == DeviceType.relay) {
          final currentStates = device!.relayChannels;

          _relayChannels = List.generate(
            currentStates.length,
            (index) => RelayAutomationChannel(
              channel: index + 1,
              name: 'Kênh ${index + 1}',
              enabled: false,
              timeOn: null,
              timeOff: null,
              daysOnWeek: const [],
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        _showMessage('Không thể tải cấu hình: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setTimeFromString(String? value, {required bool isOffTime}) {
    if (value == null || value.isEmpty) return;

    final parts = value.split(':');
    if (parts.length < 2) return;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return;
    }

    final time = TimeOfDay(hour: hour, minute: minute);

    if (isOffTime) {
      _selectedOffTime = time;
    } else {
      _selectedTime = time;
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final device = provider.getDeviceById(widget.deviceId);

    if (device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Automation')),
        body: const Center(child: Text('Không tìm thấy thiết bị')),
      );
    }

    final isRelay = device.type == DeviceType.relay;
    final isFan = device.type == DeviceType.fan;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Automation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDeviceHeader(device),
                const SizedBox(height: 16),

                _buildEnableCard(),

                if (_enabled) ...[
                  const SizedBox(height: 16),

                  if (isRelay) ...[
                    _buildRelayCard(),
                    const SizedBox(height: 16),
                    _buildScheduleCard(),
                  ],

                  if (isFan) ...[
                    _buildFanCard(),
                    const SizedBox(height: 16),
                    // Thẻ cấu hình thời gian
                    if (_autoMode == 'schedule' || _autoMode == 'both') ...[
                      const SizedBox(height: 16),
                      _buildScheduleCard(),
                    ],
                    // Thẻ cấu hình nhiệt độ
                    if (_autoMode == 'temperature' || _autoMode == 'both') ...[
                      const SizedBox(height: 16),
                      _buildTemperatureCard(),
                    ],
                  ],
                ],

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveAutomation,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Đang lưu...' : 'Lưu cấu hình'),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }

  // ============================================================
  // DEVICE HEADER
  // ============================================================

  Widget _buildDeviceHeader(Device device) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAFE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(device.icon, size: 30, color: const Color(0xFF536DFE)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.typeName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ENABLE AUTOMATION
  // ============================================================

  Widget _buildEnableCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        title: const Text(
          'Bật tự động hóa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(_enabled ? 'Đang hoạt động' : 'Đang tắt'),
        value: _enabled,
        onChanged: (value) {
          setState(() => _enabled = value);
        },
      ),
    );
  }

  // ============================================================
  // RELAY PROFILE
  // ============================================================

  Widget _buildRelayCard() {
    final allSelected =
        _relayChannels.isNotEmpty &&
        _relayChannels.every((item) => item.enabled);

    return _sectionCard(
      title: 'Cấu hình Relay',
      children: [
        const Text(
          'Chọn các kênh cần áp dụng lịch tự động.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),

        if (_relayChannels.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Chưa có thông tin kênh Relay. '
              'Hãy kiểm tra profile do backend trả về.',
            ),
          )
        else ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _relayChannels = _relayChannels.map((item) {
                    return RelayAutomationChannel(
                      channel: item.channel,
                      name: item.name,
                      enabled: !allSelected,
                      timeOn: item.timeOn,
                      timeOff: item.timeOff,
                      daysOnWeek: item.daysOnWeek,
                    );
                  }).toList();
                });
              },
              child: Text(allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả'),
            ),
          ),

          ..._relayChannels.asMap().entries.map((entry) {
            final index = entry.key;
            final channel = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: channel.enabled
                    ? const Color(0xFFEEF0FF)
                    : const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: CheckboxListTile(
                value: channel.enabled,
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF536DFE),
                ),
                title: Text(
                  channel.name.isNotEmpty
                      ? channel.name
                      : 'Đèn ${channel.channel}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onChanged: (value) {
                  setState(() {
                    final updated = List<RelayAutomationChannel>.from(
                      _relayChannels,
                    );

                    updated[index] = RelayAutomationChannel(
                      channel: channel.channel,
                      name: channel.name,
                      enabled: value ?? false,
                      timeOn: channel.timeOn,
                      timeOff: channel.timeOff,
                      daysOnWeek: channel.daysOnWeek,
                    );

                    _relayChannels = updated;
                  });
                },
              ),
            );
          }),

          Text(
            'Đã chọn ${_relayChannels.where((item) => item.enabled).length}'
            '/${_relayChannels.length} kênh',
            style: const TextStyle(
              color: Color(0xFF536DFE),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // FAN PROFILE
  // ============================================================
  Widget _buildFanCard() {
    return _sectionCard(
      title: 'Cấu hình quạt',
      children: [
        // Mức quạt mặc định
        Row(
          children: [
            const Expanded(
              child: Text(
                'Mức quạt mặc định',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DropdownButton<int>(
              value: _defaultFanLevel,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Tắt')),
                DropdownMenuItem(value: 1, child: Text('Mức 1')),
                DropdownMenuItem(value: 2, child: Text('Mức 2')),
                DropdownMenuItem(value: 3, child: Text('Mức 3')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _defaultFanLevel = value);
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Chế độ tự động
        Row(
          children: [
            const Expanded(
              child: Text(
                'Chế độ tự động',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DropdownButton<String>(
              value: _autoMode,
              items: const [
                DropdownMenuItem(value: 'temperature', child: Text('Nhiệt độ')),
                DropdownMenuItem(value: 'schedule', child: Text('Thời gian')),
                DropdownMenuItem(
                  value: 'both',
                  child: Text('Nhiệt độ và thời gian'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _autoMode = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SCHEDULE
  // ============================================================
  Widget _buildScheduleCard() {
    return _sectionCard(
      title: 'Lịch hoạt động',
      children: [
        _buildTimeSelector(
          title: 'Thời gian bật',
          time: _selectedTime,
          onTap: () => _selectTime(isOffTime: false),
        ),

        const SizedBox(height: 12),

        _buildTimeSelector(
          title: 'Thời gian tự tắt',
          time: _selectedOffTime,
          onTap: () => _selectTime(isOffTime: true),
        ),

        const SizedBox(height: 22),

        const Text(
          'Lặp lại vào các ngày',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 12),

        _buildDaySelector(),

        const SizedBox(height: 12),

        Text(
          _selectedDaysText(),
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: Color(0xFF536DFE)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              time.format(context),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF536DFE),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final selected = _selectedDays[index];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !selected;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF536DFE)
                  : const Color(0xFFF1F3F8),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _shortDayNames[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // FAN TEMPERATURE PROFILE
  // ============================================================

  Widget _buildTemperatureCard() {
    Widget buildTemperatureControl({
      required String title,
      required double value,
      required ValueChanged<double> onChanged,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              // Nút giảm 1°C
              IconButton(
                onPressed: value > 16 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF00ACC1),
                visualDensity: VisualDensity.compact,
              ),

              // Giá trị nhiệt độ
              Text(
                '${value.round()}°C',
                style: const TextStyle(
                  color: Color(0xFF00ACC1),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // Nút tăng 1°C
              IconButton(
                onPressed: value < 50 ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF00ACC1),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          Slider(
            min: 16,
            max: 50,
            divisions: 34,
            value: value,
            label: '${value.round()}°C',
            activeColor: const Color(0xFF00ACC1),
            onChanged: onChanged,
          ),
        ],
      );
    }

    return _sectionCard(
      title: 'Nhiệt độ tự động',
      children: [
        buildTemperatureControl(
          title: 'Nhiệt độ bật',
          value: _temperatureOn,
          onChanged: (value) {
            setState(() => _temperatureOn = value);
          },
        ),

        const SizedBox(height: 12),

        buildTemperatureControl(
          title: 'Nhiệt độ tắt',
          value: _temperatureOff,
          onChanged: (value) {
            setState(() => _temperatureOff = value);
          },
        ),

        const Text(
          'Thiết bị bật khi nhiệt độ đạt ngưỡng bật '
          'và tắt khi nhiệt độ đạt ngưỡng tắt.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED CARD
  // ============================================================

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PICK TIME
  // ============================================================

  Future<void> _selectTime({required bool isOffTime}) async {
    final initialTime = isOffTime ? _selectedOffTime : _selectedTime;

    final result = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (result == null || !mounted) return;

    setState(() {
      if (isOffTime) {
        _selectedOffTime = result;
      } else {
        _selectedTime = result;
      }
    });
  }

  String _selectedDaysText() {
    final selected = <String>[];

    for (var i = 0; i < 7; i++) {
      if (_selectedDays[i]) {
        selected.add(_dayNames[i]);
      }
    }

    if (selected.isEmpty) return 'Chưa chọn ngày';
    if (selected.length == 7) return 'Mỗi ngày';

    return selected.join(', ');
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveAutomation() async {
    if (_enabled && !_selectedDays.any((day) => day)) {
      _showMessage('Vui lòng chọn ít nhất một ngày.');
      return;
    }

    final provider = context.read<DeviceProvider>();
    final device = provider.getDeviceById(widget.deviceId);

    if (device == null) {
      _showMessage('Không tìm thấy thiết bị.');
      return;
    }

    if (device.type == DeviceType.relay &&
        _enabled &&
        !_relayChannels.any((channel) => channel.enabled)) {
      _showMessage('Vui lòng chọn ít nhất một kênh Relay.');
      return;
    }

    setState(() => _saving = true);
    try {
      final selectedDays = _selectedDays
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key + 1)
          .toList();

      final automation = await provider.saveAutomation(
        deviceId: widget.deviceId,
        enabled: _enabled,
        timeOn: _formatTime(_selectedTime),
        timeOff: _formatTime(_selectedOffTime),
        daysOnWeek: selectedDays,

        autoMode: _autoMode,
        defaultLevel: device.type == DeviceType.fan ? _defaultFanLevel : null,
        temperatureOn: _temperatureOn,
        temperatureOff: _temperatureOff,
        fanLevel: device.type == DeviceType.fan ? _defaultFanLevel : null,

        autoEnabled: device.type == DeviceType.fan ? _autoEnabled : null,

        relayChannels: device.type == DeviceType.relay
            ? _relayChannels
            : const [],

        profileVersion: (_profileVersion ?? 0) + 1,
      );

      if (!mounted) return;

      _profileVersion = automation.profileVersion;

      _showMessage('Đã lưu cấu hình tự động hóa.');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showMessage('Lưu cấu hình thất bại: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
