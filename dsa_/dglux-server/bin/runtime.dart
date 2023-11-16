import "dart:convert";import "dart:io";import "dart:io" as c;import "dart:isolate";import "dart:async";const X=0x2f;const h=0x3a;const MB=0x41;const NB=0x5a;const OB=0x61;const PB=0x7a;const i=0x5c;e QB()=>new e.ZB();class e{e.ZB():M=J.o as R,cB=null;final R M;final String cB;String get current=>cB!=null?cB:LB;String get Q=>M.Q;String absolute(String A,[String B,String C,String D,String G,String H,String I]){n("absolute",[A,B,C,D,G,H,I]);if(B==null&&isAbsolute(A)&&!L(A)){return A;}return join(current,A,B,C,D,G,H,I);}bool isAbsolute(String A)=>M.P(A)>0;bool L(String A)=>M.L(A);String join(String B,[String C,String D,String G,String H,String I,String N,String a]){var A=<String>[B,C,D,G,H,I,N,a];n("join",A);return VB(A.where((b)=>b!=null));}String VB(Iterable<String> I){var B=new StringBuffer();var D=false;var G=false;for(var A in I.where((A)=>A!='')){if(this.L(A)&&G){var C=dB(A);var H=B.toString();C.O=H.substring(0,M.P(H,withDrive:true));if(M.Z(C.O)){C.U[0]=M.Q;}B.clear();B.write(C.toString());}else if(this.isAbsolute(A)){G=!this.L(A);B.clear();B.write(A);}else{if(A.length>0&&M.f(A[0])){}else if(D){B.write(Q);}B.write(A);}D=M.Z(A);}return B.toString();}List<String> split(String B){var A=dB(B);A.S=A.S.where((C)=>!C.isEmpty).toList();if(A.O!=null)A.S.insert(0,A.O);return A.S;}Y dB(String A)=>new Y.aB(A,M);}void n(String H,List<String> A){for(var B=1;B<A.length;B++ ){if(A[B]==null||A[B-1]!=null)continue;int C;for(C=A.length;C>=1;C-- ){if(A[C-1]!=null)break;}var D=new StringBuffer();D.write("${H}(");D.write(A.take(C).map((G)=>G==null?"null":'"${G}"').join(", "));D.write("): part ${B-1} was null, but part ${B} was not.");throw new ArgumentError(D.toString());}}const String IB=r"""
import "dart:async";
import "dart:io";
import "dart:isolate";
import "{{uri}}" as run;

main(List<String> args, msg) async {
  var rp = new ReceivePort();
  SendPort sp;
  if (msg is SendPort) {
    sp = msg;
  } else {
    sp = rp.sendPort;
  }

  var rcfg = {};

  rp.listen((x) {
    if (x == "STOP") {
      if (rcfg != null && rcfg["closeHandler"] is Function) {
        rcfg["closeHandler"]();
      }
      rp.close();
    }
  });

  sp.send(rp.sendPort);

  var file = new File("{{log_file}}");
  if (!(await file.exists())) {
    await file.create(recursive: true);
  }
  var raf = await file.openWrite(mode: FileMode.APPEND);
  var spec = new ZoneSpecification(print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
    raf.writeln("[${currentTimestamp}] ${line}");
  }, handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace) {
    var out = [];
    out.addAll(error.toString().split("\n"));
    out.addAll(stackTrace.toString().split("\n"));

    for (var line in out) {
      raf.writeln("[${currentTimestamp}] ${line}");
    }
    out.clear();
  });

  return await runZoned(() async {
    return await run.main(args);
  }, zoneSpecification: spec, zoneValues: {
    "dslink.runtime.config": rcfg
  });
}

String get currentTimestamp => new DateTime.now().toString();
""";main(List<String> G)async{c.stdin.transform(const Utf8Decoder()).listen((String A){if(A.startsWith("\u0002")&&A.endsWith("\u0003")){try {var B=A.substring(1,A.length-1);var C=const JsonDecoder().convert(B);JB(C);}catch (H){}}});var D=const JsonEncoder().convert({"event":"runtime.ready"});c.stdout.write("\u0002${D}\u0003");}JB(Map G)async{String CB=G["event"];if(CB=="start"){String A=G["path"];try {String WB=G["main"];Map<String,dynamic> B=G["configs"];var a=new Directory(A);var b=[] ;for(var C in B.keys){if(B[C] is Map){B[C]=B[C]["value"];}if(C=="log-file"){continue;}b.add("--${C}=${B[C]}");}b.add("--base-path=${a.path}");var DB=new File(g(a.path,WB)).absolute;var H=IB;H=H.replaceAll("{{uri}}",DB.uri.toString());H=H.replaceAll("{{log_file}}",B["log-file"].toString());var EB=new File(g(a.path,".rtm_stub"));await EB.writeAsString(H);var k=new ReceivePort();var FB=new Directory(g(DB.parent.path,"packages"));Uri GB;if(await FB.exists()){GB=FB.uri;}var D=await Isolate.spawnUri(EB.uri,b,k.sendPort,paused:true,packageRoot:GB);var l=new ReceivePort();l.listen((N){if(N=="EXIT"){var I=const JsonEncoder().convert({"event":"stopped","path":A});c.stdout.write("\u0002${I}\u0003");d.remove(A);l.close();k.close();V.remove(A);}});D.addOnExitListener(l.sendPort,response:"EXIT");d[A]=D;D.resume(D.pauseCapability);k.listen((HB){if(HB is SendPort){V[A]=HB;}});var I=const JsonEncoder().convert({"event":"ready","path":A});c.stdout.write("\u0002${I}\u0003");}catch (N,XB){var I=const JsonEncoder().convert({"event":"ready","path":A});c.stdout.write("\u0002${I}\u0003");d.remove(A);await new Future.delayed(const Duration(seconds:1));var YB=const JsonEncoder().convert({"event":"fail","path":A,"summary":N.toString(),"stack":XB.toString()});c.stdout.write("\u0002${YB}\u0003");V.remove(A);return;}}else if(CB=="stop"){var A=G["path"];try {if(V[A] is SendPort){V[A].send("STOP");}await new Future.delayed(const Duration(milliseconds:500));var D=d.remove(A);D.kill(priority:Isolate.IMMEDIATE);V.remove(A);}catch (N){}}}Map<String,Isolate> d={};Map<String,SendPort> V={};abstract class R extends J{String get Q;bool f(String A);bool K(int A);bool Z(String A);int P(String A,{bool withDrive: false});String t(String A){var B=P(A);if(B>0)return A.substring(0,B);return L(A)?A[0]:null;}bool L(String A);}class Y{R M;String O;bool L;List<String> S;List<String> U;bool get isAbsolute=>O!=null;factory Y.aB(String A,R D){var H=D.t(A);var N=D.L(A);if(H!=null)A=A.substring(H.length);var I=<String>[] ;var G=<String>[] ;var B=0;if(A.isNotEmpty&&D.K(A.codeUnitAt(0))){G.add(A[0]);B=1;}else{G.add('');}for(var C=B;C<A.length;C++ ){if(D.K(A.codeUnitAt(C))){I.add(A.substring(B,C));G.add(A[C]);B=C+1;}}if(B<A.length){I.add(A.substring(B));G.add('');}return new Y.bB(D,H,N,I,G);}Y.bB(this.M,this.O,this.L,this.S,this.U);String toString(){var A=new StringBuffer();if(O!=null)A.write(O);for(var B=0;B<S.length;B++ ){A.write(U[B]);A.write(S[B]);}A.write(U.last);return A.toString();}}final e KB=QB();String get LB{var B=Uri.base;if(B==m)return W;m=B;if(J.o==J.j){W=B.resolve('.').toString();return W;}else{var A=B.toFilePath();var C=A.length-1;assert(A[C]=='/'||A[C]=='\\');W=C==0?A:A.substring(0,C);return W;}}Uri m;String W;String g(String A,[String B,String C,String D,String G,String H,String I,String N])=>KB.join(A,B,C,D,G,H,I,N);class p extends R{p();final name='posix';final Q='/';final U=const['/'];final BB=new RegExp(r'/');final u=new RegExp(r'[^/]$');final AB=new RegExp(r'^/');final v=null;bool f(String A)=>A.contains('/');bool K(int A)=>A==X;bool Z(String A)=>A.isNotEmpty&&!K(A.codeUnitAt(A.length-1));int P(String A,{bool withDrive: false}){if(A.isNotEmpty&&K(A.codeUnitAt(0)))return 1;return 0;}bool L(String A)=>false;}abstract class J{static final J RB=new p();static final J SB=new r();static final J j=new q();static final J o=TB();static J TB(){if(Uri.base.scheme!='file')return J.j;if(!Uri.base.path.endsWith('/'))return J.j;if(new Uri(path:'a/b').toFilePath()=='a\\b')return J.SB;return J.RB;}String get name;String get Q;String t(String A);String toString()=>name;}class q extends R{q();final name='url';final Q='/';final U=const['/'];final BB=new RegExp(r'/');final u=new RegExp(r"(^[a-zA-Z][-+.a-zA-Z\d]*://|[^/])$");final AB=new RegExp(r"[a-zA-Z][-+.a-zA-Z\d]*://[^/]*");final v=new RegExp(r"^/");bool f(String A)=>A.contains('/');bool K(int A)=>A==X;bool Z(String A){if(A.isEmpty)return false;if(!K(A.codeUnitAt(A.length-1)))return true;return A.endsWith("://")&&P(A)==A.length;}int P(String A,{bool withDrive: false}){if(A.isEmpty)return 0;if(K(A.codeUnitAt(0)))return 1;for(var C=0;C<A.length;C++ ){var D=A.codeUnitAt(C);if(K(D))return 0;if(D==h){if(C==0)return 0;if(A.startsWith('//',C+1))C+= 3;var B=A.indexOf('/',C);if(B<=0)return A.length;if(!withDrive||A.length<B+3)return B;if(!A.startsWith('file://'))return B;if(!UB(A,B+1))return B;return A.length==B+3?B+3:B+4;}}return 0;}bool L(String A)=>A.isNotEmpty&&K(A.codeUnitAt(0));}bool s(int A)=>(A>=MB&&A<=NB)||(A>=OB&&A<=PB);bool UB(String A,int B){if(A.length<B+2)return false;if(!s(A.codeUnitAt(B)))return false;if(A.codeUnitAt(B+1)!=h)return false;if(A.length==B+2)return true;return A.codeUnitAt(B+2)==X;}class r extends R{r();final name='windows';final Q='\\';final U=const['/','\\'];final BB=new RegExp(r'[/\\]');final u=new RegExp(r'[^/\\]$');final AB=new RegExp(r'^(\\\\[^\\]+\\[^\\/]+|[a-zA-Z]:[/\\])');final v=new RegExp(r"^[/\\](?![/\\])");bool f(String A)=>A.contains('/');bool K(int A)=>A==X||A==i;bool Z(String A){if(A.isEmpty)return false;return !K(A.codeUnitAt(A.length-1));}int P(String A,{bool withDrive: false}){if(A.isEmpty)return 0;if(A.codeUnitAt(0)==X)return 1;if(A.codeUnitAt(0)==i){if(A.length<2||A.codeUnitAt(1)!=i)return 1;var B=A.indexOf('\\',2);if(B>0){B=A.indexOf('\\',B+1);if(B>0)return B;}return A.length;}if(A.length<3)return 0;if(!s(A.codeUnitAt(0)))return 0;if(A.codeUnitAt(1)!=h)return 0;if(!K(A.codeUnitAt(2)))return 0;return 3;}bool L(String A)=>P(A)==1;}