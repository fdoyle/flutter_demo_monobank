import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

void main() => runApp(MyApp());

const double INSET = 10;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.grey,
        primaryColor: Colors.black,
        primaryColorDark: Colors.black,
      ),
      home: MyHomePage(title: 'Monobank'),
    );
  }
}

class BankingData {
  List<BankingEntry> entries;

  int total;
  List<double> percentages;
  List<double> percentageOffsets;

  BankingData(this.entries) {
    total = entries
        .map((entry) => entry.amount)
        .fold(0, (total, entry) => total + entry);
    percentages = entries.map((entry) => (entry.amount / total)).toList();

    double runningTotal = 0;
    List<double> o = List();
    for (double p in percentages) {
      o.add(runningTotal);
      runningTotal += p;
    }
    o.add(1);
    percentageOffsets = o;
  }

  int getTotal() {
    return total;
  }

  List<BankingEntry> getBankingEntries() {
    return entries;
  }
}

class BankingEntry {
  //todo needs color data
  String label;
  int amount;
  IconData icon;
  Color color;

  BankingEntry(this.label, this.amount, this.icon, this.color);
}

BankingData bankingData = BankingData(<BankingEntry>[
  BankingEntry("Groceries", 483, Icons.free_breakfast, Colors.red),
  BankingEntry("Tourism", 346, Icons.map, Colors.blue),
  BankingEntry("Shopping", 120, Icons.shopping_cart, Colors.green),
  BankingEntry("Transport", 137, Icons.directions_car, Colors.purple),
]);

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double currentPage = 0;

  @override
  Widget build(BuildContext context) {
    PageController controller = PageController();
    PageController iconController = PageController();
    controller.addListener(() {
      setState(() {
        currentPage = controller.page;
      });
      iconController.jumpTo(controller.position
          .pixels); //these pageviews must have same size for this to work
    });

    double pageFraction = currentPage - currentPage.floor();
    int currentPageNumber = currentPage.floor();


    //current start will be {pageFraction}% between {currentPageNumber} offset and {currentPageNumber+1} offset
    double currentPageOffset = bankingData.percentageOffsets[currentPageNumber];
    double currentPageSize = bankingData.percentages[currentPageNumber];

    double nextPageOffset =
        bankingData.percentageOffsets[currentPageNumber + 1];
    double nextPageSize;
    if (currentPageNumber + 1 >= bankingData.percentages.length) {
      nextPageSize = 0; //we're at the last one, don't wrap yet
    } else {
      nextPageSize = bankingData.percentages[currentPageNumber + 1];
    }

    double startOffset = pageFraction * currentPageSize + currentPageOffset;
    double endOffset = pageFraction * nextPageSize + nextPageOffset;

    double startDegrees = 360 * startOffset;
    double endDegrees = 360 * endOffset;

    MaterialColor color = bankingData.entries[currentPageNumber].color;
    MaterialColor nextColor;
    if (currentPageNumber + 1 >= bankingData.entries.length) {
      nextColor = Colors.red;
    } else {
      nextColor = bankingData.entries[currentPageNumber + 1].color;
    }

    Color blendedColor =
    Color.alphaBlend(nextColor.withAlpha((255 * pageFraction).round()), color)
        .withAlpha(80);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
        constraints: BoxConstraints.expand(),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
                child: IgnorePointer(
                    child: Container(
                        decoration: BoxDecoration(
                            // Box decoration takes a gradient
                            gradient: RadialGradient(
                              radius: 1.4,
              // Where the linear gradient begins and ends
              // Add one stop for each color. Stops should increase from 0 to 1
              stops: [0,  2],
              colors: [
                // Colors are easy thanks to Flutter's Colors class.
                blendedColor,
                Colors.transparent,
              ],
            ))))),

            Positioned.fill(
                child: PageView.builder(
                    itemCount: bankingData.entries.length,
                    controller: controller,
                    itemBuilder: (context, index) {
                      return Column(
                        children: <Widget>[
                          Text("\$${bankingData.entries[index].amount} ",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold)),
                          Text("${bankingData.entries[index].label}",
                              style: TextStyle(
                                  color: bankingData.entries[index].color,
                                  fontSize: 20))
                        ],
                      );
                    })),
            Positioned.fill(
                child: IgnorePointer(
              child: ClipOval(
                clipper: IconPagerClipper(),
                child: PageView.builder(
                    itemCount: bankingData.entries.length,
                    controller: iconController,
                    pageSnapping: false,
                    itemBuilder: (context, index) {
                      return Center(
                          child: Icon(
                        bankingData.entries[index].icon,
                        color: bankingData.entries[index].color,
                        size: 50,
                      ));
                    }),
              ),
            )),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BankPieChartCustomPainter(
                      bankingData, color, nextColor, pageFraction),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BankPieChartOverlayArc(startDegrees, endDegrees,
                      color, nextColor, pageFraction),
                ),
              ),
            )

            //background glow,
          ],
        ),
      ),
    );
  }
}

class IconPagerClipper extends CustomClipper<Rect> {
  @override
  bool shouldReclip(IconPagerClipper oldClipper) => true;

  @override
  Rect getClip(Size size) {
    double radius = min(size.width, size.height) / 4 + INSET;
    Offset center = Offset(size.width / 2, size.height / 2);
    print(radius);

    return Rect.fromCircle(center: center, radius: radius);
  }
}

class BankPieChartCustomPainter extends CustomPainter {
  BankingData data;
  Color color;
  Color nextColor;
  double blend;

  BankPieChartCustomPainter(this.data, this.color, this.nextColor, this.blend);

  @override
  void paint(Canvas canvas, Size size) {
    Color blendedColor =
        Color.alphaBlend(nextColor.withAlpha((255 * blend).round()), color)
            .withAlpha(70);

    double radius = min(size.width, size.height) / 2.0;
    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius), Paint());
    canvas.drawColor(Colors.black26, BlendMode.srcATop);
    canvas.drawCircle(center, radius - INSET, Paint()..color = blendedColor);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius / 2 + INSET,
        Paint()
          ..blendMode = BlendMode.clear
          ..color = Colors.black);
    data.percentageOffsets.forEach((p) {
      canvas.drawLine(
          center,
          center + Offset(cos(p * 2 * pi) * radius, sin(p * 2 * pi) * radius),
          Paint()
            ..blendMode = BlendMode.clear
            ..strokeWidth = 2);
    });
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return !(oldDelegate is BankPieChartCustomPainter &&
        oldDelegate.color == color);
  }
}

class BankPieChartOverlayArc extends CustomPainter {
  double startAngle;
  double endAngle;
  MaterialColor color;
  MaterialColor nextColor;
  double blend;

  BankPieChartOverlayArc(
      this.startAngle, this.endAngle, this.color, this.nextColor, this.blend);

  @override
  void paint(Canvas canvas, Size size) {
    double radius = min(size.width, size.height) / 2.0;
    Offset center = Offset(size.width / 2, size.height / 2);

    double startAngleRadians = startAngle * vector.degrees2Radians;
    double endAngleRadians = endAngle * vector.degrees2Radians;

    //this results in some really funky transitions, but my color theory isn't good enough to improve it.
    //like, going from green to purple goes through grey because math
    Color gradientStartColor =
        Color.alphaBlend(nextColor.withAlpha((255 * blend).round()), color);
    Color gradientEndColor = Color.alphaBlend(
        nextColor.shade800.withAlpha((255 * blend).round()), color.shade800);

    final rect = new Rect.fromLTWH(0.0, 0.0, size.width, size.height);
    final gradient = new SweepGradient(
      startAngle: startAngleRadians,
      endAngle: endAngleRadians,
      tileMode: TileMode.repeated,
      colors: [gradientStartColor, gradientEndColor],
    );

    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius), Paint());
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle * vector.degrees2Radians,
        vector.degrees2Radians * (endAngle - startAngle),
        true,
        Paint()..shader = gradient.createShader(rect));

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius / 2,
        Paint()
          ..blendMode = BlendMode.clear
          ..color = Colors.black);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return !(oldDelegate is BankPieChartOverlayArc &&
        oldDelegate.startAngle == startAngle &&
        oldDelegate.endAngle == endAngle);
  }
}
