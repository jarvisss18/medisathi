import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Color(0xFF1E6FE8)),
            const SizedBox(width: 8),
            const Text(
              'MediSathi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up, size: 30, color: Color(0xFF1E6FE8)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reading Home screen aloud...')),
              );
            },
            tooltip: 'Read Aloud',
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () => GoRouter.of(context).push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E6FE8), Color(0xFF0F4098)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Namaste, Mrs. Sunanda!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'How can we help you stay safe today?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Action Grid (4 Large Tiles)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionTile(
                  context,
                  title: 'Scan Medicine',
                  icon: Icons.qr_code_scanner,
                  color: const Color(0xFF1E6FE8),
                  onTap: () => context.push('/scan'),
                ),
                _buildActionTile(
                  context,
                  title: 'My Medicines',
                  icon: Icons.medication,
                  color: const Color(0xFF10B981),
                  onTap: () => context.push('/my-medicines'),
                ),
                _buildActionTile(
                  context,
                  title: 'Reminders',
                  icon: Icons.alarm,
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.push('/reminders'),
                ),
                _buildActionTile(
                  context,
                  title: 'Caregiver Alert',
                  icon: Icons.contact_emergency,
                  color: const Color(0xFFEF4444),
                  onTap: () => context.push('/caregiver'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Doses Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Today's Doses",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text('2 Taken / 1 Next'),
                          backgroundColor: Color(0xFFE2E8F0),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: const Icon(Icons.medication, color: Color(0xFF1E6FE8)),
                      ),
                      title: const Text(
                        'Amlodipine 5 mg',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: const Text('Next due at 8:00 PM • 1 tablet after food'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 40),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dose marked as TAKEN')),
                          );
                        },
                        child: const Text('Taken'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Safety Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prototype for medication identification and adherence support — not a substitute for medical advice.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) context.push('/my-medicines');
          if (index == 2) context.push('/reminders');
          if (index == 3) context.push('/settings');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.medication), label: 'Medicines'),
          NavigationDestination(icon: Icon(Icons.alarm), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          border: Border.all(color: color.withAlpha(77), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color,
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
