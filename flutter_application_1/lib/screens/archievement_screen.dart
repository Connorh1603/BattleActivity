import 'package:flutter/material.dart';

class Trophy {
  final String name;
  final int current;
  final int goal;
  final double progress;
  final IconData icon;
  final int stars;

  Trophy({required this.name, required this.current, required this.progress, required this.icon, required this.goal, required this.stars});
}

class ArchievementScreen extends StatelessWidget {
  const ArchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Trophy> trophies = [
      Trophy(name: "Gelernte Stunden", current: 50, goal: 100, progress: 0.5, icon: Icons.school, stars: 3),
      Trophy(name: "Fitness Freak", current: 7, goal: 10, progress: 0.7, icon: Icons.fitness_center, stars: 2),
      Trophy(name: "Lauflegende", current: 40, goal: 50, progress: 0.8, icon: Icons.directions_run, stars: 3),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Erfolge')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Deine Erfolge',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: trophies.length,
                itemBuilder: (context, index) {
                  final trophy = trophies[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon der Aktivität
                          CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            radius: 24,
                            child: Icon(trophy.icon, size: 30, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 12),

                          // Textbereich
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trophy.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("${trophy.current}/${trophy.goal}", style: TextStyle(color: Colors.grey[700])),
                                Row(
                                  children: List.generate(
                                    trophy.stars,
                                    (starIndex) => const Icon(Icons.emoji_events, size: 18, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Fortschrittsanzeige
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: trophy.progress,
                                  strokeWidth: 5,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigationsbuttons
            const SizedBox(height: 10),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  child: const Text('Go to Profile'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/activity'),
                  child: const Text('Aktivitäten'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/group'),
                  child: const Text('Gruppen'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
