import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  final String username;

  const GroupDetailScreen({super.key, required this.groupId, required this.username});

  @override
  Widget build(BuildContext context) {
    print("DEBUG: Benutzername im Detail-Screen: $username");

    return Scaffold(
      appBar: AppBar(title: Text('Gruppendetails')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Groups').doc(groupId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Gruppe nicht gefunden"));
          }

          final groupData = snapshot.data!;
          final groupName = groupData['name'] ?? 'Unbekannte Gruppe';
          final groupType = groupData['typ'] ?? 'Kein Typ';
          final groupSubType = groupData['subtyp'] ?? '';
          final adminId = groupData['admin'] ?? '';
          final members = List<String>.from(groupData['members'] ?? []);
          final isAdmin = username == adminId;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Typ: $groupType - ${groupSubType.isEmpty ? "Keiner" : groupSubType}",
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 16),
                Text("Mitglieder:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(members[index])
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return ListTile(
                              leading: Icon(Icons.person),
                              title: Text("Lade..."),
                            );
                          }

                          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                            return ListTile(
                              leading: Icon(Icons.person),
                              title: Text("Unbekannt"),
                            );
                          }

                          final username = userSnapshot.data!.get('username') ?? 'Unbekannt';

                          return ListTile(
                            leading: Icon(Icons.person),
                            title: Text(username),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _getLatestActivityInfo(members),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data = snapshot.data;

                    if (data == null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            "Noch keine Aktivität in dieser Gruppe.",
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }

                    final username = data['username'];
                    final duration = data['duration'];
                    final timestamp = data['timestamp'] as DateTime;

                    final diff = DateTime.now().difference(timestamp);
                    final String timeAgo = diff.inDays > 0
                        ? "vor ${diff.inDays} Tag(en)"
                        : diff.inHours > 0
                            ? "vor ${diff.inHours} Stunde(n)"
                            : "gerade eben";

                    return Card(
                      color: Colors.orange.shade50,
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "$username hat $timeAgo eine Aktivität unternommen und $duration Minuten seinem Score hinzugefügt.",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
                Text("Leaderboard:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getLeaderboardData(members),
                    builder: (context, leaderboardSnapshot) {
                      if (leaderboardSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!leaderboardSnapshot.hasData || leaderboardSnapshot.data!.isEmpty) {
                        return Center(child: Text("Keine Leaderboard-Daten verfügbar."));
                      }

                      final leaderboardData = leaderboardSnapshot.data!;
                      final maxY = leaderboardData
                          .map((e) => (e['valueMonthly'] as num?)?.toDouble() ?? 0.0)
                          .fold<double>(0.0, (a, b) => a > b ? a : b);

                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 22.0), // ⬅️ Abstand links & rechts
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceBetween,
                            maxY: maxY,
                            barGroups: leaderboardData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final user = entry.value;

                              return BarChartGroupData(
                                x: index,
                                barsSpace: 12,
                                barRods: [
                                  BarChartRodData(
                                    toY: (user['valueMonthly'] as num).toDouble(),
                                    color: Colors.blue,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) =>
                                      Text(value.toInt().toString(), style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= leaderboardData.length) return Container();
                                    final userName = leaderboardData[value.toInt()]['user'];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(userName, style: TextStyle(fontSize: 14)),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () async {
                      await _leaveGroup();
                      Navigator.pop(context);
                    },
                    child: Text("Gruppe Verlassen", style: TextStyle(color: Colors.red, fontSize: 18)),
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => _showAddMemberDialog(context, isAdmin),
                    child: Text("Mitglied hinzufügen", style: TextStyle(color: Colors.green, fontSize: 18)),
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () async {
                      final groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
                      final groupSnapshot = await groupRef.get();
                      final adminId = groupSnapshot['admin'] ?? '';

                      if (adminId == username) {
                        _showChangeGroupNameDialog(context);
                      } else {
                        _showNotAdminMessage(context);
                      }
                    },
                    child: Text("Gruppennamen ändern", style: TextStyle(color: Colors.blue, fontSize: 18)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getLeaderboardData(List<String> members) async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);

    List<Map<String, dynamic>> leaderboard = [];

    for (String user in members) {
      int totalDuration = 0;
      final userActivitiesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user)
          .collection('activities');

      final snapshot = await userActivitiesRef
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth.millisecondsSinceEpoch)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final duration = (data['duration'] as num?)?.toInt() ?? 0;
        final groupIds = List<String>.from(data['groupIds'] ?? []);

        if (groupIds.contains(groupId)) {
          totalDuration += duration;
        }
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user).get();
      final username = userDoc.data()?['username'] ?? 'Unbekannt';

      leaderboard.add({
        'user': username,
        'valueMonthly': totalDuration,
      });
    }

    return leaderboard;
  }


  Future<void> _leaveGroup() async {
    final groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
    await groupRef.update({
      'members': FieldValue.arrayRemove([username])
    });
    print("$username hat die Gruppe verlassen.");
  }

  void _showNotAdminMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Keine Berechtigung"),
        content: Text("Nur der Gruppenadmin kann den Gruppennamen ändern."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }
  Future<Map<String, dynamic>?> _getLatestActivityInfo(List<String> members) async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);

    Map<String, dynamic>? latestActivity;
    DateTime? latestTimestamp;

    for (String userId in members) {
      final activitiesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities');

      final snapshot = await activitiesRef
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth.millisecondsSinceEpoch)
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final duration = (data['duration'] as num?)?.toInt() ?? 0;
        final groupIds = List<String>.from(data['groupIds'] ?? []);
        final rawTimestamp = data['timestamp'];
        final timestamp = rawTimestamp is int
            ? DateTime.fromMillisecondsSinceEpoch(rawTimestamp)
            : null;

        if (groupIds.contains(groupId) && timestamp != null) {
          if (latestTimestamp == null || timestamp.isAfter(latestTimestamp)) {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
            final username = userDoc.data()?['username'] ?? 'Unbekannt';

            latestActivity = {
              'username': username,
              'timestamp': timestamp,
              'duration': duration,
            };

            latestTimestamp = timestamp;
          }
        }
      }
    }

    return latestActivity;
  }

  void _showAddMemberDialog(BuildContext context, bool isAdmin) {
    showDialog(
      context: context,
      builder: (context) {
        if (isAdmin) {
          return AlertDialog(
            title: Text("Mitglied hinzufügen"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Gib diese Gruppen-ID an das neue Mitglied weiter:"),
                SizedBox(height: 8),
                SelectableText(groupId, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: groupId));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gruppen-ID kopiert!")));
                  },
                  child: Text("ID kopieren"),
                ),
              ],
            ),
          );
        } else {
          return AlertDialog(
            title: Text("Mitglied hinzufügen"),
            content: Text("Bitte frage den Gruppenadmin nach der Gruppen-ID."),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Verstanden"))],
          );
        }
      },
    );
  }

  void _showChangeGroupNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Gruppennamen ändern"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: "Neuer Gruppenname"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Abbrechen")),
            ElevatedButton(
              onPressed: () async {
                String newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await _changeGroupName(newName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gruppenname geändert!")));
                }
              },
              child: Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeGroupName(String newName) async {
    final groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
    await groupRef.update({'name': newName});
    print("Gruppenname geändert auf: $newName");
  }
}
