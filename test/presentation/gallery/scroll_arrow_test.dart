import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/scroll_arrow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a model that cannot be read leaves the room without a cue', () async {
    // Null, not a throw. The gallery is the last thing the visitor reaches,
    // and a missing hint is a room without a hint — while a missing hint that
    // throws is no room at all.
    expect(await ScrollArrow.load(asset: 'assets/objects/nothing.glb'), isNull);
  });

  test('parenting a model needs add, not children.add', () {
    // Executable note on a trap that cost two rounds of "it is still huge and
    // still pointing the wrong way". `children` is a public list and
    // appending to it puts the model in the tree, so it renders — but the
    // child's parent is never set, its world transform never composes with
    // the parent's, and every rotation and scale set on the parent is
    // silently discarded.
    final viaAdd = Node()..add(Node());
    expect(viaAdd.children.single.parent, viaAdd);

    final viaList = Node();
    viaList.children.add(Node());
    expect(
      viaList.children.single.parent,
      isNull,
      reason: 'if this ever starts passing, the trap is gone',
    );
  });

  test('the cue retires as soon as the corridor starts moving', () {
    // A cue that follows the visitor down the corridor repeating itself has
    // stopped being a cue.
    expect(ScrollArrow.fadesBy, greaterThan(0));
    expect(
      ScrollArrow.fadesBy,
      lessThan(0.1),
      reason: 'holding it past the first stride reads as part of the room',
    );
  });

  test('it lies ahead of where the visitor starts', () {
    // Behind the camera it is invisible; at the camera it is underfoot.
    expect(ScrollArrow.distanceIn, lessThan(0));
  });

  test('it is turned a quarter, and only turned', () {
    // The export already applies its own Z-up to Y-up conversion, so the
    // arrow arrives lying flat and pointing across the corridor. Adding a
    // tilt of our own stood it back up on edge.
    expect(ScrollArrow.facing.abs(), closeTo(3.141592653589793 / 2, 1e-9));
  });

  test('it is sized like a floor marking, not a monument', () {
    // The model is three units long as authored, in a corridor eight across.
    expect(ScrollArrow.scale * 3, lessThan(1.5));
  });
}
