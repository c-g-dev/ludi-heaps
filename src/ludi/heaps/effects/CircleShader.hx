package ludi.heaps.effects;

import hxsl.Types.Vec;
import hxsl.Types.Vec4;

class CircleShader extends hxsl.Shader {

	static var SRC = {
		var input : {
			var uv : Vec2;
		};

		var output : {
			var color : Vec4;
		};

		@param var rectSize : Vec2;           // render quad size in pixels
		@param var radiusPx : Float;          // circle radius in pixels
		@param var fillColor : Vec4;          // RGBA (used when hasTexture == false)
		@param var borderColor : Vec4;        // RGBA
		@param var borderThickness : Float;   // border thickness in pixels
		@param var featherPx : Float;         // AA feather width in pixels
		@const var hasTexture : Bool;         // compile-time switch for using texture
		@param var fillTex : Sampler2D;       // texture used as fill (when hasTexture)

		function sdfCircle(local:Vec2, radius:Float):Float {
			return length(local) - radius;
		}

		function fragment() {
			var p = input.uv * rectSize;
			var halfSize = rectSize * 0.5;
			var local = p - halfSize;

			var dist = sdfCircle(local, radiusPx);

			var aa = max(featherPx, 0.0001);

			// Coverage for filled circle interior
			var fillCoverage = 1.0 - smoothstep(0.0, aa, dist);

			// Border coverage as a band outside the fill
			var t = max(borderThickness, 0.0);
			var covBorder = (t > 0.0) ? clamp(smoothstep(0.0, aa, dist + t) - smoothstep(0.0, aa, dist), 0.0, 1.0) : 0.0;

			var fill:Vec4;
			if (hasTexture) {
				var texCol = fillTex.get(input.uv);
				fill = texCol * fillCoverage;
			} else {
				fill = fillColor * fillCoverage;
			}

			var outCol = fill + borderColor * covBorder;
			outCol.a = clamp(outCol.a, 0.0, 1.0);
			output.color = outCol;
		}
	};


	public function new(width:Float, height:Float, radius:Float, fillColorARGB:Int = 0xFFFFFFFF, borderThickness:Float = 0.0, borderColorARGB:Int = 0x00000000, featherPx:Float = 1.0, ?fillTexture:h3d.mat.Texture) {
		super();
		this.rectSize = new hxsl.Vec(width, height);
		this.radiusPx = radius;
		this.fillColor = toColor(fillColorARGB);
		this.borderColor = toColor(borderColorARGB);
		this.borderThickness = borderThickness;
		this.featherPx = featherPx;
		this.hasTexture = fillTexture != null;
		if (fillTexture != null) this.fillTex = fillTexture;
	}

	public function setSize(width:Float, height:Float):CircleShader {
		rectSize.set(width, height);
		return this;
	}

	public function setRadius(radius:Float):CircleShader {
		radiusPx = radius;
		return this;
	}

	public function setFillColor(argb:Int):CircleShader {
		fillColor = toColor(argb);
		hasTexture = false;
		return this;
	}

	public function setFillTexture(tex:h3d.mat.Texture):CircleShader {
		this.fillTex = tex;
		hasTexture = true;
		return this;
	}

	public function setFillTile(tile:h2d.Tile):CircleShader {
		this.fillTex = tile.getTexture();
		hasTexture = true;
		return this;
	}

	public function clearFillTexture():CircleShader {
		hasTexture = false;
		return this;
	}

	public function setBorder(thickness:Float, argb:Int):CircleShader {
		borderThickness = thickness;
		borderColor = toColor(argb);
		return this;
	}

	public function setBorderThickness(thickness:Float):CircleShader {
		borderThickness = thickness;
		return this;
	}

	public function setBorderColor(argb:Int):CircleShader {
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