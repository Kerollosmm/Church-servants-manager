import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/MyColors.dart';
import 'package:flutterbhz/models/Student_Model.dart';

class AttendancePage extends StatefulWidget {
   const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String selectedFilter = 'الكل';
  String searchQuery = ''; // Added search state

  List<Student> students = [
    Student(id: '1', name: 'مينا مجدي', studentId: '2023001'),
    Student(id: '2', name: 'مارينا يوسف', studentId: '2023015'),
    Student(id: '3', name: 'يشوعى عادل', studentId: '2023042'),
  ];

  void markAttendance(Student student, bool value) {
    setState(() {
      student.isPresent = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: MyColors.paige,
          appBar: AppBar(
            title: const Text('أخذ الحضور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: MyColors.lightBrown,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
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

  Widget _buildClassAndDate() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الصف الثالث - أ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('السبت، 21 أكتوبر', style: TextStyle(color: MyColors.lightBrown)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => searchQuery = value), // Handle search
      decoration: InputDecoration(
        hintText: 'ابحث عن طالب...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFilters() {
    List<String> filters = ['الكل', 'حاضر', 'غائب'];
    return Row(
      children: filters.map((filter) {
        bool isSelected = selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? MyColors.ocur : Colors.grey.shade200,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            onPressed: () => setState(() => selectedFilter = filter),
            child: Text(filter),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStudentsList() {
    // Combined Filter and Search logic
    List<Student> filteredStudents = students.where((s) {
      final matchesSearch = s.name.contains(searchQuery);
      final matchesFilter = (selectedFilter == 'الكل') ||
          (selectedFilter == 'حاضر' && s.isPresent) ||
          (selectedFilter == 'غائب' && !s.isPresent);
      return matchesSearch && matchesFilter;
    }).toList();

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) => _buildStudentItem(filteredStudents[index]),
    );
  }

  Widget _buildStudentItem(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(child: Text(student.name[0])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('ID: ${student.studentId}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: student.isPresent ? Colors.grey : Colors.red),
            onPressed: () => markAttendance(student, false),
          ),
          IconButton(
            icon: Icon(Icons.check, color: student.isPresent ? Colors.green : Colors.grey),
            onPressed: () => markAttendance(student, true),
          ),
        ],
      ),
    );
  }
}
