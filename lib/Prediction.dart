import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PredictionScreen extends StatefulWidget {
  @override
  _MentalHealthPredictionPageState createState() =>
      _MentalHealthPredictionPageState();
}

class _MentalHealthPredictionPageState extends State<PredictionScreen> {
  String? selectedGender;
  String? selectedAge;
  String? selectedFamilyHistory;
  String? selectedBenefits;
  String? selectedCareOptions;
  String? selectedAnonymity;
  String? selectedLeave;
  String? selectedWorkInterfere;
  String predictionResult = '';
  bool isPredicting = false;

  List<String> genders = ['Female', 'Male', 'Trans'];
  List<String> ages =
      List<String>.generate(53, (index) => (18 + index).toString());
  List<String> familyHistoryOptions = ['Yes', 'No'];
  List<String> benefitsOptions = ['Yes', 'No', 'Don\'t know'];
  List<String> careOptions = ['Yes', 'No', 'Not sure'];
  List<String> anonymityOptions = ['Yes', 'No', 'Don\'t know'];
  List<String> leaveOptions = [
    'Don\'t know',
    'Somewhat difficult',
    'Somewhat easy',
    'Very difficult',
    'Very easy'
  ];
  List<String> workInterfereOptions = [
    'Don\'t know',
    'Never',
    'Often',
    'Rarely',
    'Sometimes'
  ];

  Future<void> predict() async {
    if (selectedGender == null ||
        selectedAge == null ||
        selectedFamilyHistory == null ||
        selectedBenefits == null ||
        selectedCareOptions == null ||
        selectedAnonymity == null ||
        selectedLeave == null ||
        selectedWorkInterfere == null) {
      // Show an error if any dropdown is not selected
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please select all fields.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isPredicting = true;
    });

    String url = 'http://54.90.153.100:5000/predict';
    Map<String, dynamic> requestData = {
      'data': [
        int.parse(selectedAge!),
        selectedGender!.toLowerCase(),
        selectedFamilyHistory!,
        selectedBenefits!,
        selectedCareOptions!,
        selectedAnonymity!,
        selectedLeave!,
        selectedWorkInterfere!
      ],
    };

    try {
      http.Response response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        String responseBody = response.body;

        // Directly use the response body as it is plain text
        setState(() {
          predictionResult = responseBody;
          isPredicting = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load prediction');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isPredicting = false;
      });

      // Show an error dialog with the error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to load prediction. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mental Health Predictor'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: genders.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Select Gender',
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedGender = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedAge,
                items: ages.map((String age) {
                  return DropdownMenuItem<String>(
                    value: age,
                    child: Text(age),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Select Age',
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedAge = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedFamilyHistory,
                items: familyHistoryOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Is there any family history of mental illness?',
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedFamilyHistory = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedBenefits,
                items: benefitsOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Does employer provides mental health benefits?',
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedBenefits = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCareOptions,
                items: careOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Are Care Options provided for mental health?',
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedCareOptions = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedAnonymity,
                items: anonymityOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Is your Anonymity Protected?',
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedAnonymity = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedLeave,
                items: leaveOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Ease of taking Medical Leave for mental health?',
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedLeave = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedWorkInterfere,
                items: workInterfereOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'If mental health conditions interfere with work?',
                ),
                onChanged: (newValue) {
                  setState(() {
                    selectedWorkInterfere = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isPredicting ? null : predict,
                child: isPredicting
                    ? CircularProgressIndicator()
                    : Text('Predict'),
              ),
              SizedBox(height: 20),
              Text(
                'Prediction Result: $predictionResult',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
