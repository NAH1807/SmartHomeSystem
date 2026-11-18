import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/device.dart';
import 'device_detail.dart';
import 'device_editor.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() =>
      _DevicesScreenState();
}

class _DevicesScreenState
    extends State<DevicesScreen> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) return;

      context
          .read<DeviceProvider>()
          .loadDevices();
    });
  }

  Future<void> _refresh() async {
    await context
        .read<DeviceProvider>()
        .loadDevices();
  }

  Future<void> _addDevice() async {
    final result = await Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const DeviceEditorScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _editDevice(int deviceId) async {
    final result = await Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DeviceEditorScreen(
          deviceId: deviceId,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _deleteDevice(
    int deviceId,
    String name,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete device',
          ),
          content: Text(
            'Delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) {
      return;
    }

    try {
      await context
          .read<DeviceProvider>()
          .deleteDevice(deviceId);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Device deleted',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Devices',
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: _addDevice,
        child: const Icon(Icons.add),
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Consumer<DeviceProvider>(
          builder: (
            context,
            provider,
            child,
          ) {
            if (provider.loading &&
                provider.devices.isEmpty) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (provider.error != null &&
                provider.devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      provider.error!,
                      textAlign:
                          TextAlign.center,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text(
                        'Retry',
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.devices.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Text(
                        'No devices yet',
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  provider.devices.length,
              itemBuilder:
                  (context, index) {
                final device =
                    provider.devices[index];

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  clipBehavior:
                      Clip.antiAlias,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        device.icon,
                      ),
                    ),

                    title: Text(
                      device.name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      '${device.typeName} • '
                      '${device.isOnline ? "Online" : "Offline"}',
                    ),

                    trailing:
                        PopupMenuButton<String>(
                      onSelected:
                          (value) {
                        if (value ==
                            'edit') {
                          _editDevice(
                            device.id,
                          );
                        }

                        if (value ==
                            'delete') {
                          _deleteDevice(
                            device.id,
                            device.name,
                          );
                        }
                      },
                      itemBuilder:
                          (context) =>
                              const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            'Edit',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                          ),
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              DeviceDetailScreen(
                            deviceId:
                                device.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}