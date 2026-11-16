import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/presentation/gallery/map_prefetch.dart';
import 'package:portfolio/presentation/gallery/texture_sets.dart';

/// A fake network: every fetch waits until the test releases it.
class Network {
  final Map<String, Completer<ByteData>> open = <String, Completer<ByteData>>{};
  final List<String> requested = <String>[];
  int inFlight = 0;
  int peak = 0;

  Future<ByteData> fetch(String asset) {
    requested.add(asset);
    inFlight++;
    if (inFlight > peak) peak = inFlight;
    final c = Completer<ByteData>();
    open[asset] = c;
    return c.future.whenComplete(() => inFlight--);
  }

  void finish(String asset, [int byte = 1]) =>
      open.remove(asset)!.complete(ByteData(1)..setUint8(0, byte));
}

void main() {
  // PORTFOLIO-8 (c): the 31 texture files used to download one at a time,
  // each only when its decode asked for it.
  test('fetches ahead, in order, never more than [parallel] at once', () async {
    final net = Network();
    final prefetch = MapPrefetch(parallel: 2, fetch: net.fetch);
    prefetch.start(<String>['a', 'b', 'c', 'd']);
    expect(net.requested, <String>['a', 'b'], reason: 'the first two start at once');

    net.finish('b');
    await pumpEventQueue();
    expect(net.requested, <String>['a', 'b', 'c'], reason: 'a free slot takes the next');

    net.finish('a');
    net.finish('c');
    await pumpEventQueue();
    net.finish('d');
    await pumpEventQueue();
    expect(net.peak, 2);
    for (final asset in <String>['a', 'b', 'c', 'd']) {
      expect((await prefetch.load(asset)).lengthInBytes, 1);
    }
    expect(prefetch.outstanding, 0, reason: 'nothing is kept once handed over');
  });

  test('a file listed twice is fetched once and handed over twice', () async {
    final net = Network();
    final prefetch = MapPrefetch(fetch: net.fetch);
    prefetch.start(<String>['wall', 'floor', 'wall']);
    expect(net.requested, <String>['wall', 'floor']);
    net.finish('wall', 7);
    net.finish('floor');

    expect((await prefetch.load('wall')).getUint8(0), 7);
    expect(prefetch.outstanding, 2, reason: 'wall is still owed once');
    expect((await prefetch.load('wall')).getUint8(0), 7);
    await prefetch.load('floor');
    expect(prefetch.outstanding, 0);
    expect(net.requested, <String>['wall', 'floor'], reason: 'no second download');
  });

  test('a file nobody named is fetched when asked for', () async {
    final net = Network();
    final prefetch = MapPrefetch(fetch: net.fetch);
    final bytes = prefetch.load('late');
    expect(net.requested, <String>['late']);
    net.finish('late');
    expect((await bytes).lengthInBytes, 1);
  });

  test('a failed download fails only its own load, and frees its slot', () async {
    final net = Network();
    final prefetch = MapPrefetch(parallel: 1, fetch: net.fetch);
    prefetch.start(<String>['missing', 'next']);
    final missing = prefetch.load('missing');
    net.open.remove('missing')!.completeError(StateError('404'));
    await expectLater(missing, throwsStateError);
    await pumpEventQueue();
    expect(net.requested, <String>['missing', 'next']);
    net.finish('next');
    expect((await prefetch.load('next')).lengthInBytes, 1);
  });

  test('the build names every file it reads, in the order it reads them', () {
    // Prefetching a list that misses a file only costs that file its head
    // start; prefetching one the build never reads is a download for
    // nothing. Every set the room and the keyboard load is in the list.
    final named = GalleryPrefetch.files.toSet();
    for (final set in <TextureSet>[
      GallerySurfaces.floor,
      GallerySurfaces.ceiling,
      GallerySurfaces.wall,
      GallerySurfaces.frame,
      GallerySurfaces.testimonialFrame,
      GallerySurfaces.keyboardBase,
      ...GallerySurfaces.keyRows,
    ]) {
      for (final file in set.files) {
        expect(named, contains(file));
      }
    }
    expect(GalleryPrefetch.files.first, GallerySurfaces.floor.colour);
    expect(GalleryPrefetch.files.last, GallerySurfaces.keyRows.last.normal);
  });
}
