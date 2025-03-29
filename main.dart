 import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تقرير السيارة',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
      ),
      home: CarReportScreen(),
    );
  }
}

class CarReportScreen extends StatefulWidget {
  @override
  _CarReportScreenState createState() => _CarReportScreenState();
}

class _CarReportScreenState extends State<CarReportScreen> {
  TextEditingController _carNumberController = TextEditingController();
  String _reportText = "";
  Uint8List? _logoImage;
  Map<String, String> carData = {};

  Future<void> fetchReport() async {
    String carNumber = _carNumberController.text.trim();
    if (carNumber.isEmpty || int.tryParse(carNumber) == null) {
      _showError("يرجى إدخال رقم سيارة صالح.");
      return;
    }

    String url = "https://www.check-car.co.il/report/$carNumber/";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        _showError("فشل في جلب البيانات. تأكد من الرقم المدخل.");
        return;
      }

      var document = htmlParser.parse(response.body);
      Map<String, String> extractedData = {};

      var tables = document.getElementsByClassName("data_table");
      for (var table in tables) {
        var rows = table.getElementsByClassName("table_col");
        for (var row in rows) {
          var labelElement = row.querySelector(".label");
          var valueElement = row.querySelector(".value");

          if (labelElement != null && valueElement != null) {
            extractedData[labelElement.text.trim()] = valueElement.text.trim();
          }
        }
      }

      var titleElement = document.querySelector(".title .name");
      var updateDateElement = document.querySelector(".title .updated");

      if (titleElement != null) {
        extractedData["اسم السيارة"] = titleElement.text.trim();
      }
      if (updateDateElement != null) {
        extractedData["تاريخ التحديث"] = updateDateElement.text.trim();
      }

      var logoElement = document.querySelector("img");
      Uint8List? logoImage;
      if (logoElement != null && logoElement.attributes.containsKey("src")) {
        String logoUrl = logoElement.attributes["src"]!;
        logoImage = await _fetchImage(logoUrl);
      }

      setState(() {
        carData = extractedData;
        _logoImage = logoImage;
      });

    } catch (e) {
      _showError("حدث خطأ أثناء جلب البيانات: $e");
    }
  }

  Future<Uint8List?> _fetchImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint("خطأ في تحميل الصورة: $e");
    }
    return null;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("خطأ"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("موافق"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تقرير السيارة"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _carNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "أدخل رقم السيارة",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: fetchReport,
                ),
              ),
            ),
            SizedBox(height: 20),
            _logoImage != null
                ? Column(
                    children: [
                      Image.memory(_logoImage!, height: 100),
                      SizedBox(height: 10),
                    ],
                  )
                : SizedBox(),
            Expanded(
              child: carData.isNotEmpty
                  ? ListView.builder(
                      itemCount: carData.length,
                      itemBuilder: (context, index) {
                        String key = carData.keys.elementAt(index);
                        String value = carData[key]!;
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(
                              key,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              value,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(child: Text("أدخل رقم السيارة واضغط بحث")),
            ),
          ],
        ),
      ),
    );
  }
}
