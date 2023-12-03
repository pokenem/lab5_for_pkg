import 'package:flutter/material.dart';
import 'package:zoom_widget/zoom_widget.dart';
import 'dart:math';
import 'dart:io';

void main() {
  runApp(MaterialApp(routes: {
    '/': (context) => HomePage(),
    '/paint': (context) => MyApp(),
  }, initialRoute: '/',));
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body:  Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height:150, width: 300,child: ElevatedButton(onPressed: (){Navigator.pushNamed(context, '/paint', arguments: Type.Cirus);}, child: Text("Алгоритм Кируса-Бека"))),
              SizedBox(height: 80,),
              SizedBox(height:150, width: 300, child: ElevatedButton(onPressed: (){Navigator.pushNamed(context, '/paint', arguments: Type.Central);}, child: Text("Алгоритм средней точки"))),
            ],
          ),
      ),
    );
  }
}

class Plane {
  List<(Point, Point)> segments = [];

  List<(Point, Point)> clippedSegments = [];

  List<(Point, Point)> polygon = [];

  double Xmin = 0, Ymin = 0, Xmax = 0, Ymax = 0;
  double t_1 = 0, t_2 = 0;
  Type t = Type.Central;
  bool onLine = false;

  Plane(Type t) {
    var file = File("C:/Users/andre/AndroidStudioProjects/lab5_for_pkg/lib/input.txt");
    var lines = file.readAsLinesSync();

    int n = int.parse(lines[0]);
    for (int i = 1; i <= n; i++) {
      var coords = lines[i].split(' ');
      int x1 = int.parse(coords[0]);
      int y1 = int.parse(coords[1]);
      int x2 = int.parse(coords[2]);
      int y2 = int.parse(coords[3]);
      Point p1 = Point(x1.toDouble(), y1.toDouble());
      Point p2 = Point(x2.toDouble(), y2.toDouble());
      segments.add((p1, p2));
    }

    var bounds = lines[n + 1].split(' ');
    Xmin = double.parse(bounds[0]);
    Ymin = double.parse(bounds[1]);
    Xmax = double.parse(bounds[2]);
    Ymax = double.parse(bounds[3]);

    int m = int.parse(lines[n + 2]);
    for (int i = n + 3; i < n + 3 + m; i++) {
      var coords = lines[i].split(' ');
      int x1 = int.parse(coords[0]);
      int y1 = int.parse(coords[1]);
      int x2 = int.parse(coords[2]);
      int y2 = int.parse(coords[3]);
      Point p1 = Point(x1.toDouble(), y1.toDouble());
      Point p2 = Point(x2.toDouble(), y2.toDouble());
      polygon.add((p1, p2));
    }

    this.t = t;

    if (t == Type.Central) {
      clipSegments();
    } else {
      cirus();
    }
  }

  void clipSegments() {
    List<(Point, Point)> segmentsCopy = List.from(segments);

    for (int i = 0; i < segmentsCopy.length; i++) {
      Point P1 = segmentsCopy[i].$1;
      Point P2 = segmentsCopy[i].$2;
      int P1_code = getCode(P1);
      int P2_code = getCode(P2);

      if (sqrt(pow(P1.x - P2.x, 2) + pow(P1.y - P2.y, 2)) <= 1) {
        return;
      }

      if ((P1_code | P2_code) == 0) {
        clippedSegments.add(segmentsCopy[i]);
      } else if ((P1_code & P2_code) != 0) {
        continue;
      } else {
        if (P1_code == 0) {
          Point tmp = P1;
          P1 = P2;
          P2 = tmp;
        }
        segmentsCopy[i] = (P2, intersectionPoint(P1, P2));
        i--;
      }
    }
  }

  int getCode(Point point) {
    double x = point.x.toDouble();
    double y = point.y.toDouble();

    int code = 0;

    if (x < Xmin) code += 1;
    if (x > Xmax) code += 2;
    if (y < Ymin) code += 4;
    if (y > Ymax) code += 8;

    return code;
  }

  Point intersectionPoint(Point P1, Point P2) {
    int P1_code = getCode(P1);

    Point intersectionPoint = Point(0, 0);

    if ((P1_code & 8) != 0) {
      intersectionPoint = Point(P1.x + (P2.x - P1.x) * (Ymax - P1.y) / (P2.y - P1.y), Ymax);
    } else if ((P1_code & 4) != 0) {
      intersectionPoint = Point(P1.x + (P2.x - P1.x) * (Ymin - P1.y) / (P2.y - P1.y), Ymin);
    } else if ((P1_code & 2) != 0) {
      intersectionPoint = Point(Xmax, P1.y + (P2.y - P1.y) * (Xmax - P1.x) / (P2.x - P1.x));
    } else if ((P1_code & 1) != 0) {
      intersectionPoint = Point(Xmin, P1.y + (P2.y - P1.y) * (Xmin - P1.x) / (P2.x - P1.x));
    }

    return intersectionPoint;
  }

  void cirus() {
    for (int i = 0; i < segments.length; i++) {
      ClipByCirus(segments[i]);
      if (t_1 < 0 || t_1 > 1 || t_2 < 0 || t_2 > 1) {
        continue;
      } else {
        Point begin = segments[i].$1;
        Point end = segments[i].$2;
        Point p1 = Point(begin.x + t_1 * (end.x - begin.x), begin.y + t_1 * (end.y - begin.y));
        Point p2 = Point(begin.x + t_2 * (end.x - begin.x), begin.y + t_2 * (end.y - begin.y));
        clippedSegments.add((p1, p2));
      }
    }
  }

  double getT((Point, Point) edge, (Point, Point) segment, bool onLine) {
    bool a;
    double ks = (segment.$2.y - segment.$1.y) / (segment.$2.x - segment.$1.x);
    double ke = (edge.$2.y - edge.$1.y) / (edge.$2.x - edge.$1.x);
    double bs = segment.$1.y - ks * segment.$1.x;
    double be = edge.$1.y - ke * edge.$1.x;
    double x = (be - bs) / (ks - ke);
    if ((x - edge.$1.x) / (edge.$2.x - edge.$1.x) <= 0 || (x - edge.$1.x) / (edge.$2.x - edge.$1.x) >= 1) {
      return -1;
    }
    if ((segment.$2.x - segment.$1.x) == 0 && ke == ks && be == bs) {
      a = true;
      this.onLine = a;
      return -1;
    } else {
      double te = (x - segment.$1.x) / (segment.$2.x - segment.$1.x);
      return te;
    }
  }

  double ScalarMultiply((Point, Point) v1, (Point, Point) v2) {
    double v1x1 = v1.$1.y.toDouble();
    double v1x2 = v1.$2.y.toDouble();
    double v1y1 = v1.$1.x.toDouble();
    double v1y2 = v1.$2.x.toDouble();
    double v2x1 = v2.$1.x.toDouble();
    double v2x2 = v2.$2.x.toDouble();
    double v2y1 = v2.$1.y.toDouble();
    double v2y2 = v2.$2.y.toDouble();
    return (-(v1x2 - v1x1) * (v2x2 - v2x1) + (v1y2 - v1y1) * (v2y2 - v2y1));
  }

  double getParameterOfPoint(Point p, (Point, Point) segment) {
    return (p.x - segment.$1.x) / (segment.$2.x - segment.$1.x);
  }

  ClipByCirus((Point, Point) segment) {
    List<double> T_enter = [];
    List<double> T_outer = [];
    double t, S;
    this.onLine = false;
    for (int i = 0; i < polygon.length; i++) {
      t = getT(polygon[i], segment, onLine);
      if (onLine) {
        T_enter.add(getParameterOfPoint(polygon[i].$1, segment));
        T_outer.add(getParameterOfPoint(polygon[i].$2, segment));
        T_outer.add(getParameterOfPoint(polygon[i].$1, segment));
        T_enter.add(getParameterOfPoint(polygon[i].$2, segment));
        this.onLine = false;
        continue;
      }
      S = -ScalarMultiply(polygon[i], segment);
      if (t >= 0 && t <= 1) {
        if (S > 0) {
          T_enter.add(t);
        } else if (S < 0) {
          T_outer.add(t);
        } else {
          T_enter.add(t);
          T_outer.add(t);
        }
      }
    }
    if (T_outer.length == 0 && T_enter.length == 0) {
      t_1 = -1;
      t_2 = -1;
      return;
    }

    double t_enter = 0;
    double t_outer = 1;
    for (int i = 0; i < T_enter.length; i++) {
      if (t_enter < T_enter[i]) {
        t_enter = T_enter[i];
      }
    }
    for (int i = 0; i < T_outer.length; i++) {
      if (t_outer > T_outer[i]) {
        t_outer = T_outer[i];
      }
    }
    t_1 = t_enter;
    t_2 = t_outer;
  }
}

enum Type { Central, Cirus }

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return Scaffold(
      appBar: AppBar(),
      body: Zoom(
        child: Center(
          child: CustomPaint(
            size: Size(920, 920),
            painter: MyPainter(arguments),
          ),
        ),
      ),
    );
  }
}

Offset iToOffset(double x, double y, Size size) {
  return Offset((size.width / 2 + x * 20).toDouble(), (size.height / 2 - y * 20).toDouble());
}

class MyPainter extends CustomPainter {
  final t;
  MyPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    var plane = Plane(t);
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), Paint());
    }
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), Paint());
    }
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), Paint()..strokeWidth = 3);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), Paint()..strokeWidth = 3);
    TextStyle textStyle1 = TextStyle(
      color: Colors.black,
      fontSize: 30,
    );
    TextSpan textSpan = TextSpan(
      text: "X",
      style: textStyle1,
    );
    TextPainter textPainter1 = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter1.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    textPainter1.paint(canvas, Offset(size.width, size.height / 2));
    TextSpan textSpan1 = TextSpan(
      text: "Y",
      style: textStyle1,
    );
    TextPainter textPainter2 = TextPainter(
      text: textSpan1,
      textDirection: TextDirection.ltr,
    );
    textPainter2.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    textPainter2.paint(canvas, Offset(size.width / 2 - 30, 0));
    for (double i = 0; i < size.width; i += 20) {
      TextStyle textStyle = TextStyle(
        color: Colors.black,
        fontSize: 10,
      );
      TextSpan textSpan = TextSpan(
        text: (((i / 20) - size.width / 40)).toInt().toString(),
        style: textStyle,
      );
      TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      textPainter.paint(canvas, Offset(i, size.height / 2));
    }
    for (double i = 0; i < size.height; i += 20) {
      TextStyle textStyle = TextStyle(
        color: Colors.black,
        fontSize: 10,
      );
      TextSpan textSpan = TextSpan(
        text: ((size.height / 40 - (i / 20))).toInt().toString(),
        style: textStyle,
      );
      TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      textPainter.paint(canvas, Offset(size.width / 2, i));
    }
    for (dynamic it in plane.segments) {
      canvas.drawLine(iToOffset(it.$1.x, it.$1.y, size), iToOffset(it.$2.x, it.$2.y, size), Paint()..strokeWidth = 3);
    }
    if(plane.t == Type.Central)
      {
        canvas.drawRect(Rect.fromPoints(iToOffset(plane.Xmin, plane.Ymin, size), iToOffset(plane.Xmax, plane.Ymax, size)), Paint()..strokeWidth = 3..style = PaintingStyle.stroke);
      }
    else
    for (dynamic it in plane.polygon) {
      canvas.drawLine(iToOffset(it.$1.x, it.$1.y, size), iToOffset(it.$2.x, it.$2.y, size), Paint()..strokeWidth = 3);
    }
    for(dynamic it in plane.clippedSegments){
      canvas.drawLine(iToOffset(it.$1.x, it.$1.y, size), iToOffset(it.$2.x, it.$2.y, size), Paint()..strokeWidth = 3..color = Colors.red);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
  }
}
