import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceCard extends StatefulWidget {
  final Device device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  State<DeviceCard> createState() =>
      _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  late bool isOn;

  @override
  void initState() {
    super.initState();

    isOn = widget.device.isOn;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          AnimatedContainer(
            duration:
                const Duration(milliseconds: 200),

            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: isOn
                  ? const Color(0xFFE8E9FF)
                  : const Color(0xFFF3F4F6),

              borderRadius:
                  BorderRadius.circular(15),
            ),

            child: Icon(
              widget.device.icon,

              color: isOn
                  ? const Color(0xFF4F46E5)
                  : Colors.grey,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  widget.device.name,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,

                      decoration:
                          BoxDecoration(
                        color:
                            widget.device.isOnline
                                ? Colors.green
                                : Colors.grey,

                        shape:
                            BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      widget.device.room,

                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Switch(
            value: isOn,

            onChanged: widget.device.isOnline
                ? (value) {
                    setState(() {
                      isOn = value;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}