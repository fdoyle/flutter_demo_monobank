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

  int totalSpent;
  List<double> percentages;
  List<double> sectionStartPercentage;

  BankingData(this.entries) {
    totalSpent = entries
        .map((entry) => entry.amount)
        .fold(0, (total, entry) => total + entry);
    percentages = entries
        .map((entry) => (entry.amount / totalSpent))
        .toList(); //what percentage of the whole is each entry

    //if I want to lay these values out on a line from 0 to 1 (or divide up a circle, as we will later),
    // where along that 0 to 1 line does each 'section' start.
    double runningTotal = 0;
    List<double> offsets = List();
    for (double p in percentages) {
      offsets.add(runningTotal);
      runningTotal += p;
    }
    offsets.add(1);
    sectionStartPercentage = offsets;
  }

  int getTotal() {
    return totalSpent;
  }

  List<BankingEntry> getBankingEntries() {
    return entries;
  }
}

class BankingEntry {
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
  double currentPageViewPosition = 0;

  @override
  Widget build(BuildContext context) {
    PageController controller = PageController();
    PageController iconController = PageController();
    controller.addListener(() {
      setState(() {
        currentPageViewPosition = controller.page;
      });
      iconController.jumpTo(controller.position
          .pixels); //sync the iconController position to the default controller position
    });

    double pageScrolledPercent = currentPageViewPosition -
        currentPageViewPosition.floor(); //fractional part of currentPage
    int currentPageNumber =
        currentPageViewPosition.floor(); //whole part of currentPage

    double currentPageOffset =
        bankingData.sectionStartPercentage[currentPageNumber];
    double currentPageSize = bankingData.percentages[currentPageNumber];

    double nextPageSectionStart =
        bankingData.sectionStartPercentage[currentPageNumber + 1];
    double nextPageSize;
    if (currentPageNumber + 1 >= bankingData.percentages.length) {
      nextPageSize = 0; //we're at the last page, so this value will never be used. That changes if you want an infinite viewpager
    } else {
      nextPageSize = bankingData.percentages[currentPageNumber + 1];
    }

    double sectionStartOffsetPercent =
        pageScrolledPercent * currentPageSize + currentPageOffset;
    double sectionEndOffsetPercent =
        pageScrolledPercent * nextPageSize + nextPageSectionStart;

    double startDegrees = 360 * sectionStartOffsetPercent;
    double endDegrees = 360 * sectionEndOffsetPercent;

    MaterialColor color = bankingData.entries[currentPageNumber].color;
    MaterialColor nextColor;
    if (currentPageNumber + 1 >= bankingData.entries.length) {
      nextColor = Colors.red; //we're at the last page, so the color of the page after that will never be used. this is just an arbitrary placeholder
    } else {
      nextColor = bankingData.entries[currentPageNumber + 1].color;
    }

    Color blendedColor = Color.alphaBlend(
            nextColor.withAlpha((255 * pageScrolledPercent).round()), color)
        .withAlpha(80);

    //how do you make a widget expand to fill?
    //Container -> set its constraint to BoxConstraints.expand()
    //Stack -> wrap its child in a Positioned.fill widget
    //row/column -> wrap its child in an Expanded

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
        constraints: BoxConstraints.expand(), //this causes a container and its child to try to fill its parent. by default, it'll just wrap its child.
        child: Stack(
          children: <Widget>[
            Positioned.fill( //this will cause its child to match the size of the stack
                child: IgnorePointer(
                    child: Container(
                        decoration: BoxDecoration(
                            // Box decoration takes a gradient
                            gradient: RadialGradient(
              radius: 1.4,
              // Where the linear gradient begins and ends
              // Add one stop for each color. Stops should increase from 0 to 1
              stops: [0, 2],
              colors: [
                // Colors are easy thanks to Flutter's Colors class.
                blendedColor,
                Colors.transparent,
              ],
            ))))),

            Positioned.fill(
                child: PageView.builder(
                    //this pageview will handle all touch interaction
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
                //this clips the paging icon so that it only appears within the clear inner part of the pie chart
                clipper: IconPagerClipper(),
                child: PageView.builder(
                    //this pageview is bound to the one above, and does not handle its own state either touch events or snapping
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
                      bankingData, color, nextColor, pageScrolledPercent),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BankPieChartOverlayArc(startDegrees, endDegrees,
                      color, nextColor, pageScrolledPercent),
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

//CustomClipper<Rect> returns a rect from getClip, and ClipOval uses this to clip its child to only draw
//inside a circle that fits inside that rect.
class IconPagerClipper extends CustomClipper<Rect> {
  @override
  bool shouldReclip(IconPagerClipper oldClipper) => true;

  @override
  Rect getClip(Size size) {
    //the outer radius for the moving arc is size.width/2
    //the inner radius for that same arc is outerRadius/2 or size.width/4
    //the inner radius for the background pie chart is a bit longer than innerArcRadius, or innerArcRadius+INSET
    double innerPieChartRadius = min(size.width, size.height) / 2 / 2 + INSET;
    Offset center = Offset(size.width / 2, size.height / 2);
    return Rect.fromCircle(center: center, radius: innerPieChartRadius);
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
    //alphaBlend takes two colors, laying the transparent foreground over the opaque background.
    //note that you are responsible for actually making the foreground color transparent.
    Color blendedColor = Color.alphaBlend(
            nextColor.withAlpha((255 * blend).round()), color)
        .withAlpha(
            70); //The resulting color will be totally opaque, so this makes it transparent

    double radius = min(size.width, size.height) / 2.0;
    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius),
        Paint()); //this call ensures the 'clear' below only clears pixels drawn after it
    canvas.drawColor(Colors.black26, BlendMode.srcATop);
    canvas.drawCircle(center, radius - INSET, Paint()..color = blendedColor);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius / 2 + INSET,
        Paint() //IIRC, android best practice is not to recreate the Paint object, not sure about flutter.
          ..blendMode = BlendMode.clear
          ..color = Colors.black);
    data.sectionStartPercentage.forEach((p) {
      //draw 'clear' lines to divide each section
      //this ensures the separation between each section is a constant width from the inner radius to outer radius
      //which results in a better final result than drawing separate arcs for each section.
      //this is as opposed to drawing an arc for each section and simply leaving a gap.
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
    return !(oldDelegate
            is BankPieChartCustomPainter && //a "real" implementation would probably want to check that the banking data is the same too
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

    //would probably be better to work in radians at all times, but I'm not doing that.
    double startAngleRadians = startAngle * vector.degrees2Radians;
    double endAngleRadians = endAngle * vector.degrees2Radians;

    //this results in some really funky transitions, but my color theory isn't good enough to improve it.
    //like, going from green to purple goes through grey because math
    Color gradientStartColor =
        Color.alphaBlend(nextColor.withAlpha((255 * blend).round()), color);
    Color gradientEndColor = Color.alphaBlend(
        nextColor.shade800.withAlpha((255 * blend).round()), color.shade800);

    //with the following, we're creating a gradient that covers the entire canvas rect
    //you could imagine the draw commands below as copying chunks of space from this
    final rect = new Rect.fromLTWH(0.0, 0.0, size.width, size.height);
    final gradient = new SweepGradient(
      startAngle: startAngleRadians,
      endAngle: endAngleRadians,
      tileMode: TileMode.repeated,
      colors: [gradientStartColor, gradientEndColor],
    );

    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius), Paint());
    canvas.drawArc(
        //this creates a filled arc
        Rect.fromCircle(center: center, radius: radius),
        startAngle * vector.degrees2Radians,
        vector.degrees2Radians * (endAngle - startAngle),
        true,
        Paint()..shader = gradient.createShader(rect));

    canvas.drawCircle(
        //and this cuts out the center. might be better to "draw" this as an arc too?
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
