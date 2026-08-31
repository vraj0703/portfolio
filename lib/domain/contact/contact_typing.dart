/// How the contact menu types itself on.
///
/// The affordance it stands in for — "TAP TO ENTER" — does not fade in, it
/// types: the label appears a character at a time once the layer is part way
/// through its entrance. The menu is the same gesture on a row of
/// destinations rather than on one phrase, and reading the two as the same
/// animation is the point. A row that fades in as a block, however well
/// timed, is a different thing happening in the same span.
///
/// Pure, so the order and the timing can be checked without a renderer — and
/// so the rule that decides *when* typing starts lives in one place for both,
/// as `LogoConfig.typedAt`.
abstract final class ContactTyping {
  /// What a mark costs, in characters.
  ///
  /// One. A glyph cannot arrive half-drawn, so it takes a single beat of the
  /// row's typing and fades within it — the alternative is a mark that
  /// appears instantly while the words beside it are still arriving, which
  /// reads as the mark being separate from the menu.
  static const int markWeight = 1;

  /// What the punctuation between two entries costs.
  static const int separatorWeight = 1;

  /// How far the entry at [index] has arrived, `0`..`1`.
  ///
  /// [weights] is what each entry costs in characters, in the order they are
  /// read. [typed] is the row's progress as a whole, so a long word takes
  /// proportionally longer than a short one and the row types at an even
  /// pace rather than an even beat per item.
  static double revealOf({
    required int index,
    required double typed,
    required List<int> weights,
  }) {
    if (index < 0 || index >= weights.length) return 0;

    final total = totalWeight(weights);
    if (total <= 0) return 1;

    // Where this entry starts and ends along the row, in characters.
    var before = 0;
    for (var i = 0; i < index; i++) {
      before += weights[i] + separatorWeight;
    }

    final reached = typed.clamp(0.0, 1.0) * total;
    final into = reached - before;
    if (into <= 0) return 0;

    return (into / weights[index]).clamp(0.0, 1.0);
  }

  /// The whole row's length, separators included.
  static int totalWeight(List<int> weights) {
    if (weights.isEmpty) return 0;
    final letters = weights.fold<int>(0, (sum, w) => sum + w);
    return letters + separatorWeight * (weights.length - 1);
  }

  /// How far the punctuation *after* the entry at [index] has arrived.
  ///
  /// It waits for what it separates. A dot that arrives before the word on
  /// its left reads as a bullet with nothing to point at.
  static double separatorAfter({
    required int index,
    required double typed,
    required List<int> weights,
  }) => revealOf(index: index, typed: typed, weights: weights) >= 1 ? 1 : 0;
}
