import 'package:flutter_test/flutter_test.dart';
import 'package:who_app/models/page.dart' as page_model;
import 'package:who_app/models/text.dart' as text_model;

void main(){
  const testTitle = 'Test Page Title';
  const testDescription = 'Test Description';

  final testFormElement = text_model.Text(title: 'Element Title', subTitle: "Element Subtitle", required: false, text: "Test Text");
  const testElementKey = 0;
  final testElements = { testElementKey : testFormElement };  

  late page_model.Page testPage;
  late page_model.Page emptyPage;

  final testJson = {
    'title': testTitle,
    'description': testDescription,
    'elements': { testElementKey.toString() : {
      'title': 'Element Title',
      'subtitle': 'Element Subtitle',
      'required': false,
      'type': 'text',
      'text': 'Test Text',
    }, },  
  };

  setUp(() {
    testPage = page_model.Page(
      title: testTitle,
      description: testDescription,
      elements: testElements,
    );

    emptyPage = page_model.Page(
      title: testTitle,
      description: testDescription,
      elements: {},
    );
  });


  test('Page can be initialized with title and description', () {
    expect(emptyPage.title, testTitle);
    expect(emptyPage.description, testDescription);
    expect(emptyPage.elements, isEmpty); 
    expect(emptyPage.elements, {}); 
  });

  test('Page.toJson() returns correct JSON structure', () {
    final json = testPage.toJson();
    
    expect(json['title'], testTitle);
    expect(json['description'], testDescription);
    expect(json['elements'], isNotEmpty);
    expect(json['elements'][testElementKey.toString()], testFormElement.toJson());
  });

  test('Page.fromJson() creates a correct object from JSON', () {
    testPage = page_model.Page.fromJson(testJson);

    expect(testPage.title, testTitle);
    expect(testPage.description, testDescription);
    
    expect(testPage.elements, isNotEmpty);
    expect(testPage.elements, contains(testElementKey));

    final element = testPage.elements?[testElementKey];
    expect(element, isNotNull);
    expect(element?.title, testFormElement.title);
    expect(element?.subTitle, testFormElement.subTitle);
  });

  test('Title can be read and updated', () {
    const newTitle = "New Test Title";
    emptyPage.title = newTitle;

    expect(emptyPage.title, newTitle);
  });

  test('Description can be read and updated', () {
    const newDescription = "New Description";
    emptyPage.description = newDescription;

    expect(emptyPage.description, newDescription);
  });

  
  test('Page elements can be replaced', () {
    emptyPage.elements = testElements;

    expect(emptyPage.elements, contains(testElementKey));
    expect(emptyPage.elements?[testElementKey]?.title, testFormElement.title);
    expect(emptyPage.elements?[testElementKey]?.subTitle, testFormElement.subTitle);
    expect(emptyPage.elements?[testElementKey]?.required, testFormElement.required);
    expect((emptyPage.elements?[testElementKey] as text_model.Text).text, testFormElement.text);
    
  });

  test('Page elements can be removed', () {
    emptyPage.elements?.remove(testElementKey);

    expect(emptyPage.elements, isEmpty);  
  });

}