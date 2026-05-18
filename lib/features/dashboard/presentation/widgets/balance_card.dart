import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final bool isArabic;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = AppFormatters.formatAmount(balance);

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 180,
                  color: Colors.white.withAlpha(8),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 160,
                  color: Theme.of(context).colorScheme.primary.withAlpha(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_wallet_rounded,
                                  size: 14, color: Colors.white.withAlpha(179)),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'الرصيد المتوفر' : 'Available Balance',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(179),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatted,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            fontFamily: 'Outfit',
                            height: 1.0,
                          ),
                        ).animate().shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withAlpha(51),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SDG',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withAlpha(102),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 100,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withAlpha(51),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      curve: Curves.easeOutBack,
    );
  }
}
