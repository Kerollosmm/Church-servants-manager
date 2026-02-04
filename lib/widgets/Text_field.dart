import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/MyColors.dart';

class CustomTextForm extends StatelessWidget {
  const CustomTextForm({
    super.key,
    required this.hintText,
    required this.icon,
    required this.errorText,
  });

   final String hintText;
   final String errorText;

   final IconData icon;
  @override
  Widget build(BuildContext context) {
    return   Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            validator: (value){
              if(value == null || value.isEmpty){
                return errorText;
              }
              return null;
            },
            decoration: InputDecoration(
                label:Row(
                  children: [
                    Icon(icon ,color: Mycolors.lightBrown,),
                     Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        hintText,
                        style: const TextStyle(
                          color:   Mycolors.lightBrown
                        ),
                      ),
                    ),
                  ],
                ),

                enabledBorder:const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color:  Mycolors.lightBrown )) ,
                focusedBorder:const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Mycolors.lightBrown ))





            ),
          ),
        );


  }
}
