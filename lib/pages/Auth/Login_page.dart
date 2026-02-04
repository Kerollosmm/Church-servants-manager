import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/GradientBorder_container.dart';
import 'package:flutterbhz/widgets/MyColors.dart';
import 'package:flutterbhz/widgets/Text_field.dart';

final _formKey = GlobalKey<FormState>();
bool _isPasswordHidden = true;

class Login extends StatefulWidget {
  const Login({super.key});




  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color:  Mycolors.paige,


        alignment: AlignmentGeometry.center,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/unnamed.png",width: 200,height: 200,),
              const Text('مدرسة الكاروز',style: TextStyle(fontSize:28 ,fontWeight:FontWeight.bold ),),
              const Padding(
                padding: EdgeInsets.fromLTRB(0,0,0,20),
                child: Text(' قم بتسجيل دخولك للمتابعة ',style: TextStyle(fontSize:12 ,fontWeight:FontWeight.bold ,color: Colors.black54),),
              ),



               GradientBorderContainer(
                   height: 450,
                   width: 330,
                   widget: Padding(
                        padding: const EdgeInsets.fromLTRB(8,40,8,8),
                        child: Column(
                          children: [

                            Form(
                                key: _formKey,
                                child: Column(
                                  children: [

                                    // USERNAME FIELD
                                    const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CustomTextForm(
                                         errorText: 'برجاء إدخال اسم المستخدم',
                                          hintText: 'اسم المستخدم' ,
                                          icon: Icons.person,
                                      ),
                                    ),



                                    // PASSWORD FIELD
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20.0,20,20,0),
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: TextFormField(
                                          validator: (value){
                                            if(value == null || value.isEmpty){
                                              return 'برجاء ادخال كلمة السر';
                                            }
                                            return null ;
                                          },
                                          obscureText: _isPasswordHidden,
                                          decoration: InputDecoration(

                                              label:const Row(
                                                children: [
                                                  Icon(Icons.lock,color: Mycolors.lightBrown,),
                                                  Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(
                                                      "كلمة السر",
                                                      style: TextStyle(
                                                        color:  Mycolors.lightBrown,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _isPasswordHidden
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                  color: Mycolors.lightBrown,
                                                ),
                                                onPressed: (){
                                                  setState(() {
                                                    _isPasswordHidden = !_isPasswordHidden;
                                                  });
                                                },
                                              ),

                                              enabledBorder:const OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                                  borderSide: BorderSide(color: Mycolors.lightBrown, )) ,

                                              focusedBorder:const OutlineInputBorder
                                                (borderRadius: BorderRadius.all(Radius.circular(10)),
                                                  borderSide: BorderSide(color: Mycolors.lightBrown,))





                                          ),
                                        ),
                                      ),
                                    ),


                                  ],)
                            ),

                            //FORGOT PASSWORD BUTTON
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0,0,160,0),
                              child: MaterialButton(

                                  onPressed: (){},
                                  child: const Text('نسيت كلمة المرور؟',style: TextStyle(color:Colors.brown, ),
                                  )
                              ),
                            ),


                            /// LOGIN BUTTON
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0,30,0,0),
                              child: SizedBox(
                                width: 200,
                                height: 45,
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                      gradient: LinearGradient(colors: [Colors.brown, Color(0xFFA58255),]),
                                      borderRadius: BorderRadius.all(Radius.circular(20))
                                  ),

                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadiusGeometry.circular(20)
                                        )


                                    ),
                                    onPressed: (){
                                      if(_formKey.currentState!.validate()){

                                      }
                                      Navigator.pushReplacementNamed(context, '/home');
                                    },
                                    child:const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.input,color:Colors.white,size: 20,),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text("تسجيل الدخول",style: TextStyle(fontWeight:FontWeight.bold,fontSize: 18,color: Colors.white),),
                                        ),
                                      ],
                                    ),

                                  ),
                                ),
                              ),
                            ),


                          ],
                        ),
                      ),),
                    ])
                ),
                )

    );



  }
}
