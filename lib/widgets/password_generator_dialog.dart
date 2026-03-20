import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/generator_service.dart';
import '../utils/constants.dart';

/// Dialog for generating random passwords
class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  int _length = AppConstants.defaultPasswordLength;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _digits = true;
  bool _symbols = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final generator = context.read<GeneratorService>();
    setState(() {
      _generatedPassword = generator.generate(
        length: _length,
        uppercase: _uppercase,
        lowercase: _lowercase,
        digits: _digits,
        symbols: _symbols,
      );
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAtLeastOneOption = _uppercase || _lowercase || _digits || _symbols;

    return AlertDialog(
      title: const Text('Generate Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generated password display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _generatedPassword.isEmpty ? 'Select options' : _generatedPassword,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _generatedPassword.isEmpty ? null : _copyToClipboard,
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: hasAtLeastOneOption ? _generate : null,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Length slider
            Text(
              'Length: $_length',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _length.toDouble(),
              min: AppConstants.minPasswordLength.toDouble(),
              max: AppConstants.maxPasswordLength.toDouble(),
              divisions: AppConstants.maxPasswordLength - AppConstants.minPasswordLength,
              label: _length.toString(),
              onChanged: (value) {
                setState(() {
                  _length = value.toInt();
                });
                _generate();
              },
            ),
            const SizedBox(height: 16),

            // Character options
            CheckboxListTile(
              title: const Text('Uppercase (A-Z)'),
              value: _uppercase,
              onChanged: (value) {
                setState(() {
                  _uppercase = value ?? false;
                });
                _generate();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Lowercase (a-z)'),
              value: _lowercase,
              onChanged: (value) {
                setState(() {
                  _lowercase = value ?? false;
                });
                _generate();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Digits (0-9)'),
              value: _digits,
              onChanged: (value) {
                setState(() {
                  _digits = value ?? false;
                });
                _generate();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Symbols (!@#\$...)'),
              value: _symbols,
              onChanged: (value) {
                setState(() {
                  _symbols = value ?? false;
                });
                _generate();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),

            if (!hasAtLeastOneOption)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Select at least one character type',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _generatedPassword.isEmpty
              ? null
              : () => Navigator.of(context).pop(_generatedPassword),
          child: const Text('Use Password'),
        ),
      ],
    );
  }
}
