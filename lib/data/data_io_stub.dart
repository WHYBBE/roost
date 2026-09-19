/// Web 平台暂不支持文件导入导出与文件级清理
Future<String?> pickAndReadJson() async => null;

Future<bool> saveJsonToFile(String content) async => false;

Future<bool> deleteDataFiles(String dbName) async => false;
