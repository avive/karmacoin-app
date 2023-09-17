import '../../common_libs.dart';

/// Prepare the metadata by swapping the types that are not in the correct order
/// to allow polkadart package to work properly.
///
/// This is a temporarily solution that just works. Any changes on tha chain side
/// can lead to index offset so this should be updated accordingly.
class MetadataPreparer {
  static const List<(int, int)> _typesToSwap = [
    // (pallet_election_provider_multi_phase::Phase, utils tuple type)
    (56, 57),
  ];

  static prepareMetadata(Map<String, dynamic> metadata) {
    for (var (i, j) in _typesToSwap) {
      // Swap the types
      var temp = metadata['lookup']['types'][i];
      metadata['lookup']['types'][i] = metadata['lookup']['types'][j];
      metadata['lookup']['types'][j] = temp;

      // Swap the types in types that depends on this types
      for (var type in metadata['lookup']['types']) {
        MapEntry<String, dynamic>? def = type['def'];

        // Skip if the type doesn't have a def
        if (def == null) {
          continue;
        }

        switch (def.key) {
          case 'Composite':
            _swapComposite(def.value, i, j);
            break;
          case 'Variant':
            _swapVariant(def.value, i, j);
            break;
          case 'Sequence':
            _swapSequence(def.value, i, j);
            break;
          case 'Array':
            _swapArray(def.value, i, j);
            break;
          case 'Tuple':
            _swapTuple(def.value, i, j);
            break;
          case 'Compact':
            _swapCompact(def.value, i, j);
            break;
          case 'Primitive':
            _swapPrimitive(def.value, i, j);
            break;
          default:
            debugPrint('Unknown type: ${def.key}');
            break;
        }
      }
    }
  }

  static _swapComposite(Map<String, dynamic> composite, int i, int j) {
    for (var field in composite['fields']) {
      if (field['type'] == i) {
        field['type'] = j;
      } else if (field['type'] == j) {
        field['type'] = i;
      }
    }
  }

  static _swapVariant(Map<String, dynamic> variant, int i, int j) {
    for (var variant in variant['variants']) {
      // Tuple variant
      if (variant['type'] != null) {
          if (variant['type'] == i) {
            variant['type'] = j;
          } else if (variant['type'] == j) {
            variant['type'] = i;
          }
          continue;
      }

      // Composite variant
      for (var field in variant['fields']) {
        if (field['type'] == i) {
          field['type'] = j;
        } else if (field['type'] == j) {
          field['type'] = i;
        }
      }
    }
  }

  static _swapSequence(Map<String, dynamic> sequence, int i, int j) {
    if (sequence['type'] == i) {
      sequence['type'] = j;
    } else if (sequence['type'] == j) {
      sequence['type'] = i;
    }
  }

  static _swapArray(Map<String, dynamic> array, int i, int j) {
    if (array['type'] == i) {
      array['type'] = j;
    } else if (array['type'] == j) {
      array['type'] = i;
    }
  }

  static _swapTuple(Map<String, dynamic> tuple, int i, int j) {
    for (var type in tuple['types']) {
      if (type == i) {
        type = j;
      } else if (type == j) {
        type = i;
      }
    }
  }

  static _swapCompact(Map<String, dynamic> compact, int i, int j) {
    if (compact['type'] == i) {
      compact['type'] = j;
    } else if (compact['type'] == j) {
      compact['type'] = i;
    }
  }

  static _swapPrimitive(Map<String, dynamic> primitive, int i, int j) {
    // Do nothing
  }
}
