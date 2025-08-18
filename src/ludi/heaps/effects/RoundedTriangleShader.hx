package ludi.heaps.effects;

import hxsl.Types.Vec;
import hxsl.Types.Vec3;
import hxsl.Types.Vec4;

class RoundedTriangleShader extends hxsl.Shader {

	static var SRC = {
		var input : {
			var uv : Vec2;
		};

		var output : {
			var color : Vec4;
		};

		// Canvas (pixel) size corresponding to input.uv in [0,1]
		@param var rectSize : Vec2;

		// Triangle vertices in pixel space (relative to 0..rectSize)
		@param var pA : Vec2;
		@param var pB : Vec2;
		@param var pC : Vec2;

		// Corner radius (uniform). For 0.0, the triangle is sharp.
		@param var cornerRadius : Float;

		// Per-edge border thicknesses for edges AB, BC, CA
		@param var borderThicknessABC : Vec3;

		// Fill and border colors
		@param var fillColor : Vec4;
		@param var borderColorAB : Vec4;
		@param var borderColorBC : Vec4;
		@param var borderColorCA : Vec4;

		// AA feather width in pixels
		@param var featherPx : Float;

		// Optional texture fill
		@const var hasTexture : Bool;
		@param var fillTex : Sampler2D;

		function dot2(v:Vec2):Float {
			return dot(v, v);
		}

		function distToSegment(p:Vec2, a:Vec2, b:Vec2):Float {
			var pa = p - a;
			var ba = b - a;
			var h = clamp(dot(pa, ba) / max(dot2(ba), 1e-6), 0.0, 1.0);
			return length(pa - ba * h);
		}

		function orientation(a:Vec2, b:Vec2, c:Vec2):Float {
			return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
		}

		function signedDistanceTriangle(p:Vec2, a:Vec2, b:Vec2, c:Vec2):Float {
			var dAB = distToSegment(p, a, b);
			var dBC = distToSegment(p, b, c);
			var dCA = distToSegment(p, c, a);
			var unsignedD = min(dAB, min(dBC, dCA));

			// Inside test via consistent edge orientation
			var ori = orientation(a, b, c);
			var s0 = orientation(a, b, p);
			var s1 = orientation(b, c, p);
			var s2 = orientation(c, a, p);
			if (ori < 0.0) {
				s0 = -s0; s1 = -s1; s2 = -s2;
			}
			var inside = min(s0, min(s1, s2)) >= 0.0;
			var signV = inside ? -1.0 : 1.0;
			return unsignedD * signV;
		}

		function fragment() {
			var p = input.uv * rectSize;
			var distRaw = signedDistanceTriangle(p, pA, pB, pC);

			var aa = max(featherPx, 0.0001);

			// Rounded by inward offset (fillet) using cornerRadius
			var dist = distRaw + cornerRadius;

			// Fill coverage
			var fillCoverage = 1.0 - smoothstep(0.0, aa, dist);

			// Edge selection for per-edge borders
			var dAB = distToSegment(p, pA, pB);
			var dBC = distToSegment(p, pB, pC);
			var dCA = distToSegment(p, pC, pA);
			var mAB = 0.0;
			var mBC = 0.0;
			var mCA = 0.0;
			if (dAB <= dBC && dAB <= dCA) mAB = 1.0;
			else if (dBC <= dAB && dBC <= dCA) mBC = 1.0;
			else mCA = 1.0;

			var tAB = max(borderThicknessABC.x, 0.0);
			var tBC = max(borderThicknessABC.y, 0.0);
			var tCA = max(borderThicknessABC.z, 0.0);

			var covAB = (tAB > 0.0) ? clamp(smoothstep(0.0, aa, dist + tAB) - smoothstep(0.0, aa, dist), 0.0, 1.0) * mAB : 0.0;
			var covBC = (tBC > 0.0) ? clamp(smoothstep(0.0, aa, dist + tBC) - smoothstep(0.0, aa, dist), 0.0, 1.0) * mBC : 0.0;
			var covCA = (tCA > 0.0) ? clamp(smoothstep(0.0, aa, dist + tCA) - smoothstep(0.0, aa, dist), 0.0, 1.0) * mCA : 0.0;

			var fill:Vec4;
			if (hasTexture) {
				var texCol = fillTex.get(input.uv);
				fill = texCol * fillCoverage;
			} else {
				fill = fillColor * fillCoverage;
			}
			var border = borderColorAB * covAB + borderColorBC * covBC + borderColorCA * covCA;
			var outCol = fill + border;
			outCol.a = clamp(outCol.a, 0.0, 1.0);
			output.color = outCol;
		}
	};

	public function new(width:Float, height:Float, radius:Float = 0.0, fillColorARGB:Int = 0xFFFFFFFF, borderThickness:Float = 0.0, borderColorARGB:Int = 0x00000000, featherPx:Float = 1.0, ?fillTexture:h3d.mat.Texture) {
		super();
		this.rectSize = new hxsl.Vec(width, height);
		// Default triangle: apex top-center, base along bottom
		this.pA = new hxsl.Vec(width * 0.5, 0.0);
		this.pB = new hxsl.Vec(0.0, height);
		this.pC = new hxsl.Vec(width, height);
		this.cornerRadius = radius;
		this.borderThicknessABC = new hxsl.Vec3(borderThickness, borderThickness, borderThickness);
		this.fillColor = toColor(fillColorARGB);
		var bc = toColor(borderColorARGB);
		this.borderColorAB = bc;
		this.borderColorBC = bc;
		this.borderColorCA = bc;
		this.featherPx = featherPx;
		this.hasTexture = fillTexture != null;
		if (fillTexture != null) this.fillTex = fillTexture;
	}

	public function setSize(width:Float, height:Float):RoundedTriangleShader {
		rectSize.set(width, height);
		return this;
	}

	public function setVertices(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):RoundedTriangleShader {
		pA.set(ax, ay);
		pB.set(bx, by);
		pC.set(cx, cy);
		return this;
	}

	public function setFillColor(argb:Int):RoundedTriangleShader {
		fillColor = toColor(argb);
		hasTexture = false;
		return this;
	}

	public function setFillTexture(tex:h3d.mat.Texture):RoundedTriangleShader {
		this.fillTex = tex;
		hasTexture = true;
		return this;
	}

	public function setFillTile(tile:h2d.Tile):RoundedTriangleShader {
		this.fillTex = tile.getTexture();
		hasTexture = true;
		return this;
	}

	public function clearFillTexture():RoundedTriangleShader {
		hasTexture = false;
		return this;
	}

	public function setBorder(thickness:Float, argb:Int):RoundedTriangleShader {
		borderThicknessABC = new hxsl.Vec3(thickness, thickness, thickness);
		var c = toColor(argb);
		borderColorAB = c;
		borderColorBC = c;
		borderColorCA = c;
		return this;
	}

	public function setBorderThicknesses(ab:Float, bc:Float, ca:Float):RoundedTriangleShader {
		borderThicknessABC = new hxsl.Vec3(ab, bc, ca);
		return this;
	}

	public function setBorderColors(abARGB:Int, bcARGB:Int, caARGB:Int):RoundedTriangleShader {
		borderColorAB = toColor(abARGB);
		borderColorBC = toColor(bcARGB);
		borderColorCA = toColor(caARGB);
		return this;
	}

	public function setBorderAB(thickness:Float, argb:Int):RoundedTriangleShader {
		borderThicknessABC.x = thickness;
		borderColorAB = toColor(argb);
		return this;
	}

	public function setBorderBC(thickness:Float, argb:Int):RoundedTriangleShader {
		borderThicknessABC.y = thickness;
		borderColorBC = toColor(argb);
		return this;
	}

	public function setBorderCA(thickness:Float, argb:Int):RoundedTriangleShader {
		borderThicknessABC.z = thickness;
		borderColorCA = toColor(argb);
		return this;
	}

	public function setCornerRadius(radius:Float):RoundedTriangleShader {
		cornerRadius = radius;
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

