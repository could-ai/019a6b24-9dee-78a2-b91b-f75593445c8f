import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stealth_provider.dart';

class StealthModeScreen extends StatelessWidget {
  const StealthModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stealth Mode'),
      ),
      body: Consumer<StealthProvider>(
        builder: (context, stealthProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stealth mode explanation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.2),
                      const Color(0xFF00D9FF).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 48,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Disguise Your App',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When enabled, Whispr will appear as a different app to protect your privacy. The app name and icon will change to your selected disguise.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stealth mode toggle
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Enable Stealth Mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    stealthProvider.isStealthMode
                        ? 'App is currently disguised'
                        : 'App shows as Whispr',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  value: stealthProvider.isStealthMode,
                  activeColor: const Color(0xFF6C63FF),
                  onChanged: (value) async {
                    await stealthProvider.toggleStealthMode();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Stealth mode enabled - App disguised as ${stealthProvider.disguiseName}'
                                : 'Stealth mode disabled - App shows as Whispr',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stealthProvider.isStealthMode
                          ? const Color(0xFF6C63FF).withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      stealthProvider.isStealthMode
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: stealthProvider.isStealthMode
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Disguise options header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Choose Disguise',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              
              // Disguise options grid
              ...stealthProvider.getDisguiseOptions().map((option) {
                final isSelected = stealthProvider.disguiseName == option.name;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected
                      ? const Color(0xFF6C63FF).withOpacity(0.2)
                      : const Color(0xFF1A1A2E),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForDisguise(option.icon),
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                      ),
                    ),
                    title: Text(
                      option.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF6C63FF),
                          )
                        : null,
                    onTap: () async {
                      await stealthProvider.setDisguise(option.name, option.icon);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Disguise changed to ${option.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 24),
              
              // Warning note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Note: The app name change will be visible in the app switcher. For full stealth, close and reopen the app.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  IconData _getIconForDisguise(String icon) {
    switch (icon) {
      case 'calculator':
        return Icons.calculate;
      case 'notes':
        return Icons.note;
      case 'weather':
        return Icons.wb_sunny;
      case 'clock':
        return Icons.access_time;
      case 'compass':
        return Icons.explore;
      case 'flashlight':
        return Icons.flashlight_on;
      default:
        return Icons.apps;
    }
  }
}