package ludi.heaps.util;

import h2d.Tile;
import hxd.fmt.grd.Data.Color;

class LinearGradient {
	public var angleDeg:Float;
	public var stops:Array<{ location:Float, color:Color, opacity:Float }>;
	public var resolution:Int;

	public function new(angle:Float, stops:Array<{ location:Float, color:Color, opacity:Float }>, ?resolution:Int = 256) {
		if (!hxd.Math.isPOT(resolution)) throw "gradient resolution should be a power of two";
		var normalized = ((Std.int(Math.floor(angle)) % 360) + 360) % 360;
		this.angleDeg = angle - Math.floor(angle) + normalized; // keep fractional part while normalizing
		this.stops = prepareStops(stops);
		this.resolution = resolution;
	}

	public function getTile():Tile {
		var pixels = buildPixels(resolution, resolution, angleDeg, stops);
		return Tile.fromPixels(pixels);
	}

	public static function twoColorVertical(c1:Int, c2:Int, ?resolution:Int = 256):LinearGradient {
		return new LinearGradient(90, [
			{ location: 0.0, color: hexToRGB(c1), opacity: 1.0 },
			{ location: 1.0, color: hexToRGB(c2), opacity: 1.0 }
		], resolution);
	}

	public static function twoColorHorizontal(c1:Int, c2:Int, ?resolution:Int = 256):LinearGradient {
		return new LinearGradient(0, [
			{ location: 0.0, color: hexToRGB(c1), opacity: 1.0 },
			{ location: 1.0, color: hexToRGB(c2), opacity: 1.0 }
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
		if (src == null || src.length == 0) throw "LinearGradient requires at least one stop";
		var arr = src.copy();
		arr.sort(function(a, b) return a.location < b.location ? -1 : (a.location > b.location ? 1 : 0));
		return arr;
	}

	static inline function clamp01(x:Float):Float return x < 0 ? 0 : (x > 1 ? 1 : x);

	static function buildPixels(w:Int, h:Int, angleDeg:Float, stops:Array<{ location:Float, color:Color, opacity:Float }>):hxd.Pixels {
		var pixels = hxd.Pixels.alloc(w, h, ARGB);
		var theta = angleDeg * Math.PI / 180.0;
		var dx = Math.cos(theta);
		var dy = Math.sin(theta);
		var denom = Math.abs(dx) + Math.abs(dy);
		if (denom == 0) denom = 1; // avoid div by zero; angle won't actually cause this
		var invDenom = 1.0 / denom;

		var cx = (w - 1) * 0.5;
		var cy = (h - 1) * 0.5;
		var invW = 1.0 / (w - 1);
		var invH = 1.0 / (h - 1);

		for (y in 0...h) {
			for (x in 0...w) {
				var px = x * invW - 0.5;
				var py = y * invH - 0.5;
				var proj = px * dx + py * dy;
				var t = clamp01(0.5 + proj * invDenom);
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
				throw "Only RGB colors are supported in LinearGradient";
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

