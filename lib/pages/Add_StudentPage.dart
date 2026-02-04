import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/MyColors.dart';
import 'package:flutterbhz/widgets/Text_field.dart';





class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});


  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {


  @override
  Widget build(BuildContext context) {
    return  SafeArea(
        child:  Scaffold(

          backgroundColor: Mycolors.paige,
          body:  Center(
            child: SingleChildScrollView(
              child: Column(
                children: [


                    /*BackButton(
                      color: Colors.black,
                      onPressed: (){
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                    ),*/


                  //Add Image
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0,20,0,20),
                    child: CircleAvatar(
                      maxRadius: 60,

                    ),
                  ),


                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:  SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Container(
                                  height: 450,
                                  decoration: BoxDecoration(

                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Mycolors.lightBrown),

                                  ),
                                  child: const SingleChildScrollView(
                                    child: Column(
                                      children: [

                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomTextForm(
                                              hintText: 'اسم الطالب رباعي'
                                              , icon: Icons.person,
                                              errorText: 'برجاء إدخال اسم الطالب'
                                          ),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomTextForm(
                                              hintText: 'تاريخ اليلاد'
                                              , icon: Icons.date_range,
                                              errorText: 'برجاء إدخال تاريخ الميلاد'
                                          ),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomTextForm(
                                              hintText: 'السنة الدراسية'
                                              , icon: Icons.school,
                                              errorText: 'برجاء إدخال السنة الدراسية'
                                          ),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomTextForm(
                                              hintText: 'العنوان'
                                              , icon: Icons.home,
                                              errorText: 'برجاء إدخال العنوان'
                                          ),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomTextForm(
                                              hintText: 'رقم تليفون الطالب'
                                              , icon: Icons.phone,
                                              errorText: 'برجاء إدخال رقم التليفون'
                                          ),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomTextForm(
                                              hintText: 'رقم تليفون الأم'
                                              , icon: Icons.phone,
                                              errorText: 'برجاء إدخال رقم تليفون الأم'
                                          ),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomTextForm(
                                              hintText: 'رقم تليفون الأب'
                                              , icon: Icons.phone,
                                              errorText: 'برجاء إدخال رقم تليفون الأب'
                                          ),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomTextForm(
                                              hintText: 'اسم أب الاعتراف'
                                              , icon: Icons.church,
                                              errorText: 'برجاء إدخال اسم أب الاعتراف'
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),


                                Padding(
                                    padding: const EdgeInsets.fromLTRB(0,30,0,30),
                                    child: SizedBox(
                                      width: 200,
                                      height: 45,
                                      child: ElevatedButton(

                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Mycolors.lightBrown,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadiusGeometry.circular(20)
                                            )
                                        ),
                                        onPressed: (){},
                                        child:const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save,color:Colors.white,size: 20,),
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text("حفظ البيانات",style: TextStyle(fontWeight:FontWeight.bold,fontSize: 18,color: Colors.white),),
                                            ),
                                          ],
                                        ),

                                      ),

                                    )
                                ),
                              ],
                            ),
                          ),
                        )

                  ),
                ],
              ),
            ),
          ),

        ),

      );

  }
}


