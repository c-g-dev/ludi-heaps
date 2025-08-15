package ludi.heaps.sprite;

import h2d.Object;
import h2d.Tile;

/**
 * Generic spritesheet helper that slices a source `h2d.Tile` into a grid of frame tiles.
 *
 * Extend this class and implement `get(arg:T)` to map your identifier to a rendered `h2d.Object`.
 *
 * Example:
 *
 * enum MyIcons { Icon1; Icon2; }
 * class Icons extends Spritesheet<MyIcons> {
 *     override public function get(iconId:MyIcons):Object {
 *         // Example usage: lazily slice with desired dimensions
 *         // var frames = cut(sheet, { w:16, h:16 });
 *         // return new h2d.Bitmap(frames[Type.enumIndex(iconId)]);
 *         return null; // implement in subclass
 *     }
 * }
 */
abstract class Spritesheet<T> {

	public function new() {}

    /** Implement in subclasses to return a rendered object for an id of type T. */
    public abstract function get(arg: T): Object;

	/**
	 * Slice a spritesheet into tiles using the provided dimensions and layout parameters.
	 * No state is stored; callers can request different sizes per call if needed.
	 */
	public function cut(sheet: Tile, tileSize: { w:Int, h:Int }, ?spacing: { x:Int, y:Int }, ?margin: { x:Int, y:Int }): Array<Tile> {
		var result: Array<Tile> = [];
		var sheetW = Std.int(sheet.width);
		var sheetH = Std.int(sheet.height);
		var tw = tileSize.w;
		var th = tileSize.h;
		var spx = spacing == null ? 0 : spacing.x;
		var spy = spacing == null ? 0 : spacing.y;
		var mgx = margin == null ? 0 : margin.x;
		var mgy = margin == null ? 0 : margin.y;
		var stepX = tw + spx;
		var stepY = th + spy;

		var y = mgy;
		while (y + th <= sheetH) {
			var x = mgx;
			while (x + tw <= sheetW) {
				result.push(sheet.sub(x, y, tw, th));
				x += stepX;
			}
			y += stepY;
		}
		return result;
	}
}

