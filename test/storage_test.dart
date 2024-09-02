import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const TestData testString = TestData<String>('testString', 'hello');
  const TestData testBool = TestData<bool>('testBool', false);
  const TestData testInt = TestData<int>('testInt', 1234);
  const TestData testDouble = TestData<double>('testDouble', 1.432);

  late TestDataStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = TestDataStorage();
  });

  test('saveData', () async {
    expect(await storage.saveData(data: testString), true);
    expect(await storage.saveData(data: testBool), true);
    expect(await storage.saveData(data: testInt), true);
    expect(await storage.saveData(data: testDouble), true);
  });

  test('getData', () async {
    await storage.saveData(data: testString);
    await storage.saveData(data: testBool);
    await storage.saveData(data: testInt);
    await storage.saveData(data: testDouble);

    final TestData? actualString = await storage.getData(key: testString.key);
    expect(actualString, testString);
    final TestData? actualBool = await storage.getData(key: testBool.key);
    expect(actualBool, testBool);
    final TestData? actualInt = await storage.getData(key: testInt.key);
    expect(actualInt, testInt);
    final TestData? actualDouble = await storage.getData(key: testDouble.key);
    expect(actualDouble, testDouble);
  });

  test('getAllData', () async {
    await storage.saveData(data: testString);
    await storage.saveData(data: testBool);
    await storage.saveData(data: testInt);
    await storage.saveData(data: testDouble);

    final Map<String, Object> allData = await storage.getAllData();
    expect(allData, containsData(testString));
    expect(allData, containsData(testBool));
    expect(allData, containsData(testInt));
    expect(allData, containsData(testDouble));
  });

  test('removeData', () async {
    await storage.saveData(data: testString);
    await storage.saveData(data: testInt);

    await storage.removeData(key: testInt.key);
    final Map<String, Object> allData = await storage.getAllData();
    expect(allData.length, 1);
    expect(allData, containsData(testString));
    expect(allData, isNot(containsData(testInt)));
  });

  test('clearAllData', () async {
    await storage.saveData(data: testString);
    await storage.saveData(data: testDouble);

    await storage.clearAllData();
    final Map<String, Object> allData = await storage.getAllData();
    expect(allData, isEmpty);
  });

  test('If the key already exists, the value will be replaced.', () async {
    await storage.saveData(data: testString);

    // replace value
    final TestData newTestString = TestData(testString.key, 'bye');
    await storage.saveData(data: newTestString);

    final TestData? replacedData = await storage.getData(key: testString.key);
    expect(replacedData, newTestString);
  });
}

Matcher containsData(TestData data) {
  return containsPair(data.key, data.value);
}

class TestData<T> {
  const TestData(this.key, this.value);

  final String key;
  final T value;

  @override
  bool operator ==(Object other) =>
      other is TestData && key == other.key && value == other.value;

  @override
  int get hashCode => key.hashCode ^ value.hashCode;
}

class TestDataStorage {
  Future<bool> saveData({required TestData data}) {
    return FlutterForegroundTask.saveData(key: data.key, value: data.value);
  }

  Future<TestData<T>?> getData<T>({required String key}) async {
    final T? value = await FlutterForegroundTask.getData<T>(key: key);
    if (value == null) {
      return null;
    }
    return TestData<T>(key, value);
  }

  Future<Map<String, Object>> getAllData() {
    return FlutterForegroundTask.getAllData();
  }

  Future<bool> removeData({required String key}) {
    return FlutterForegroundTask.removeData(key: key);
  }

  Future<bool> clearAllData() {
    return FlutterForegroundTask.clearAllData();
  }
}
