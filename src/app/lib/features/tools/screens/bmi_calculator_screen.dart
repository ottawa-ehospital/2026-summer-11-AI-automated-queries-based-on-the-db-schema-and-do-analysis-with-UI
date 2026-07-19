import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../presentation/bmi_styles.dart';
import '../widgets/bmi_input_card.dart';
import '../widgets/bmi_reference_card.dart';
import '../widgets/bmi_result_card.dart';

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  double? _bmi;
  String? _category;
  Color? _categoryColor;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final l10n = context.l10n;
    final h = double.tryParse(_heightCtrl.text.trim());
    final w = double.tryParse(_weightCtrl.text.trim());
    if (h == null || w == null || h <= 0 || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validHeightWeightError)),
      );
      return;
    }
    final hm = h / 100;
    final bmi = w / (hm * hm);
    final (category, color) = _classifyBmi(l10n, bmi);
    setState(() {
      _bmi = bmi;
      _category = category;
      _categoryColor = color;
    });
  }

  (String, Color) _classifyBmi(AppLocalizations l10n, double bmi) {
    if (bmi < 18.5) return (l10n.bmiUnderweight, Colors.blue);
    if (bmi < 25) return (l10n.bmiNormal, Colors.green);
    if (bmi < 30) return (l10n.bmiOverweight, Colors.orange);
    return (l10n.bmiObese, Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(title: l10n.bmiCalculatorTitle, icon: Icons.monitor_weight_outlined),
          SliverToBoxAdapter(
            child: Padding(
              padding: BmiStyles.bodyPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BmiInputCard(
                    heightController: _heightCtrl,
                    weightController: _weightCtrl,
                    onCalculate: _calculate,
                  ),
                  if (_bmi != null && _category != null && _categoryColor != null) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    BmiResultCard(
                      bmi: _bmi!,
                      category: _category!,
                      categoryColor: _categoryColor!,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  const BmiReferenceCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
