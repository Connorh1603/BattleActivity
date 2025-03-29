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
          final adminId = groupData['admin'] ?? '';
          final members = List<String>.from(groupData['members'] ?? []);
          final isAdmin = username == adminId;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Typ: $groupType",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Text("Mitglieder:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.person),
                        title: Text(members[index]),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
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

                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceBetween,
                          maxY: leaderboardData.isNotEmpty
                              ? leaderboardData.map((e) => e['valueMonthly'] as double).reduce((a, b) => a > b ? a : b)
                              : 100,
                          barGroups: leaderboardData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final user = entry.value;

                            return BarChartGroupData(
                              x: index,
                              barsSpace: 12,  // Vergrößert den Abstand zwischen den Balken
                              barRods: [
                                BarChartRodData(
                                  toY: user['valueMonthly'].toDouble(),
                                  color: Colors.blue,
                                  width: 20,  // Balkenbreite reduziert für besseren Abstand
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
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(fontSize: 12),
                                  );
                                },
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
                                    child: Text(
                                      userName,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: false),
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
                    child: Text(
                      "Gruppe Verlassen",
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () async {
                      _showAddMemberDialog(context, isAdmin);
                    },
                    child: Text(
                      "Mitglied hinzufügen",
                      style: TextStyle(color: Colors.green, fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () async {
                      // Prüfen, ob der Nutzer Admin ist
                      final groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
                      final groupSnapshot = await groupRef.get();
                      final adminId = groupSnapshot['admin'] ?? '';

                      if (adminId == username) {
                        _showChangeGroupNameDialog(context);
                      } else {
                        _showNotAdminMessage(context);
                      }
                    },
                    child: Text(
                      "Gruppennamen ändern",
                      style: TextStyle(color: Colors.blue, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dialog zum Ändern des Gruppennamens
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () async {
                String newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await _changeGroupName(newName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gruppenname geändert!")),
                  );
                }
              },
              child: Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  /// Gruppenname in Firestore ändern
  Future<void> _changeGroupName(String newName) async {
    final groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
    await groupRef.update({
      'name': newName,
    });
    print("Gruppenname geändert auf: $newName");
  }

  Future<void> _leaveGroup() async {
    final groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
    await groupRef.update({
      'members': FieldValue.arrayRemove([username])
    });
    print("$username hat die Gruppe verlassen.");
  }

  Future<List<Map<String, dynamic>>> _getLeaderboardData(List<String> members) async {
    final activitiesRef = FirebaseFirestore.instance.collection('Activities');
    List<Future<Map<String, dynamic>>> futures = members.map((userId) async {
      try {
        QuerySnapshot activitySnapshot = await activitiesRef.where('user', isEqualTo: userId).get();
        int valueMonthly = 0;
        if (activitySnapshot.docs.isNotEmpty) {
          valueMonthly = activitySnapshot.docs.first['valueMonthly'] ?? 0;
        }
        return {'user': userId, 'valueMonthly': valueMonthly};
      } catch (e) {
        print("Fehler beim Laden von $userId: $e");
        return {'user': userId, 'valueMonthly': 0};
      }
    }).toList();
    return await Future.wait(futures);
  }
  /// Meldung anzeigen, wenn kein Admin
void _showNotAdminMessage(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Keine Berechtigung"),
        content: Text("Nur der Gruppenadmin kann den Gruppennamen ändern."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      );
    },
  );
}
  /// Dialog zum Hinzufügen von Mitgliedern
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gruppen-ID kopiert!")),
                    );
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Verstanden"),
              ),
            ],
          );
        }
      },
    );
  }

}
