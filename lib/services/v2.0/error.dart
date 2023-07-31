class ChainError {
  String name;
  String description;

  ChainError.fromSubstrateMetadata(Map<String, dynamic> errorMetadata)
      : name = errorMetadata['name'],
        description = errorMetadata['docs'][0];
}
