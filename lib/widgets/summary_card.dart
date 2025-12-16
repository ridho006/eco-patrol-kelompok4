// widgets/summary_card.dart
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final int totalReports;
  final int completedReports;
  final int pendingReports;

  const SummaryCard({
    Key? key,
    required this.totalReports,
    required this.completedReports,
    required this.pendingReports,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade500],
          ),
        ),
        child: Column(
          children: [
            Text(
              'Ringkasan Laporan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.list_alt,
                  label: 'Total',
                  value: totalReports.toString(),
                  color: Colors.white,
                ),
                _buildDivider(),
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Selesai',
                  value: completedReports.toString(),
                  color: Colors.lightGreenAccent,
                ),
                _buildDivider(),
                _buildStatItem(
                  icon: Icons.pending,
                  label: 'Pending',
                  value: pendingReports.toString(),
                  color: Colors.orangeAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      color: Colors.white30,
    );
  }
}