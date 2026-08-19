import 'package:flutter/material.dart';

import '../models/device.dart';
import '../models/room.dart';

import '../widgets/home_header.dart';
import '../widgets/home_summary_card.dart';
import '../widgets/room_card.dart';
import '../widgets/device_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const rooms = [
    Room(
      id: 'living_room',
      name: 'Living Room',
      deviceCount: 6,
      icon: Icons.weekend_outlined,
    ),

    Room(
      id: 'bedroom',
      name: 'Bedroom',
      deviceCount: 4,
      icon: Icons.bed_outlined,
    ),

    Room(
      id: 'kitchen',
      name: 'Kitchen',
      deviceCount: 5,
      icon: Icons.kitchen_outlined,
    ),

    Room(
      id: 'bathroom',
      name: 'Bathroom',
      deviceCount: 2,
      icon: Icons.bathtub_outlined,
    ),
  ];

  static final devices = [
    Device(
      id: 'light_001',
      name: 'Living Room Light',
      room: 'Living Room',
      type: DeviceType.light,
      icon: Icons.lightbulb_outline,
      isOn: true,
    ),

    Device(
      id: 'ac_001',
      name: 'Air Conditioner',
      room: 'Bedroom',
      type: DeviceType.airConditioner,
      icon: Icons.ac_unit,
      isOn: false,
    ),

    Device(
      id: 'plug_001',
      name: 'Smart Plug',
      room: 'Kitchen',
      type: DeviceType.smartPlug,
      icon: Icons.power,
      isOn: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding:
                EdgeInsets.fromLTRB(
              20,
              20,
              20,
              10,
            ),

            sliver: SliverToBoxAdapter(
              child: HomeHeader(),
            ),
          ),

          const SliverPadding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 20,
            ),

            sliver: SliverToBoxAdapter(
              child: HomeSummaryCard(),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              10,
            ),

            sliver: SliverToBoxAdapter(
              child: _sectionTitle(
                'Rooms',
                'See all',
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 145,

                child: ListView.builder(
                  scrollDirection:
                      Axis.horizontal,

                  itemCount:
                      rooms.length,

                  itemBuilder:
                      (context, index) {
                    return RoomCard(
                      room: rooms[index],
                    );
                  },
                ),
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              10,
            ),

            sliver: SliverToBoxAdapter(
              child: _sectionTitle(
                'Favorite Devices',
                'See all',
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            sliver: SliverList(
              delegate:
                  SliverChildBuilderDelegate(
                (context, index) {
                  return DeviceCard(
                    device: devices[index],
                  );
                },

                childCount:
                    devices.length,
              ),
            ),
          ),

          const SliverPadding(
            padding:
                EdgeInsets.only(
              bottom: 20,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(
    String title,
    String action,
  ) {
    return Row(
      children: [
        Text(
          title,

          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),

        Text(
          action,

          style: const TextStyle(
            color: Color(0xFF4F46E5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}