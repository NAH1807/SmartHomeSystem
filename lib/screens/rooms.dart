import 'package:flutter/material.dart';

import '../models/room.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

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

    Room(
      id: 'garage',
      name: 'Garage',
      deviceCount: 3,
      icon: Icons.garage_outlined,
    ),

    Room(
      id: 'balcony',
      name: 'Balcony',
      deviceCount: 2,
      icon: Icons.balcony_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Rooms',

              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Manage devices by room',

              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: GridView.builder(
                itemCount: rooms.length,

                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),

                itemBuilder:
                    (context, index) {
                  final room =
                      rooms[index];

                  return Container(
                    padding:
                        const EdgeInsets.all(18),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),

                      border: Border.all(
                        color:
                            Colors.grey.shade200,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Container(
                          width: 52,
                          height: 52,

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFEEF2FF,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),

                          child: Icon(
                            room.icon,

                            color:
                                const Color(
                              0xFF4F46E5,
                            ),

                            size: 27,
                          ),
                        ),

                        const Spacer(),

                        Text(
                          room.name,

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          '${room.deviceCount} devices',

                          style:
                              const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}