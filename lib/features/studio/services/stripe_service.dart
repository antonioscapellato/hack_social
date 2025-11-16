import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Stripe Service for handling payment integration
class StripeService {
  static const String _secretKey = 'sk_test_51RZeQY4Yio8KAoezPojBvZIDv7IswRANa1p0uTYCoSI2xkmbnYag0mdkequvWKQfHy1oxwJYglI4Tf47FVQ264Vo00PNtsv3yh';
  static const String _publishableKey = 'pk_test_51RZeQY4Yio8KAoezFRVV5LxeqRl6tnuqlsABOrZQs0KcbeuAXxJvTtviONtQGyncworNlrhZ1t0bLof8rvfbHVES00ZkUJ8qXN';
  
  static bool _initialized = false;

  // Initialize Stripe with publishable key
  static Future<void> initialize() async {
    if (_initialized) return;
    
    Stripe.publishableKey = _publishableKey;
    Stripe.merchantIdentifier = 'merchant.com.hacksocial';
    
    await Stripe.instance.applySettings();
    _initialized = true;
  }

  // Create payment intent directly from client (for sandbox/testing only)
  // In production, this should be done on your backend server
  static Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
  }) async {
    try {
      // Convert amount to cents (Stripe uses smallest currency unit)
      final amountInCents = (amount * 100).toInt();
      
      // Create payment intent via Stripe API
      final body = {
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        'automatic_payment_methods[enabled]': 'true',
      };
      
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'clientSecret': data['client_secret'],
          'paymentIntentId': data['id'],
          'amount': amount,
          'currency': currency,
        };
      } else {
        print('Error creating payment intent: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception creating payment intent: $e');
      return null;
    }
  }

  // Present payment sheet
  static Future<bool> presentPaymentSheet({
    required String clientSecret,
  }) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Hack Social',
          style: ThemeMode.dark,
        ),
      );

      // Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment was successful
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User canceled the payment
        return false;
      } else {
        // Payment failed
        print('Payment failed: ${e.error.message}');
        return false;
      }
    } catch (e) {
      print('Exception presenting payment sheet: $e');
      return false;
    }
  }
}
