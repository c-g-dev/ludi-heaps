package ludi.heaps.shapes;

import h2d.Bitmap;
import h2d.Tile;
import h2d.Object;
import h3d.mat.Texture;
import ludi.heaps.effects.RoundedRectangleShader;

class UIRectangle extends Bitmap {
    public var widthPx(get, set):Float;
    public var heightPx(get, set):Float;

    public var cornerRadius(get, set):Float;
    public var cornerTopLeft(get, set):Float;
    public var cornerTopRight(get, set):Float;
    public var cornerBottomRight(get, set):Float;
    public var cornerBottomLeft(get, set):Float;

    public var borderThickness(get, set):Float;
    public var borderThicknessTop(get, set):Float;
    public var borderThicknessRight(get, set):Float;
    public var borderThicknessBottom(get, set):Float;
    public var borderThicknessLeft(get, set):Float;

    public var fillColorARGB(get, set):Int;

    public var borderColorTopARGB(get, set):Int;
    public var borderColorRightARGB(get, set):Int;
    public var borderColorBottomARGB(get, set):Int;
    public var borderColorLeftARGB(get, set):Int;

    public var featherPx(get, set):Float;

    public var fillTexture(get, set):Texture;
    public var fillTile(get, set):Tile;

    public var hasTexture(get, never):Bool;

    var _widthPx:Float;
    var _heightPx:Float;

    var _cornerTopLeft:Float;
    var _cornerTopRight:Float;
    var _cornerBottomRight:Float;
    var _cornerBottomLeft:Float;

    var _borderTop:Float;
    var _borderRight:Float;
    var _borderBottom:Float;
    var _borderLeft:Float;

    var _fillColorARGB:Int;
    var _borderTopARGB:Int;
    var _borderRightARGB:Int;
    var _borderBottomARGB:Int;
    var _borderLeftARGB:Int;

    var _featherPx:Float;

    var _fillTexture:Texture;
    var _fillTile:Tile;

    var rr:RoundedRectangleShader;

    public function new(width:Float, height:Float, ?parent:Object, radius:Float = 8.0, fillColorARGB:Int = 0xFFFFFFFF, borderThickness:Float = 0.0, borderColorARGB:Int = 0x00000000, featherPx:Float = 1.0, ?initialFillTile:Tile) {
        var unit = Tile.fromColor(0xFFFFFFFF, 1, 1);
        super(unit, parent);

        rr = new RoundedRectangleShader(width, height, radius, fillColorARGB, borderThickness, borderColorARGB, featherPx, initialFillTile != null ? initialFillTile.getTexture() : null);
        shader = rr;

        _widthPx = width;
        _heightPx = height;
        scaleX = _widthPx;
        scaleY = _heightPx;

        _cornerTopLeft = radius;
        _cornerTopRight = radius;
        _cornerBottomRight = radius;
        _cornerBottomLeft = radius;

        _borderTop = borderThickness;
        _borderRight = borderThickness;
        _borderBottom = borderThickness;
        _borderLeft = borderThickness;

        _fillColorARGB = fillColorARGB;
        _borderTopARGB = borderColorARGB;
        _borderRightARGB = borderColorARGB;
        _borderBottomARGB = borderColorARGB;
        _borderLeftARGB = borderColorARGB;

        _featherPx = featherPx;

        _fillTile = initialFillTile;
        _fillTexture = initialFillTile != null ? initialFillTile.getTexture() : null;
    }

    inline function syncSize():Void {
        rr.setSize(_widthPx, _heightPx);
        scaleX = _widthPx;
        scaleY = _heightPx;
    }

    // Size
    function get_widthPx():Float return _widthPx;
    function set_widthPx(v:Float):Float {
        _widthPx = v;
        syncSize();
        return v;
    }

    function get_heightPx():Float return _heightPx;
    function set_heightPx(v:Float):Float {
        _heightPx = v;
        syncSize();
        return v;
    }

    // Corner radii
    function get_cornerRadius():Float return (_cornerTopLeft + _cornerTopRight + _cornerBottomRight + _cornerBottomLeft) * 0.25;
    function set_cornerRadius(v:Float):Float {
        _cornerTopLeft = v;
        _cornerTopRight = v;
        _cornerBottomRight = v;
        _cornerBottomLeft = v;
        rr.setCornerRadius(v);
        return v;
    }

    function get_cornerTopLeft():Float return _cornerTopLeft;
    function set_cornerTopLeft(v:Float):Float {
        _cornerTopLeft = v;
        rr.setCornerRadii(_cornerTopLeft, _cornerTopRight, _cornerBottomRight, _cornerBottomLeft);
        return v;
    }

    function get_cornerTopRight():Float return _cornerTopRight;
    function set_cornerTopRight(v:Float):Float {
        _cornerTopRight = v;
        rr.setCornerRadii(_cornerTopLeft, _cornerTopRight, _cornerBottomRight, _cornerBottomLeft);
        return v;
    }

    function get_cornerBottomRight():Float return _cornerBottomRight;
    function set_cornerBottomRight(v:Float):Float {
        _cornerBottomRight = v;
        rr.setCornerRadii(_cornerTopLeft, _cornerTopRight, _cornerBottomRight, _cornerBottomLeft);
        return v;
    }

    function get_cornerBottomLeft():Float return _cornerBottomLeft;
    function set_cornerBottomLeft(v:Float):Float {
        _cornerBottomLeft = v;
        rr.setCornerRadii(_cornerTopLeft, _cornerTopRight, _cornerBottomRight, _cornerBottomLeft);
        return v;
    }

    // Border thickness
    function get_borderThickness():Float return (_borderTop + _borderRight + _borderBottom + _borderLeft) * 0.25;
    function set_borderThickness(v:Float):Float {
        _borderTop = v;
        _borderRight = v;
        _borderBottom = v;
        _borderLeft = v;
        rr.setBorder(v, (_borderTopARGB + _borderRightARGB + _borderBottomARGB + _borderLeftARGB) == 0 ? 0x00000000 : _borderTopARGB);
        // Restore individual colors if they differ
        if (!(_borderTopARGB == _borderRightARGB && _borderTopARGB == _borderBottomARGB && _borderTopARGB == _borderLeftARGB)) {
            rr.setBorderColors(_borderTopARGB, _borderRightARGB, _borderBottomARGB, _borderLeftARGB);
        }
        return v;
    }

    function get_borderThicknessTop():Float return _borderTop;
    function set_borderThicknessTop(v:Float):Float {
        _borderTop = v;
        rr.setBorderTop(v, _borderTopARGB);
        return v;
    }

    function get_borderThicknessRight():Float return _borderRight;
    function set_borderThicknessRight(v:Float):Float {
        _borderRight = v;
        rr.setBorderRight(v, _borderRightARGB);
        return v;
    }

    function get_borderThicknessBottom():Float return _borderBottom;
    function set_borderThicknessBottom(v:Float):Float {
        _borderBottom = v;
        rr.setBorderBottom(v, _borderBottomARGB);
        return v;
    }

    function get_borderThicknessLeft():Float return _borderLeft;
    function set_borderThicknessLeft(v:Float):Float {
        _borderLeft = v;
        rr.setBorderLeft(v, _borderLeftARGB);
        return v;
    }

    // Fill color
    function get_fillColorARGB():Int return _fillColorARGB;
    function set_fillColorARGB(v:Int):Int {
        _fillColorARGB = v;
        rr.setFillColor(v);
        return v;
    }

    // Border colors
    function get_borderColorTopARGB():Int return _borderTopARGB;
    function set_borderColorTopARGB(v:Int):Int {
        _borderTopARGB = v;
        rr.setBorderTop(_borderTop, v);
        return v;
    }

    function get_borderColorRightARGB():Int return _borderRightARGB;
    function set_borderColorRightARGB(v:Int):Int {
        _borderRightARGB = v;
        rr.setBorderRight(_borderRight, v);
        return v;
    }

    function get_borderColorBottomARGB():Int return _borderBottomARGB;
    function set_borderColorBottomARGB(v:Int):Int {
        _borderBottomARGB = v;
        rr.setBorderBottom(_borderBottom, v);
        return v;
    }

    function get_borderColorLeftARGB():Int return _borderLeftARGB;
    function set_borderColorLeftARGB(v:Int):Int {
        _borderLeftARGB = v;
        rr.setBorderLeft(_borderLeft, v);
        return v;
    }

    // Feather
    function get_featherPx():Float return _featherPx;
    function set_featherPx(v:Float):Float {
        _featherPx = v;
        rr.featherPx = v;
        return v;
    }

    // Fill texture/tile
    function get_fillTexture():Texture return _fillTexture;
    function set_fillTexture(tex:Texture):Texture {
        _fillTexture = tex;
        _fillTile = null;
        if (tex != null) rr.setFillTexture(tex); else rr.clearFillTexture();
        return tex;
    }

    function get_fillTile():Tile return _fillTile;
    function set_fillTile(t:Tile):Tile {
        _fillTile = t;
        _fillTexture = t != null ? t.getTexture() : null;
        if (t != null) rr.setFillTile(t); else rr.clearFillTexture();
        return t;
    }

    function get_hasTexture():Bool return rr.hasTexture;

    // Convenience methods
    public function setBorder(thickness:Float, colorARGB:Int):UIRectangle {
        _borderTop = thickness;
        _borderRight = thickness;
        _borderBottom = thickness;
        _borderLeft = thickness;
        _borderTopARGB = colorARGB;
        _borderRightARGB = colorARGB;
        _borderBottomARGB = colorARGB;
        _borderLeftARGB = colorARGB;
        rr.setBorder(thickness, colorARGB);
        return this;
    }

    public function setCornerRadius(r:Float):UIRectangle {
        _cornerTopLeft = r;
        _cornerTopRight = r;
        _cornerBottomRight = r;
        _cornerBottomLeft = r;
        rr.setCornerRadius(r);
        return this;
    }
}