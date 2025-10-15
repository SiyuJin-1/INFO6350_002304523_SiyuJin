import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(primarySwatch: Colors.grey),
      initialRoute: '/',
      routes: {
        '/': (context) => ButtonCalculator(),
        '/form': (context) => FormCalculator(),
      },
    );
  }
}

class ButtonCalculator extends StatefulWidget {
  @override
  _ButtonCalculatorState createState() => _ButtonCalculatorState();
}

class _ButtonCalculatorState extends State<ButtonCalculator> {
  String input = '';
  String result = '';

  void onPressed(String value) {
    setState(() {
      if (value == '=') {
        try {
          result = _evaluate(input);
        } catch (e) {
          result = 'Error';
        }
      } else if (value == 'C') {
        input = '';
        result = '';
      } else {
        input += value;
      }
    });
  }

  String _evaluate(String expr) {
    final operators = ['+', '-', '*', '/'];
    for (String op in operators) {
      if (expr.contains(op)) {
        final parts = expr.split(op);
        if (parts.length == 2) {
          double a = double.parse(parts[0]);
          double b = double.parse(parts[1]);
          switch (op) {
            case '+':
              return (a + b).toString();
            case '-':
              return (a - b).toString();
            case '*':
              return (a * b).toString();
            case '/':
              return b != 0 ? (a / b).toString() : 'NaN';
          }
        }
      }
    }
    return 'Invalid';
  }

  final buttons = [
    '7', '8', '9', '*',
    '4', '5', '6', '/',
    '1', '2', '3', '+',
    '=', '0', 'C', '-'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Button Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            onPressed: () => Navigator.pushNamed(context, '/form'),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.black,
            alignment: Alignment.centerRight,
            child: Text(input, style: TextStyle(fontSize: 30, color: Colors.white)),
          ),
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.black,
            alignment: Alignment.centerRight,
            child: Text(result, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: GridView.builder(
              itemCount: buttons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
              itemBuilder: (context, index) {
                String btn = buttons[index];
                bool isEqualBtn = btn == '=';

                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEqualBtn ? Colors.orange : Colors.white,
                      foregroundColor: isEqualBtn ? Colors.white : Colors.black,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    onPressed: () => onPressed(buttons[index]),
                    child: Text(buttons[index], style: TextStyle(fontSize: 28)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FormCalculator extends StatefulWidget {
  @override
  _FormCalculatorState createState() => _FormCalculatorState();
}

class _FormCalculatorState extends State<FormCalculator> {
  final _formKey = GlobalKey<FormState>();
  final _num1Controller = TextEditingController();
  final _num2Controller = TextEditingController();
  String result = '';

  void _calculate(String operator) {
    if (_formKey.currentState!.validate()) {
      final a = double.parse(_num1Controller.text);
      final b = double.parse(_num2Controller.text);
      double res = 0;

      switch (operator) {
        case '+':
          res = a + b;
          break;
        case '-':
          res = a - b;
          break;
        case '*':
          res = a * b;
          break;
        case '/':
          res = b != 0 ? a / b : double.nan;
          break;
      }

      setState(() {
        result = res.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            onPressed: () => Navigator.pushNamed(context, '/'),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _num1Controller,
                decoration: InputDecoration(labelText: 'Enter first number'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null
                    ? 'Enter valid number'
                    : null,
              ),
              TextFormField(
                controller: _num2Controller,
                decoration: InputDecoration(labelText: 'Enter second number'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null
                    ? 'Enter valid number'
                    : null,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['+', '-', '*', '/'].map((op) {
                  return ElevatedButton(
                    onPressed: () => _calculate(op),
                    child: Text(op, style: TextStyle(fontSize: 20)),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text('Result: $result', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      ),
    );
  }
}