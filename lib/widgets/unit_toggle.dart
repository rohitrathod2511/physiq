
import 'package:flutter/material.dart';

class UnitToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String leftLabel;
  final String rightLabel;

  const UnitToggle({
    Key? key,
    required this.value,
    required this.onChanged,
    this.leftLabel = 'Metric',
    this.rightLabel = 'Imperial',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLeft = value == leftLabel;
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4, // Approx half width minus padding
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(leftLabel),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      leftLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: isLeft ? Colors.black : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(rightLabel),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      rightLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: !isLeft ? Colors.black : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
