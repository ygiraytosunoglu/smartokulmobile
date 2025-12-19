import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import '../constants.dart';

class CourseScheduleScreen extends StatefulWidget {
  final int sinifId; // parametre

  const CourseScheduleScreen({super.key, required this.sinifId});

  @override
  State<CourseScheduleScreen> createState() => _CourseScheduleScreenState();
}

class _CourseScheduleScreenState extends State<CourseScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());

    print(
        'ders programı: ${globals.serverAdrr}/api/school/get-class-schedule?schoolId=${globals.globalSchoolId}&classId=${widget.sinifId}');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title:
        Text(
            "Ders Programı",
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),


      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildCourseScheduleCard(
                      context,
                      'Ders Programı ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      Icons.table_chart,
                      '${globals.serverAdrr}/api/school/get-class-schedule?schoolId=${globals.globalSchoolId}&classId=${widget.sinifId}',
                      ' ',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseScheduleCard(
      BuildContext context, String title, IconData icon, String imageUrl, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageUrl: imageUrl),
                ),
              );
            },
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              color: Colors.grey[400], size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Resim yüklenemedi',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Image.network(imageUrl),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import '../constants.dart';

class CourseScheduleScreen extends StatefulWidget {
  final int sinifId; // parametre

  const CourseScheduleScreen({super.key, required this.sinifId});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
    print('ders programı'+'${globals.serverAdrr}/api/school/get-class-schedule?schoolId=${globals.globalSchoolId}&classId=${sinifId}');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        title: const Text("Yemek Listesi"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildCourseScheduleCard(
                      context,
                      'Ders Programı ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      Icons.table_chart,
                      '${globals.serverAdrr}/api/school/get-class-schedule?schoolId=${globals.globalSchoolId}&classId=${sinifId}',
                      ' ',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseScheduleCard(
      BuildContext context, String title, IconData icon, String imageUrl, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageUrl: imageUrl),
                ),
              );
            },
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              color: Colors.grey[400], size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Resim yüklenemedi',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Image.network(imageUrl),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
*/