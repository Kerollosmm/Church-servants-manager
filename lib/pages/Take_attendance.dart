import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/MyColors.dart';


class Student {
  final String id;
  final String name;
  final String studentId;
  bool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.studentId,
    this.isPresent = false,
  });
}


class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String selectedFilter = 'الكل';

  List<Student> students = [
    Student(id: '1', name: 'مينا مجدي', studentId: '2023001'),
    Student(id: '2', name: 'مارينا يوسف', studentId: '2023015'),
    Student(id: '3', name: 'يشوعى عادل', studentId: '2023042'),
  ];

  // 🔥 Firebase (بعد كده)
  // Stream<QuerySnapshot> getStudents() { }

  void markAttendance(Student student, bool value) {
    setState(() {
      student.isPresent = value;
    });

    // 🔥 Firestore update
    // FirebaseFirestore.instance
    //   .collection('attendance')
    //   .doc(student.id)
    //   .set({...});
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        backgroundColor: Mycolors.paige,
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                _buildClassAndDate(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilters(),
                const SizedBox(height: 12),
                Expanded(child: _buildStudentsList()),
              ],
            ),
          ),
        ),
      );

  }


  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('أخذ الحضور'),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    );
  }


  Widget _buildClassAndDate() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          )
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الصف الثالث - أ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('السبت، 21 أكتوبر',
              style: TextStyle(color:Mycolors.lightBrown,)),
        ],
      ),
    );
  }


  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'ابحث عن طالب...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }


  Widget _buildFilters() {
    List<String> filters = ['الكل', 'حاضر', 'غائب', 'متأخر'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: filters.map((filter) {
        bool isSelected = selectedFilter == filter;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isSelected ? Mycolors.ocur : Colors.grey.shade200,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          onPressed: () {
            setState(() => selectedFilter = filter);
          },
          child: Text(filter),
        );
      }).toList(),
    );
  }


  Widget _buildStudentsList() {
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentItem(student);
      },
    );
  }


  Widget _buildStudentItem(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(student.name[0])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('ID: ${student.studentId}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close,
                color: student.isPresent ? Colors.grey : Colors.red),
            onPressed: () => markAttendance(student, false),
          ),
          IconButton(
            icon: Icon(Icons.check,
                color: student.isPresent ? Colors.green : Colors.grey),
            onPressed: () => markAttendance(student, true),
          ),
        ],
      ),
    );
  }


}
