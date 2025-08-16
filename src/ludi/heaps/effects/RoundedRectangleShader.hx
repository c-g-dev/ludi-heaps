package ludi.heaps.effects;

import hxsl.Types.Vec;
import hxsl.Types.Vec4;

class RoundedRectangleShader extends hxsl.Shader {

	static var SRC = {
		var input : {
			var uv : Vec2;
		};

		var output : {
			var color : Vec4;
		};
		@param var rectSize : Vec2;          // rectangle size in pixels
		@param var cornerRadius : Float;      // uniform radius for all corners (in pixels)
		@param var borderThickness : Float;   // 0 for no border (in pixels)
		@param var fillColor : Vec4;          // RGBA
		@param var borderColor : Vec4;        // RGBA
		@param var featherPx : Float;         // AA feather width in pixels

		function sdfRoundedRect(local:Vec2, halfExtents:Vec2, radius:Float):Float {
			var q = abs(local) - (halfExtents - vec2(radius, radius));
			return length(max(q, vec2(0.0, 0.0))) - radius;
		}

		function fragment() {
			var p = input.uv * rectSize;
			var halfSize = rectSize * 0.5;
			var local = p - halfSize;
			var dist = sdfRoundedRect(local, halfSize, cornerRadius);

			var aa = max(featherPx, 0.0001);

			// Coverage for filled rounded-rect interior
			var fillCoverage = 1.0 - smoothstep(0.0, aa, dist);

			// Coverage for border ring, if any
			var ringCoverage = 0.0;
			if (borderThickness > 0.0) {
				var innerDist = dist + borderThickness;
				ringCoverage = clamp(smoothstep(0.0, aa, innerDist) - smoothstep(0.0, aa, dist), 0.0, 1.0);
			}

			var fill = fillColor * fillCoverage;
			var border = borderColor * ringCoverage;
			var outCol = fill + border;
			outCol.a = clamp(outCol.a, 0.0, 1.0);
			output.color = outCol;
		}
	};



	public function new(width:Float, height:Float, radius:Float = 8.0, fillColorARGB:Int = 0xFFFFFFFF, borderThickness:Float = 0.0, borderColorARGB:Int = 0x00000000, featherPx:Float = 1.0) {
		super();
		this.rectSize = new hxsl.Vec(width, height);
		this.cornerRadius = radius;
		this.borderThickness = borderThickness;
		this.fillColor = toColor(fillColorARGB);
		this.borderColor = toColor(borderColorARGB);
		this.featherPx = featherPx;
	}

	public function setSize(width:Float, height:Float):RoundedRectangleShader {
		rectSize.set(width, height);
		return this;
	}

	public function setFillColor(argb:Int):RoundedRectangleShader {
		fillColor = toColor(argb);
		return this;
	}

	public function setBorder(thickness:Float, argb:Int):RoundedRectangleShader {
		borderThickness = thickness;
		borderColor = toColor(argb);
		return this;
	}

	static inline function toColor(argb:Int):hxsl.Vec4 {
		var a = ((argb >>> 24) & 0xFF) / 255.0;
		var r = ((argb >>> 16) & 0xFF) / 255.0;
		var g = ((argb >>> 8) & 0xFF) / 255.0;
		var b = (argb & 0xFF) / 255.0;
		return new hxsl.Vec4(r, g, b, a);
	}
}


