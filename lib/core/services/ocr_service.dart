import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

final String modelType = 'gemini-3.5-flash';

class ParsedItem {
  final String name;
  final double price;

  ParsedItem({required this.name, required this.price});
}

class ParsedReceipt {
  final List<ParsedItem> items;
  final double taxPercentage;
  final double serviceChargePercentage;
  final double discountPercentage;
  final double discountAmount;

  ParsedReceipt({
    required this.items,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.discountPercentage,
    required this.discountAmount,
  });
}

class OcrService {
  // Extracting raw text from receipt
  static Future<ParsedReceipt> processReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      // Extract raw text using ML Kit
      final recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      if (rawText.trim().isEmpty) {
        return ParsedReceipt(
          items: [],
          taxPercentage: 0.0,
          serviceChargePercentage: 0.0,
          discountPercentage: 0.0,
          discountAmount: 0.0,
        );
      }

      // Setup Gemini AI
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null ||
          apiKey.isEmpty ||
          apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        throw Exception('GEMINI_API_KEY not found in .env file');
      }

      final model = GenerativeModel(
        model: modelType,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      // Prompt Gemini to parse the receipt
      final prompt =
          '''
You are an expert receipt parser specializing in Malaysian restaurant receipts (mix of English, Chinese, Malay, Tamil).

Extract all purchased items and their prices from the receipt text below.

Rules:
1. QUANTITY: If a line shows "2 x 2.50/ea", the unit price is 2.50, NOT the total 5.00
2. MULTI-LINE ITEMS: Some items span multiple lines — combine them into one entry using the base item name
3. IGNORE these lines completely:
   - Subtotal, Total, Net Total, Balance
   - Tax lines (SST, GST, Service Tax)
   - Rounding Adjustment
   - Modifier notes (e.g. "NO SHALLOTS", "Less Sugar", "Hot", "Cold")
   - Cash, Change, Visa, Mastercard, Credit Card
4. TAX: Extract SST or GST percentage as taxPercentage (e.g. 6 for 6%)
5. SERVICE CHARGE: Extract service charge percentage as serviceChargePercentage (e.g. 10 for 10%)
7. ITEM NAMES: Use the English name if other language are present, if there is no English name, use Unknown Item. Fix obvious OCR typos.
8. PRICES: Always positive floats in MYR
9. Extract the discount amount or percentage if any (e.g. "Discount 5%", "Discount 5.00", etc)

Respond ONLY with valid JSON. No explanation, no markdown, no backticks.
Schema:
{
  "items": [
    {
      "name": "string",
      "price": 0.0
    }
  ],
  "taxPercentage": 0.0,
  "serviceChargePercentage": 0.0
  "discountPercentage": 0.0,
  "discountAmount": 0.0
}

Receipt Text:
$rawText
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final jsonString = response.text;

      if (jsonString == null || jsonString.isEmpty) {
        throw Exception('Failed to generate JSON from Gemini');
      }

      // Parse the JSON response
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final items = <ParsedItem>[];
      if (data['items'] != null) {
        for (final item in data['items']) {
          items.add(
            ParsedItem(
              name: item['name'] ?? 'Unknown Item',
              price: (item['price'] ?? 0.0).toDouble(),
            ),
          );
        }
      }

      final taxPercentage = (data['taxPercentage'] ?? 0.0).toDouble();
      final serviceChargePercentage = (data['serviceChargePercentage'] ?? 0.0)
          .toDouble();
      final discountPercentage = (data['discountPercentage'] ?? 0.0).toDouble();
      final discountAmount = (data['discountAmount'] ?? 0.0).toDouble();

      return ParsedReceipt(
        items: items,
        taxPercentage: taxPercentage,
        serviceChargePercentage: serviceChargePercentage,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
      );
    } catch (e) {
      debugPrint('Error processing receipt: $e');
      rethrow; // Handle display error
    } finally {
      await textRecognizer.close();
    }
  }

  // Assigning items to members based on natural language input
  static Future<Map<int, List<String>>> assignItemsWithAI(
    String userInput,
    List<ParsedItem> items,
    List<UserModel> members,
  ) async {
    if (userInput.trim().isEmpty || items.isEmpty || members.isEmpty) {
      return {};
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    final model = GenerativeModel(
      model: modelType,
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final itemsText = items
        .asMap()
        .entries
        .map((e) => '${e.key}: ${e.value.name}')
        .join('\n');
    final membersText = members
        .map((m) => 'ID: ${m.id} | Name: ${m.name}')
        .join('\n');

    final prompt =
        '''
You are an AI assistant that maps receipt items to members based on natural language input.

Items:
$itemsText

Members:
$membersText

User Input: "$userInput"

Determine which member(s) consumed each item. Return a JSON object mapping the item's index (as a string) to an array of EXACT member IDs (the part after "ID:").
If an item is not mentioned in the user input, do NOT include it in the JSON.
If multiple members shared an item, include all their IDs.

Respond ONLY with valid JSON matching this schema:
{
  "item_index_string": ["member_id_string", ...]
}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonString = response.text;

      debugPrint('Gemini Assignment JSON: $jsonString');

      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }

      String cleanJson = jsonString;
      if (cleanJson.contains('```json')) {
        cleanJson = cleanJson.split('```json')[1].split('```')[0].trim();
      } else if (cleanJson.contains('```')) {
        cleanJson = cleanJson.split('```')[1].split('```')[0].trim();
      }

      final Map<String, dynamic> data = jsonDecode(cleanJson);
      final Map<int, List<String>> result = {};

      data.forEach((key, value) {
        final index = int.tryParse(key);
        if (index != null) {
          if (value is List) {
            result[index] = value.map((e) => e.toString()).toList();
          } else if (value is String) {
            result[index] = [value];
          }
        }
      });

      debugPrint('Parsed Assignment Map: $result');
      return result;
    } catch (e) {
      debugPrint('Error assigning items with AI: $e');
      return {};
    }
  }
}
