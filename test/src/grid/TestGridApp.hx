package grid;



import h2d.Tile;

import ludi.heaps.grid.Bootstrap.BasicGridActor;
import ludi.heaps.grid.Grid.GridContainer;
import ludi.heaps.grid.Cell;
import hxd.Res;
import grid.FXAA.FXAAFilter;

import h2d.Bitmap;
import h2d.Tile;
import ludi.heaps.effects.RoundedRectangleShader;

class TestGridApp extends hxd.App {

    var bmp:Bitmap;

    override function init() {
        super.init();

     //   sdl.Sdl.setGLOptions(4, 3, 24, 8, 1, 4);

        Res.initEmbed();
     //   s2d.defaultSmooth = true;

     /*
        var fxaa =  new FXAAFilter() ;
        fxaa.blendStrength = 3;
        s2d.filter = fxaa;
        
        /*
        var grid = new GridContainer(10, 10, 32);
        s2d.addChild(grid);

        var actor = new BasicGridActor();
        var gfx = new h2d.Graphics();
        gfx.smooth = true;
        gfx.beginFill(0xEC1515);
        gfx.drawCircle(16, 16, 16, 100);
        gfx.endFill();

        actor.addChild(gfx);
        grid.placeActor(actor, new Cell(0, 0));
        */

     /*   var builder = ludi.heaps.box.Box.build(300, 300);
        builder.roundedCorners(30);
        builder.verticalGradient(0xEC1515, 0x692D2D);
        var box = builder.get();
                     

        s2d.addChild(box);*/


        var w = 240;
        var h = 120;
        bmp = new Bitmap(Tile.fromColor(0xFFFFFFFF, w, h), s2d);

        // fill: ARGB, border optional
        var shader = new RoundedRectangleShader(
            w, h,
            16,            // corner radius (px)
            0xFF2D8CFF,    // fill ARGB
            2,             // border thickness (px), 0 disables
            0xFFFFFFFF,    // border ARGB
            1.0            // AA feather (px)
        );
        bmp.addShader(shader);
    }

    public override function update(dt:Float) {
        //slowly zoom in on bmp
        bmp.scaleX += 0.01;
        bmp.scaleY += 0.01;
    }

    public static function main() {
        new TestGridApp();
    }
}