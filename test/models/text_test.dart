import 'package:flutter_test/flutter_test.dart';
import 'package:who_app/models/text.dart';

void main() {
    const testTitle = "Test Title";
    const testSubTitle = "Test Subtitle";
    const testText = "This is a test text.";
    const testRequired = true;

    test('Text can be initialized correctly', () {
      final textElement = Text(
        title: testTitle,
        subTitle: testSubTitle,
        required: testRequired,
        text: testText,
      );

      expect(textElement.title, testTitle);
      expect(textElement.subTitle, testSubTitle);
      expect(textElement.required, testRequired);
      expect(textElement.text, testText);
    });

    test('Text.fromJson() creates correct object', () {
      final json = {
        'title': testTitle,
        'subtitle': testSubTitle,
        'required': testRequired,
        'type': "text",
        'text': testText,
      };

      final textElement = Text.fromJson(json);

      expect(textElement.title, testTitle);
      expect(textElement.subTitle, testSubTitle);
      expect(textElement.required, testRequired);
      expect(textElement.text, testText);
    });

    test('Text.toJson() returns correct JSON', () {
      final textElement = Text(
        title: testTitle,
        subTitle: testSubTitle,
        required: testRequired,
        text: testText,
      );

      final json = textElement.toJson();

      expect(json['title'], testTitle);
      expect(json['subtitle'], testSubTitle);
      expect(json['required'], testRequired);
      expect(json['type'], "text");
      expect(json['text'], testText);
    });
}