package ludi.heaps.sprite;

import h2d.Tile;

class Icons extends Spritesheet<Int> {

    var frames: Array<Tile>;
    var hasCut: Bool;

    public function new(sheet:Tile, frameSize:Int) {
        super();
        frames = cut(sheet, { w:frameSize, h:frameSize });
        hasCut = true;
    }

    public function get(arg: Int): Object {
        return new h2d.Bitmap(getTileAtIndex(arg));
    }

    public function getTileAtIndex(index: Int): Tile {
        return frames[index];
    }
}
