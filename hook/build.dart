import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
// flutter_scene:init:start
    // Import .glb scenes under assets/ as DataAssets, loadable by source path
    // with loadScene (and hot-reloadable). A no-op when there are no scenes.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      // generatedTree, not dataAssetsRequired: data assets are a master-channel
      // feature, and this project ships from stable. Same output either way —
      // it lands in flutter_scene_generated/ instead of the asset bundle.
      assetMode: SceneAssetMode.generatedTree,
    );
    // Compile .fmat materials under assets/ as DataAssets, loadable by source
    // path with loadFmatMaterial (and hot-reloadable). A no-op when there are
    // no materials.
    await buildMaterials(
      buildInput: input,
      buildOutput: output,
      assetMode: MaterialAssetMode.generatedTree,
    );
// flutter_scene:init:end
  });
}
