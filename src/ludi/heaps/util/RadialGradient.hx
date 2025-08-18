package ludi.heaps.util;

import h2d.Tile;
import hxd.fmt.grd.Data.Color;

class RadialGradient {
	public var stops:Array<{ location:Float, color:Color, opacity:Float }>;
	public var resolution:Int;
	public var centerX:Float; // normalized [0..1]
	public var centerY:Float; // normalized [0..1]

	public function new(stops:Array<{ location:Float, color:Color, opacity:Float }>, ?resolution:Int = 256, ?centerX:Float = 0.5, ?centerY:Float = 0.5) {
		if (!hxd.Math.isPOT(resolution)) throw "gradient resolution should be a power of two";
		this.stops = prepareStops(stops);
		this.resolution = resolution;
		this.centerX = centerX;
		this.centerY = centerY;
	}

	public function getTile():Tile {
		var pixels = buildPixels(resolution, resolution, centerX, centerY, stops);
		return Tile.fromPixels(pixels);
	}

	public static function twoColor(cInner:Int, cOuter:Int, ?resolution:Int = 256):RadialGradient {
		return new RadialGradient([
			{ location: 0.0, color: hexToRGB(cInner), opacity: 0.5 },
			{ location: 1.0, color: hexToRGB(cOuter), opacity: 1.0 }
		], resolution);
	}

	static inline function hexToRGB(hex:Int):Color {
		if (hex < 0 || hex > 0xFFFFFF) throw "Invalid hex color value. Expected range: 0x000000 to 0xFFFFFF";
		var r = (hex >> 16) & 0xFF;
		var g = (hex >> 8) & 0xFF;
		var b = hex & 0xFF;
		return RGB(r, g, b);
	}

	static function prepareStops(src:Array<{ location:Float, color:Color, opacity:Float }>):Array<{ location:Float, color:Color, opacity:Float }>{
		if (src == null || src.length == 0) throw "RadialGradient requires at least one stop";
		var arr = src.copy();
		arr.sort(function(a, b) return a.location < b.location ? -1 : (a.location > b.location ? 1 : 0));
		return arr;
	}

	static inline function clamp01(x:Float):Float return x < 0 ? 0 : (x > 1 ? 1 : x);

	static function buildPixels(w:Int, h:Int, cxNorm:Float, cyNorm:Float, stops:Array<{ location:Float, color:Color, opacity:Float }>):hxd.Pixels {
		var pixels = hxd.Pixels.alloc(w, h, ARGB);
		var invW = 1.0 / (w - 1);
		var invH = 1.0 / (h - 1);

		// Compute max radius from the chosen center to the farthest corner in normalized [0..1] space
		var corners = [
			{ x: 0.0, y: 0.0 },
			{ x: 1.0, y: 0.0 },
			{ x: 0.0, y: 1.0 },
			{ x: 1.0, y: 1.0 }
		];
		var maxR = 0.0;
		for (c in corners) {
			var dx = c.x - cxNorm;
			var dy = c.y - cyNorm;
			var d = Math.sqrt(dx * dx + dy * dy);
			if (d > maxR) maxR = d;
		}
		if (maxR <= 0) maxR = 1.0; // avoid div by zero if degenerate
		var invMaxR = 1.0 / maxR;

		for (y in 0...h) {
			for (x in 0...w) {
				var px = x * invW; // [0..1]
				var py = y * invH; // [0..1]
				var dx = px - cxNorm;
				var dy = py - cyNorm;
				var r = Math.sqrt(dx * dx + dy * dy);
				var t = clamp01(r * invMaxR);
				var c = sampleColor(t, stops);
				pixels.setPixel(x, y, c);
			}
		}
		return pixels;
	}

	static function sampleColor(t:Float, stops:Array<{ location:Float, color:Color, opacity:Float }>):Int {
		if (stops.length == 1) {
			var c0 = toRGBA(stops[0].color, stops[0].opacity);
			return c0;
		}
		var lo = stops[0];
		var hi = stops[stops.length - 1];
		if (t <= lo.location) return toRGBA(lo.color, lo.opacity);
		if (t >= hi.location) return toRGBA(hi.color, hi.opacity);
		var i = 0;
		while (i < stops.length - 1) {
			var s0 = stops[i];
			var s1 = stops[i + 1];
			if (t >= s0.location && t <= s1.location) {
				var span = s1.location - s0.location;
				var u = span <= 0 ? 0 : (t - s0.location) / span;
				var rgba0 = unpackRGBA(toRGBA(s0.color, s0.opacity));
				var rgba1 = unpackRGBA(toRGBA(s1.color, s1.opacity));
				var a = Std.int(Math.round(lerp(rgba0.a, rgba1.a, u)));
				var r = Std.int(Math.round(lerp(rgba0.r, rgba1.r, u)));
				var g = Std.int(Math.round(lerp(rgba0.g, rgba1.g, u)));
				var b = Std.int(Math.round(lerp(rgba0.b, rgba1.b, u)));
				return (a << 24) | (r << 16) | (g << 8) | b;
			}
			i++;
		}
		return toRGBA(hi.color, hi.opacity);
	}

	static inline function lerp(a:Float, b:Float, t:Float):Float return a + (b - a) * t;

	static inline function toRGBA(c:Color, opacity:Float):Int {
		switch (c) {
			case RGB(r, g, b):
				var a = Std.int(Math.round(clamp01(opacity) * 255));
				return (Std.int(a) << 24) | ((Std.int(r) & 0xFF) << 16) | ((Std.int(g) & 0xFF) << 8) | (Std.int(b) & 0xFF);
			default:
				throw "Only RGB colors are supported in RadialGradient";
		}
	}

	static inline function unpackRGBA(argb:Int):{ a:Int, r:Int, g:Int, b:Int } {
		var a = (argb >>> 24) & 0xFF;
		var r = (argb >> 16) & 0xFF;
		var g = (argb >> 8) & 0xFF;
		var b = argb & 0xFF;
		return { a: a, r: r, g: g, b: b };
	}
}

