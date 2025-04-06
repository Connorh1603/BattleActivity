import 'imports.dart';
import 'package:percent_indicator/percent_indicator.dart';

class Achievement {
  final String name;
  final int current;
  int goal;
  final IconData icon;
  String badge;

  Achievement({
    required this.name,
    required this.current,
    required this.goal,
    required this.icon,
    required this.badge,
  });

  double get progress => (current / goal).clamp(0.0, 1.0);
}

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  _AchievementScreenState createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Achievement> achievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _saveAchievements(List<Achievement> achievements) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Speichern der Abzeichen in Firestore
    final achievementsMap = achievements.map((achievement) {
      return {
        'name': achievement.name,
        'badge': achievement.badge,
        'current': achievement.current,
        'goal': achievement.goal,
      };
    }).toList();

    await _firestore.collection('users').doc(userId).update({
      'achievements': achievementsMap,
    });
  }

  Future<void> _loadAchievements() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final activitiesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .get();

    int totalLearningMinutes = 0;
    int totalFitnessSessions = 0;
    int totalRuns = 0;
    int learningSessions = 0;
    int fitnessSessions = 0;
    int runningSessions = 0;
    int totalFreetime = 0;
    int freetimeSessions = 0;
    int totalMusicMinutes = 0;
    int musicSessions = 0;


    for (var doc in activitiesSnapshot.docs) {
      final data = doc.data();
      final String category = data['category'] ?? '';
      final int duration = data['duration'] ?? 0;

      if (category == 'Lernen') {
        totalLearningMinutes += duration;
        learningSessions += 1;
      } else if (category == 'Sport') {
        totalFitnessSessions += duration;
        fitnessSessions += 1;
      } else if (category == 'Laufen') {
        totalRuns += duration;
        runningSessions += 1;
      } else if (category == 'Freizeit') {
        totalFreetime += duration;
        freetimeSessions += 1;
      } else if (category == 'Musik') {
        totalMusicMinutes += duration;
        musicSessions += 1;
      }
    }

    setState(() {
      achievements = [
        _createAchievement('Gelernte Minuten', totalLearningMinutes, 600, Icons.school),
        _createAchievement('Lern-Sessions', learningSessions, 20, Icons.menu_book),
        _createAchievement('Fitness Freak', totalFitnessSessions, 600, Icons.fitness_center),
        _createAchievement('Workouts absolviert', fitnessSessions, 20, Icons.sports_gymnastics),
        _createAchievement('Lauflegende', totalRuns, 600, Icons.directions_run),
        _createAchievement('Läufe abgeschlossen', runningSessions, 20, Icons.run_circle),
        _createAchievement('Freiheit', totalFreetime, 600, Icons.event_available),
        _createAchievement('Am Chillen', freetimeSessions, 20, Icons.timelapse),
        _createAchievement('Neuer Mozart', totalMusicMinutes, 600, Icons.piano),
        _createAchievement('Musik gespielt', musicSessions, 20, Icons.library_music),
      ];
    });

    // Speichern der Abzeichen in der Datenbank
    await _saveAchievements(achievements);
  }

  Achievement _createAchievement(String name, int current, int baseGoal, IconData icon) {
    String badge = 'Loser';
    int goal = baseGoal;

    if (current >= baseGoal * 20) {
      badge = 'Diamant';
      goal = baseGoal * 30;
    } else if (current >= baseGoal * 12) {
      badge = 'Platin';
      goal = baseGoal * 20;
    } else if (current >= baseGoal * 6) {
      badge = 'Gold';
      goal = baseGoal * 12;
    } else if (current >= baseGoal * 2) {
      badge = 'Silber';
      goal = baseGoal * 6;
    } else if (current >= baseGoal) {
      badge = 'Bronze';
      goal = baseGoal * 2;
    }

    return Achievement(name: name, current: current, goal: goal, badge: badge, icon: icon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: PreferredSize(
        preferredSize: Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 127, 179, 68),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[300] ?? Colors.grey,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, size: 30, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('Zurück', style: TextStyle(fontSize: 20, color: Colors.white)),
                  ],
                ),
                SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 400;
                    return Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/group'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 100, 150, 60),
                            foregroundColor: Colors.white,
                            minimumSize: Size(isSmall ? 100 : 120, 40),
                          ),
                          child: Text('Gruppen', style: TextStyle(fontSize: 18)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/activity'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 100, 150, 60),
                            foregroundColor: Colors.white,
                            minimumSize: Size(isSmall ? 100 : 120, 40),
                          ),
                          child: Text('Aktivitäten', style: TextStyle(fontSize: 18)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 100, 150, 60),
                            foregroundColor: Colors.white,
                            minimumSize: Size(isSmall ? 100 : 120, 40),
                          ),
                          child: Text('Profil', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            radius: 24,
                            child: Icon(achievement.icon, size: 30, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(achievement.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("${achievement.current}/${achievement.goal} ${achievement.badge.isNotEmpty ? '- ${achievement.badge} Abzeichen' : ''}", style: TextStyle(color: Colors.grey[700])),
                                CircularPercentIndicator(
                                  radius: 30.0,
                                  lineWidth: 6.0,
                                  percent: achievement.progress,
                                  center: Text("${(achievement.progress * 100).toInt()}%"),
                                  progressColor: Colors.deepPurple,
                                  backgroundColor: Colors.grey[300]!,
                                  circularStrokeCap: CircularStrokeCap.round,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset('assets/${achievement.badge}.png',
                            width: 80,
                            height: 80,
                          ),
                        ],
                      ),
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
