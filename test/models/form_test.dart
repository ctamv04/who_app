import 'package:flutter_test/flutter_test.dart';
import 'package:who_app/models/form.dart' as form_model;
import 'package:who_app/models/page.dart' as page_model;

void main(){

  const testTitle = 'Test Form';
  const testDescription = 'Test Description';
  const testPageTitle = 'Test Page Title';
  const testPageKey = 0;
  const testPageNumber = 1;

  final testPage = page_model.Page(
    title: testPageTitle, 
    elements: {}
  );
  final testJson = {
    'title': testTitle,
    'description': testDescription,
    'pages': {testPageKey.toString(): testPage.toJson()},
  };

  late form_model.Form emptyForm;
  late form_model.Form testForm;

  setUp(() {
    emptyForm = form_model.Form(
      title: testTitle, 
      description: testDescription, 
      pages: {}
    );

    testForm = form_model.Form(
      title: testTitle, 
      description: testDescription, 
      pages: {
        testPageKey: testPage
      },
    );
  });


  test('Form can be initialized with title and description', () {
    expect(emptyForm.title, testTitle);
    expect(emptyForm.description, testDescription);
    expect(emptyForm.pages, isEmpty); 
    expect(emptyForm.pages, {}); 
  });

  test('Form.toJson() returns correct JSON structure', () {
    final json = testForm.toJson();
    
    expect(json['title'], testTitle);
    expect(json['description'], testDescription);
    expect(json['pages'], isNotEmpty);

    final pageJson = json['pages'][testPageKey.toString()];

    expect(pageJson['title'], testPageTitle);
    expect(pageJson['elements'], isEmpty);
  });

  test('Form.fromJson() creates a correct object from JSON', () {
    testForm = form_model.Form.fromJson(testJson);

    expect(testForm.title, testTitle);
    expect(testForm.description, testDescription);
    expect(testForm.pages, contains(testPageKey));
    expect(testForm.pages[testPageKey]!.title, testPageTitle);
    expect(testForm.pages[testPageKey]!.elements, isEmpty);
  });

  test('Title can be read and updated', () {
    const newTitle = "New Test Title";
    emptyForm.title = newTitle;

    expect(emptyForm.title, newTitle);
  });

  test('Description can be read and updated', () {
    const newDescription = "New Test Description";
    emptyForm.description = newDescription;

    expect(emptyForm.description, newDescription);
  });

  test('Form pages can be replaced', () {
    emptyForm.pages[testPageKey] = testPage;

    expect(emptyForm.pages, contains(testPageKey));
    expect(emptyForm.pages[testPageKey]!.title, testPageTitle);  
  });

  test('Form pages can be removed', () {
    emptyForm.pages.remove(testPageKey);

    expect(emptyForm.pages, isEmpty);  
  });
}