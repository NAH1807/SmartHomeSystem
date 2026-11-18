import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../providers/device.dart';

class DeviceEditorScreen extends StatefulWidget {
  final int? deviceId;

  const DeviceEditorScreen({
    super.key,
    this.deviceId,
  });

  @override
  State<DeviceEditorScreen> createState() => _DeviceEditorScreenState();
}

class _DeviceEditorScreenState extends State<DeviceEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  DeviceType _selectedType = DeviceType.relay;
  bool _saving = false;

  bool get isEditing => widget.deviceId != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDevice();
      });
    }
  }

  Future<void> _loadDevice() async {
    final provider = context.read<DeviceProvider>();

    final device = await provider.loadDevice(widget.deviceId!);

    if (!mounted || device == null) return;

    setState(() {
      _nameController.text = device.name;
      _selectedType = device.type;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final provider = context.read<DeviceProvider>();

    try {
      if (isEditing) {
        await provider.updateDevice(
          deviceId: widget.deviceId!,
          name: _nameController.text.trim(),
          type: _selectedType,
        );
      } else {
        await provider.createDevice(
          name: _nameController.text.trim(),
          type: _selectedType,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể ${isEditing ? 'cập nhật' : 'thêm'} thiết bị: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _typeName(DeviceType type) {
    switch (type) {
      case DeviceType.relay:
        return 'Relay';
      case DeviceType.fan:
        return 'Fan';
      case DeviceType.camera:
        return 'Camera';
    }
  }

  IconData _typeIcon(DeviceType type) {
    switch (type) {
      case DeviceType.relay:
        return Icons.power_settings_new;
      case DeviceType.fan:
        return Icons.air;
      case DeviceType.camera:
        return Icons.camera_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Device' : 'Add Device',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device name',
                hintText: 'Enter device name',
                prefixIcon: Icon(Icons.devices),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter device name';
                }

                if (value.trim().length < 2) {
                  return 'Device name is too short';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<DeviceType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Device type',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: DeviceType.values.map((type) {
                return DropdownMenuItem<DeviceType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_typeIcon(type)),
                      const SizedBox(width: 12),
                      Text(_typeName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedType = value;
                });
              },
            ),


            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        isEditing
                            ? Icons.save
                            : Icons.add,
                      ),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : isEditing
                          ? 'Save Changes'
                          : 'Add Device',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}