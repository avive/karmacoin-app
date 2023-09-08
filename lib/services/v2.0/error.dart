class ChainError {
  String name;
  String? description;

  ChainError(this.name, this.description);

  ChainError.fromSubstrateMetadata(Map<String, dynamic> errorMetadata)
      : name = errorMetadata['name'],
        description = errorMetadata['docs'][0];

  @override
  String toString() {
    return 'ChainError{name: $name, description: $description}';
  }
}
