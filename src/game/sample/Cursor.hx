package sample;

import hxd.impl.MouseMode;
import format.swf.Data.ButtonRecord;
import sample.SamplePlayer.boost as boost;

import hxd.App;
import h2d.Bitmap;
import h2d.Tile;
import hxd.System;
import h2d.Interactive;
import h2d.Scene;

class Cursor extends App {
  var crosshair: Bitmap;

  override function init() {
      // Create the crosshair
      var crosshairTile = h2d.Tile.fromColor(0xFF0000, 10, 10); // A red square crosshair
      crosshair = new h2d.Bitmap(crosshairTile, s2d);
      crosshair.tile.setCenterRatio(0.5, 0.5); // Center the crosshair
  }

  override function update(dt: Float) {
      super.update(dt);
      crosshair.x = mousePos.x; // Update crosshair X position
      crosshair.y = mousePos.y; // Update crosshair Y position
  }
}
