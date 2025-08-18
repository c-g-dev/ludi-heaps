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
		@param var cornerRadii : Vec4;       // TL, TR, BR, BL radii (in pixels)
		@param var borderThicknessTRBL : Vec4; // Top, Right, Bottom, Left thickness (pixels)
		@param var fillColor : Vec4;          // RGBA (used when hasTexture == false)
		@param var borderColorTop : Vec4;     // RGBA
		@param var borderColorRight : Vec4;   // RGBA
		@param var borderColorBottom : Vec4;  // RGBA
		@param var borderColorLeft : Vec4;    // RGBA
		@param var featherPx : Float;         // AA feather width in pixels
		@const var hasTexture : Bool;         // compile-time switch for using texture
		@param var fillTex : Sampler2D;       // texture used as fill (when hasTexture)

		function sdfRoundedRect(local:Vec2, halfExtents:Vec2, radius:Float):Float {
			var q = abs(local) - (halfExtents - vec2(radius, radius));
			return length(max(q, vec2(0.0, 0.0))) - radius;
		}

		function cornerRadiusFor(local:Vec2):Float {
			var r = 0.0;
			if (local.x < 0.0) {
				if (local.y < 0.0) r = cornerRadii.x; else r = cornerRadii.w; // TL : BL
			} else {
				if (local.y < 0.0) r = cornerRadii.y; else r = cornerRadii.z; // TR : BR
			}
			return r;
		}

		function sdfAt(local:Vec2):Float {
			var halfSize = rectSize * 0.5;
			var r = cornerRadiusFor(local);
			return sdfRoundedRect(local, halfSize, r);
		}

		function fragment() {
			var p = input.uv * rectSize;
			var halfSize = rectSize * 0.5;
			var local = p - halfSize;
			var dist = sdfAt(local);

			var aa = max(featherPx, 0.0001);

			// Coverage for filled rounded-rect interior
			var fillCoverage = 1.0 - smoothstep(0.0, aa, dist);

			// Per-side border coverage using SDF gradient for side classification
			var dx1 = sdfAt(local + vec2(1.0, 0.0));
			var dx2 = sdfAt(local - vec2(1.0, 0.0));
			var dy1 = sdfAt(local + vec2(0.0, 1.0));
			var dy2 = sdfAt(local - vec2(0.0, 1.0));
			var grad = vec2(dx1 - dx2, dy1 - dy2) * 0.5;
			var agx = abs(grad.x);
			var agy = abs(grad.y);
			var isHorizontal = agx >= agy;
			var mTop = 0.0;
			var mRight = 0.0;
			var mBottom = 0.0;
			var mLeft = 0.0;
			if (!isHorizontal && grad.y < 0.0) mTop = 1.0;
			if (isHorizontal && grad.x > 0.0) mRight = 1.0;
			if (!isHorizontal && grad.y > 0.0) mBottom = 1.0;
			if (isHorizontal && grad.x < 0.0) mLeft = 1.0;
			var tTop = max(borderThicknessTRBL.x, 0.0);
			var tRight = max(borderThicknessTRBL.y, 0.0);
			var tBottom = max(borderThicknessTRBL.z, 0.0);
			var tLeft = max(borderThicknessTRBL.w, 0.0);
			var covTop = (tTop > 0.0) ? clamp(smoothstep(0.0, aa, dist + tTop) - smoothstep(0.0, aa, dist), 0.0, 1.0) * mTop : 0.0;
			var covRight = (tRight > 0.0) ? clamp(smoothstep(0.0, aa, dist + tRight) - smoothstep(0.0, aa, dist), 0.0, 1.0) * mRight : 0.0;
			var covBottom = (tBottom > 0.0) ? clamp(smoothstep(0.0, aa, dist + tBottom) - smoothstep(0.0, aa, dist), 0.0, 1.0) * mBottom : 0.0;
			var covLeft = (tLeft > 0.0) ? clamp(smoothstep(0.0, aa, dist + tLeft) - smoothstep(0.0, aa, dist), 0.0, 1.0) * mLeft : 0.0;

			var fill:Vec4;
			if (hasTexture) {
				var texCol = fillTex.get(input.uv);
				fill = texCol * fillCoverage;
			} else {
				fill = fillColor * fillCoverage;
			}
			var border = borderColorTop * covTop + borderColorRight * covRight + borderColorBottom * covBottom + borderColorLeft * covLeft;
			var outCol = fill + border;
			outCol.a = clamp(outCol.a, 0.0, 1.0);
			output.color = outCol;
		}
	};



	public function new(width:Float, height:Float, radius:Float = 8.0, fillColorARGB:Int = 0xFFFFFFFF, borderThickness:Float = 0.0, borderColorARGB:Int = 0x00000000, featherPx:Float = 1.0, ?fillTexture:h3d.mat.Texture) {
		super();
		this.rectSize = new hxsl.Vec(width, height);
		this.cornerRadii = new hxsl.Vec4(radius, radius, radius, radius);
		this.borderThicknessTRBL = new hxsl.Vec4(borderThickness, borderThickness, borderThickness, borderThickness);
		this.fillColor = toColor(fillColorARGB);
		var bc = toColor(borderColorARGB);
		this.borderColorTop = bc;
		this.borderColorRight = bc;
		this.borderColorBottom = bc;
		this.borderColorLeft = bc;
		this.featherPx = featherPx;
		this.hasTexture = fillTexture != null;
		if (fillTexture != null) this.fillTex = fillTexture;
	}

	public function setSize(width:Float, height:Float):RoundedRectangleShader {
		rectSize.set(width, height);
		return this;
	}

	public function setFillColor(argb:Int):RoundedRectangleShader {
		fillColor = toColor(argb);
		hasTexture = false;
		return this;
	}

	public function setFillTexture(tex:h3d.mat.Texture):RoundedRectangleShader {
		this.fillTex = tex;
		hasTexture = true;
		return this;
	}

	public function setFillTile(tile:h2d.Tile):RoundedRectangleShader {
		this.fillTex = tile.getTexture();
		hasTexture = true;
		return this;
	}

	public function clearFillTexture():RoundedRectangleShader {
		hasTexture = false;
		return this;
	}
	public function setBorder(thickness:Float, argb:Int):RoundedRectangleShader {
		borderThicknessTRBL = new hxsl.Vec4(thickness, thickness, thickness, thickness);
		var c = toColor(argb);
		borderColorTop = c;
		borderColorRight = c;
		borderColorBottom = c;
		borderColorLeft = c;
		return this;
	}

	public function setBorderThicknesses(top:Float, right:Float, bottom:Float, left:Float):RoundedRectangleShader {
		borderThicknessTRBL = new hxsl.Vec4(top, right, bottom, left);
		return this;
	}

	public function setBorderColors(topARGB:Int, rightARGB:Int, bottomARGB:Int, leftARGB:Int):RoundedRectangleShader {
		borderColorTop = toColor(topARGB);
		borderColorRight = toColor(rightARGB);
		borderColorBottom = toColor(bottomARGB);
		borderColorLeft = toColor(leftARGB);
		return this;
	}

	public function setBorderTop(thickness:Float, argb:Int):RoundedRectangleShader {
		borderThicknessTRBL.x = thickness;
		borderColorTop = toColor(argb);
		return this;
	}

	public function setBorderRight(thickness:Float, argb:Int):RoundedRectangleShader {
		borderThicknessTRBL.y = thickness;
		borderColorRight = toColor(argb);
		return this;
	}

	public function setBorderBottom(thickness:Float, argb:Int):RoundedRectangleShader {
		borderThicknessTRBL.z = thickness;
		borderColorBottom = toColor(argb);
		return this;
	}

	public function setBorderLeft(thickness:Float, argb:Int):RoundedRectangleShader {
		borderThicknessTRBL.w = thickness;
		borderColorLeft = toColor(argb);
		return this;
	}

	public function setCornerRadius(radius:Float):RoundedRectangleShader {
		cornerRadii = new hxsl.Vec4(radius, radius, radius, radius);
		return this;
	}

	public function setCornerRadii(topLeft:Float, topRight:Float, bottomRight:Float, bottomLeft:Float):RoundedRectangleShader {
		cornerRadii = new hxsl.Vec4(topLeft, topRight, bottomRight, bottomLeft);
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


