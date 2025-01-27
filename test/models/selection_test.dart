import 'package:flutter_test/flutter_test.dart';
import 'package:who_app/models/selection.dart';

void main() {
    const testTitle = "Test Selection";
    const testSubTitle = "Test Subtitle";
    const testRequired = true;
    const testNumSelections = 3;
    const testOther = true;
    const testOtherText = "Other Option";
    final testSelections = {"Option 1": false, "Option 2": true, "other": false};

    test('Selection can be initialized correctly', () {
      final selectionElement = Selection(
        title: testTitle,
        subTitle: testSubTitle,
        required: testRequired,
        selections: testSelections,
        numSelections: testNumSelections,
        other: testOther,
        otherText: testOtherText,
      );

      expect(selectionElement.title, testTitle);
      expect(selectionElement.subTitle, testSubTitle);
      expect(selectionElement.required, testRequired);
      expect(selectionElement.numSelections, testNumSelections);
      expect(selectionElement.other, testOther);
      expect(selectionElement.otherText, testOtherText);
      expect(selectionElement.selections, testSelections);
    });

    test('Selection.fromJson() creates correct object', () {
      final json = {
        'title': testTitle,
        'subtitle': testSubTitle,
        'required': testRequired,
        'type': "selection",
        'num_selections': testNumSelections,
        'other': testOther,
        'selections': testSelections,
        'other_text': testOtherText,
      };

      final selectionElement = Selection.fromJson(json);

      expect(selectionElement.title, testTitle);
      expect(selectionElement.subTitle, testSubTitle);
      expect(selectionElement.required, testRequired);
      expect(selectionElement.numSelections, testNumSelections);
      expect(selectionElement.other, testOther);
      expect(selectionElement.otherText, testOtherText);
      expect(selectionElement.selections, testSelections);
    });

    test('Selection.toJson() returns correct JSON', () {
      final selectionElement = Selection(
        title: testTitle,
        subTitle: testSubTitle,
        required: testRequired,
        selections: testSelections,
        numSelections: testNumSelections,
        other: testOther,
        otherText: testOtherText,
      );

      final json = selectionElement.toJson();

      expect(json['title'], testTitle);
      expect(json['subtitle'], testSubTitle);
      expect(json['required'], testRequired);
      expect(json['type'], "selection");
      expect(json['num_selections'], testNumSelections);
      expect(json['other'], testOther);
      expect(json['other_text'], testOtherText);
      expect(json['selections'], testSelections);
    });
}