package ui;

import h2d.Graphics;
import h2d.Object;
import h2d.Text;
import ludi.heaps.box.Box;

typedef MasterDetailConfig<T> = {
    ?headerTitle:String,
    ?footerHint:String,
    ?listWidthRatio:Float,
    ?rowHeight:Int,
    itemFactory:(item:T, rowWidth:Int, rowHeight:Int)->Object,
    detailFactory:(width:Int, height:Int)->Object,
    detailUpdater:(detailView:Object, item:T)->Void
}

private class SelectableWrapper extends Object {
    public var inner:Object;
    var bg:Graphics;
    var border:Graphics;
    var rowWidth:Int;
    var rowHeight:Int;

    public function new(inner:Object, rowWidth:Int, rowHeight:Int) {
        super();
        this.inner = inner;
        this.rowWidth = rowWidth;
        this.rowHeight = rowHeight;

        bg = new Graphics(this);
        border = new Graphics(this);
        addChild(inner);

        drawIdle();
    }

    inline function drawIdle() {
        bg.clear();
        bg.beginFill(0x000000, 0);
        bg.drawRect(0, 0, rowWidth, rowHeight);
        bg.endFill();
        border.clear();
    }

    public function setSelected(selected:Bool) {
        if (selected) {
            bg.clear();
            bg.beginFill(0x77D7FF, 0.3);
            bg.drawRect(0, 0, rowWidth, rowHeight);
            bg.endFill();

            border.clear();
            border.lineStyle(2, 0x00E1FF, 1);
            border.drawRect(1, 1, rowWidth - 2, rowHeight - 2);
        } else {
            drawIdle();
        }
    }
}

class MasterDetailList<T> extends Object {
    public var totalWidth(default, null):Float;
    public var totalHeight(default, null):Float;
    public dynamic function onItemActivated(item:T):Void {}

    var nav:ArrowNav;
    var listBox:NavScrollBox;
    var detailBox:Box;
    var detailView:Object;
    var headerBox:Box;
    var headerTitle:Text;
    var footerBox:Box;
    var footerHint:Text;

    var rowHeight:Int;
    var listWidth:Int;
    var detailWidth:Int;

    var cfg:MasterDetailConfig<T>;
    var itemLookup:Map<Object, T> = new Map();
    var wrapperLookup:Map<Object, SelectableWrapper> = new Map();

    public function new(width:Float, height:Float, cfg:MasterDetailConfig<T>) {
        super();

        this.totalWidth = width;
        this.totalHeight = height;
        this.cfg = cfg;

        var listRatio = cfg.listWidthRatio != null ? cfg.listWidthRatio : 0.45;
        rowHeight = cfg.rowHeight != null ? cfg.rowHeight : 56;

        var headerH = 44;
        var footerH = 36;
        listWidth = Std.int(width * listRatio);
        detailWidth = Std.int(width - listWidth);

        var root = Box.build(Std.int(width), Std.int(height));
        root.backgroundColor(0x1E1E1E);
        addChild(root.get());

        var hb = Box.build(Std.int(width), headerH);
        hb.verticalGradient(0x2B3A42, 0x1F2A30);
        hb.roundedCorners(0);
        headerBox = hb.get();
        root.get().addChild(headerBox);

        headerTitle = new Text(hxd.Res.fonts.plex_mono_64.toFont(), headerBox);
        headerTitle.text = cfg.headerTitle != null ? cfg.headerTitle : "Items";
        headerTitle.textColor = 0xFFFFFF;
        headerTitle.scaleX = 0.35;
        headerTitle.scaleY = 0.35;
        headerTitle.x = 12;
        headerTitle.y = Std.int((headerH - headerTitle.textHeight * 0.35) / 2);

        var fb = Box.build(Std.int(width), footerH);
        fb.verticalGradient(0x1F2A30, 0x151A1E);
        fb.roundedCorners(0);
        footerBox = fb.get();
        root.get().addChild(footerBox);
        footerBox.y = height - footerH;

        footerHint = new Text(hxd.Res.fonts.plex_mono_64.toFont(), footerBox);
        footerHint.text = cfg.footerHint != null ? cfg.footerHint : "Enter: Select   Esc: Back";
        footerHint.textColor = 0x99C9FF;
        footerHint.scaleX = 0.3;
        footerHint.scaleY = 0.3;
        footerHint.x = 12;
        footerHint.y = Std.int((footerH - footerHint.textHeight * 0.3) / 2);

        listBox = new NavScrollBox(listWidth, Std.int(height - headerH - footerH));
        listBox.addPlugin(new ludi.heaps.box.Plugins.BackgroundColorPlugin(0x262626));
        root.get().addChild(listBox);
        listBox.y = headerH;

        var db = Box.build(detailWidth, Std.int(height - headerH - footerH));
        db.backgroundColor(0x202020);
        db.verticalGradient(0x2A2A2A, 0x151515);
        db.roundedCorners(6);
        db.roundedBorder(2, 0x000000, 6);
        detailBox = db.get();
        root.get().addChild(detailBox);
        detailBox.x = listWidth;
        detailBox.y = headerH;

        detailView = cfg.detailFactory(Std.int(detailBox.width), Std.int(detailBox.height));
        detailBox.addChild(detailView);

        nav = new ArrowNav();
    }

    public function setItems(items:Array<T>) {
        listBox.clear();
        itemLookup = new Map();
        wrapperLookup = new Map();

        for (item in items) {
            var inner = cfg.itemFactory(item, Std.int(listBox.width), rowHeight);
            var wrapper = new SelectableWrapper(inner, Std.int(listBox.width), rowHeight);
            listBox.addChild(wrapper);
            itemLookup.set(wrapper, item);
            wrapperLookup.set(wrapper, wrapper);

            nav.bind(wrapper, (e:ArrowNavEvent) -> {
                switch e {
                    case Enter:
                        wrapper.setSelected(true);
                        cfg.detailUpdater(detailView, item);
                    case Leave:
                        wrapper.setSelected(false);
                    case Selected:
                        if (onItemActivated != null) onItemActivated(item);
                }
            });
        }
    }

    public function update(dt:Float) {
        if (nav != null) nav.update();
    }
}

