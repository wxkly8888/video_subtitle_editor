String fileName(String str) {
  if (str.endsWith('/')) str = str.substring(0, str.length - 1);
  return str.split('/').last;
}

String fileExtension(String str) {
  if (str.endsWith('/')) str = str.substring(0, str.length - 1);
  return '.' + fileName(str).split('.').last;
}
