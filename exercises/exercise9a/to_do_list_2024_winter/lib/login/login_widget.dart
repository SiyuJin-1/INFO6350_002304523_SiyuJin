import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
      import 'login_model.dart';
      export 'login_model.dart';
    
class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key }) ;

  

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> with TickerProviderStateMixin {
  late LoginModel _model;

final scaffoldKey = GlobalKey<ScaffoldState>();

final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

          animationsMap.addAll({          'containerOnPageLoadAnimation': AnimationInfo(
            
            
            trigger: AnimationTrigger.onPageLoad,
            
                      effectsBuilder: () => [
                      VisibilityEffect(duration: 1.ms),
                        FadeEffect(
                curve: Curves.easeInOut,
                  delay: 0.0.ms,
                  duration: 300.0.ms,
                  begin: 0.0,
                  end: 1.0,
                ),
                                ScaleEffect(
                  curve: Curves.bounceOut,
                  delay: 0.0.ms,
                  duration: 300.0.ms,
                  begin: Offset(0.6, 0.6),
                  end: Offset(1.0, 1.0),
                ),
                
          ],
          
        ),          'textOnPageLoadAnimation1': AnimationInfo(
            
            
            trigger: AnimationTrigger.onPageLoad,
            
                      effectsBuilder: () => [
                      VisibilityEffect(duration: 100.ms),
                        FadeEffect(
                curve: Curves.easeInOut,
                  delay: 100.0.ms,
                  duration: 400.0.ms,
                  begin: 0.0,
                  end: 1.0,
                ),
                                MoveEffect(
                  curve: Curves.easeInOut,
                  delay: 100.0.ms,
                  duration: 400.0.ms,
                  begin: Offset(0.0, 30.0),
                  end: Offset(0.0, 0.0),
                ),
                
          ],
          
        ),          'textOnPageLoadAnimation2': AnimationInfo(
            
            
            trigger: AnimationTrigger.onPageLoad,
            
                      effectsBuilder: () => [
                      VisibilityEffect(duration: 150.ms),
                        FadeEffect(
                curve: Curves.easeInOut,
                  delay: 150.0.ms,
                  duration: 400.0.ms,
                  begin: 0.0,
                  end: 1.0,
                ),
                                MoveEffect(
                  curve: Curves.easeInOut,
                  delay: 150.0.ms,
                  duration: 400.0.ms,
                  begin: Offset(0.0, 30.0),
                  end: Offset(0.0, 0.0),
                ),
                
          ],
          
        ),          'columnOnPageLoadAnimation': AnimationInfo(
            
            
            trigger: AnimationTrigger.onPageLoad,
            
                      effectsBuilder: () => [
                          FadeEffect(
                curve: Curves.easeInOut,
                  delay: 200.0.ms,
                  duration: 400.0.ms,
                  begin: 0.0,
                  end: 1.0,
                ),
                                MoveEffect(
                  curve: Curves.easeInOut,
                  delay: 200.0.ms,
                  duration: 400.0.ms,
                  begin: Offset(0.0, 60.0),
                  end: Offset(0.0, 0.0),
                ),
                                TiltEffect(
                  curve: Curves.easeInOut,
                  delay: 200.0.ms,
                  duration: 400.0.ms,
                  begin: Offset(-0.349, 0),
                  end: Offset(0, 0),
                ),
                
          ],
          
        ),});
      
      
      
    
  }


  @override
  void dispose() {
    _model.dispose();

    
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    
    return GestureDetector(
  onTap: () =>
    _model.unfocusNode.canRequestFocus
      ? FocusScope.of(context).requestFocus(_model.unfocusNode)
      : FocusScope.of(context).unfocus(),
  child: Scaffold(
      key: scaffoldKey,
      
      backgroundColor: Colors.white  ,
      
      
      
      body: Column(
      
      mainAxisSize: MainAxisSize.max,
      
      
      children: [Container(
      
      width: double.infinity  ,height: 300.0  ,
      
      decoration: BoxDecoration(
        
        
        
        gradient:     LinearGradient(
      colors: [Color(0xFF4B39EF),Color(0xFFFF5963),Color(0xFFEE8B60)],
      stops: [0.0,0.5,1.0],
      begin: AlignmentDirectional(
        -1.0,
        -1.0
      ),
      end: AlignmentDirectional(
        1.0,
        1.0
      ),
    )
  ,
        
        
        
      ),
    
      
      child: Container(
      
      width: 100.0  ,height: 100.0  ,
      
      decoration: BoxDecoration(
        
        
        
        gradient:     LinearGradient(
      colors: [Color(0x00FFFFFF),Colors.white],
      stops: [0.0,1.0],
      begin: AlignmentDirectional(
        0.0,
        -1.0
      ),
      end: AlignmentDirectional(
        0,
        1.0
      ),
    )
  ,
        
        
        
      ),
    
      
      child: Column(
      
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      
      children: [Container(
      
      width: 100.0  ,height: 100.0  ,
      
      decoration: BoxDecoration(
        color: Color(0xCCFFFFFF)  ,
        
        
        
        borderRadius: BorderRadius.circular( 16.0  ),
        
        
      ),
    
      
      child: Padding(
             padding: EdgeInsets.all( 8.0),
             child:  Icon(
      
      Icons.animation,
      color: Color(0xFF4B39EF)  ,
      size: 44.0  ,
    )  ,
           )
           ,
    ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
Padding(
             padding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       12.0,
       0.0,
       0.0
  ),
             child: Text(
      
       'Sign In'  ,
      
      
      style: FlutterFlowTheme.of(context).headlineSmall.override(    fontFamily: 'Plus Jakarta Sans',
    color:  Color(0xFF101213)  ,
    fontSize: 22.0,
    letterSpacing: 0.0,
    fontWeight: FontWeight.bold,
    
    
    
    
  ),
      
      
    ).animateOnPageLoad(animationsMap['textOnPageLoadAnimation1']!),
           )
           ,
Padding(
             padding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       4.0,
       0.0,
       0.0
  ),
             child: Text(
      
       'Use the account below to sign in.'  ,
      
      
      style: FlutterFlowTheme.of(context).labelMedium.override(    fontFamily: 'Plus Jakarta Sans',
    color:  Color(0xFF57636C)  ,
    fontSize: 14.0,
    letterSpacing: 0.0,
    fontWeight: FontWeight.w500,
    
    
    
    
  ),
      
      
    ).animateOnPageLoad(animationsMap['textOnPageLoadAnimation2']!),
           )
           ,],
    ),
    ),
    ),
Align(
      alignment: AlignmentDirectional( 0.0  ,  0.0  ),
      child: Padding(
             padding: EdgeInsetsDirectional.fromSTEB(
       16.0,
       0.0,
       16.0,
       16.0
  ),
             child: Column(
      
      mainAxisSize: MainAxisSize.max,
      
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Column(
      
      mainAxisSize: MainAxisSize.max,
      
      
      children: [Align(
      alignment: AlignmentDirectional( 0.0  ,  0.0  ),
      child: Padding(
             padding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       0.0,
       0.0,
       16.0
  ),
             child: Wrap(
      
      spacing: 16.0,
      runSpacing: 0.0,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.horizontal,
      runAlignment: WrapAlignment.center,
      verticalDirection: VerticalDirection.down,
      clipBehavior: Clip.none,
      children: [Padding(
             padding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       0.0,
       0.0,
       16.0
  ),
             child: FFButtonWidget(
      
      onPressed:  () async {GoRouter.of(context).prepareAuthEvent();
final user = await authManager.signInWithGoogle(context);if (user == null) { return; }
    
    context.goNamedAuth(
      'ToDoList',
      context.mounted
      
      
      
      
    );
  },
      text: 'Continue with Google'  ,
      icon:  FaIcon(
        
        FontAwesomeIcons.google,
        
        size: 20.0  ,
      )  ,
      options: FFButtonOptions(
        width: 230.0  ,
        height: 44.0  ,
        padding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       0.0,
       0.0,
       0.0
  ),
        iconPadding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       0.0,
       0.0,
       0.0
  ),
        color: Colors.white  ,
        textStyle: FlutterFlowTheme.of(context).bodyMedium.override(    fontFamily: 'Plus Jakarta Sans',
    color:  Color(0xFF101213)  ,
    fontSize: 14.0,
    letterSpacing: 0.0,
    fontWeight: FontWeight.bold,
    
    
    
    
  ),
        elevation: 0.0  ,
        borderSide: BorderSide(
      color: Color(0xFFE0E3E7)  ,
      width: 2.0  ,
    ),
        borderRadius: BorderRadius.circular( 12.0  ),
        
        
        hoverColor: Color(0xFFF1F4F8)  ,
        
        
        
      ),
      
    ),
           )
           ,],
    ),
           )
           ,
    )
    ,],
    ),],
    ).animateOnPageLoad(animationsMap['columnOnPageLoadAnimation']!),
           )
           ,
    )
    ,
FFButtonWidget(
      
      onPressed:  () async {    
    context.pushNamed(
      'EmailAuth'
      
      
      
      
      
    );
  },
      text: 'Email Authentication'  ,
      
      options: FFButtonOptions(
        
        height: 40.0  ,
        padding: EdgeInsetsDirectional.fromSTEB(
       24.0,
       0.0,
       24.0,
       0.0
  ),
        iconPadding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       0.0,
       0.0,
       0.0
  ),
        color: FlutterFlowTheme.of(context).primary  ,
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(    fontFamily: 'Readex Pro',
    color:  Colors.white  ,
    
    letterSpacing: 0.0,
    
    
    
    
    
  ),
        elevation: 3.0  ,
        borderSide: BorderSide(
      color: Colors.transparent  ,
      width: 1.0  ,
    ),
        borderRadius: BorderRadius.circular( 8.0  ),
        
        
        
        
        
        
      ),
      
    ),],
    ),
    ),
)
;
  }

  
}
