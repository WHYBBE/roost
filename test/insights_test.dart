import 'package:flutter_test/flutter_test.dart';
import 'package:roost/pages/insights_page.dart';

void main() {
  group('countWords', () {
    test('中文逐字计数', () {
      expect(countWords('你好世界'), 4);
    });

    test('英文按词、数字整体计数', () {
      expect(countWords('hello world 123'), 3);
    });

    test('中英混排：英文词与中文各计一次', () {
      expect(countWords('今天 hello，world！'), 4);
    });

    test('空串与纯空白', () {
      expect(countWords(''), 0);
      expect(countWords('   \n\t'), 0);
    });

    test('标点不计入', () {
      expect(countWords('a, b. c!'), 3);
    });

    test('连续空格不重复计数', () {
      expect(countWords('foo    bar'), 2);
    });
  });
}
