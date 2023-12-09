sealed class Constants {
  static const botID = '936929561302675456';

  /// In string /imagine "hello world" --seed 232323, this matches 232323
  static final seedRegex = RegExp(r'--seed (\d+)');
}
