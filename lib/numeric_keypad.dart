import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void NumPadCallback(String value);

class NumericKeypad extends StatefulWidget {
  final NumPadCallback onValueChange;
  final Function onConfirm;
  NumericKeypad({
    required this.onValueChange,
    required this.onConfirm,
  });

  @override
  _NumericKeypadState createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  String _inputValue = '';

  void _onButtonPress(String value) {
    if (_inputValue.length < 6) {
      setState(() {
        _inputValue = _inputValue + value;
      });
      widget.onValueChange(_inputValue);
    }
  }

  void _onDeletePress() {
    setState(() {
      _inputValue = _inputValue.isEmpty
          ? _inputValue
          : _inputValue.substring(0, _inputValue.length - 1);
    });
    widget.onValueChange(_inputValue);
  }

  void _onConfirmPress() {
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (index) => Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 2, color: Colors.black),
                  color: index < _inputValue.length
                      ? Colors.black
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 32),
        for (var i = 1; i <= 9; i += 3)
          _buildRow(
              context, i.toString(), (i + 1).toString(), (i + 2).toString()),
        _buildLastRow(context),
      ],
    );
  }

  Widget _buildRow(
      BuildContext context, String num1, String num2, String num3) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(context, num1),
        _buildButton(context, num2),
        _buildButton(context, num3),
      ],
    );
  }

  Widget _buildLastRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildIconButton(context, Icons.delete, _onDeletePress),
        _buildButton(context, '0'),
        _buildIconButton(context, Icons.check, _onConfirmPress),
      ],
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          _onButtonPress(text);
        },
        child: Text(
          text,
          style: Theme.of(context).textTheme.headline4,
        ),
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.all(16)),
          shape: MaterialStateProperty.all(CircleBorder()),
          elevation: MaterialStateProperty.all(5),
        ),
      ),
    );
  }

  Widget _buildIconButton(
      BuildContext context, IconData icon, void Function() onPressed) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 32,
        ),
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.all(16)),
          shape: MaterialStateProperty.all(CircleBorder()),
          elevation: MaterialStateProperty.all(5),
        ),
      ),
    );
  }
}
