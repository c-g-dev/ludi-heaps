import h2d.Tile;

import ludi.heaps.grid.Bootstrap.BasicGridActor;
import ludi.heaps.grid.Grid.GridContainer;
import ludi.heaps.grid.Cell;
import hxd.Res;

class TestGridApp extends hxd.App {

    override function init() {
        super.init();

        Res.initEmbed();
        var grid = new GridContainer(10, 10, 32);
        s2d.addChild(grid);

        var actor = new BasicGridActor();
        actor.addChild(new h2d.Bitmap(Tile.fromColor(0xEC1515, 32, 32)));
        grid.placeActor(actor, new Cell(0, 0));
    }

    public static function main() {
        new TestGridApp();
    }
}