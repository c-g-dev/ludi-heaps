package ludi.heaps.macro;


class StaticAppReference {

    public static function addInstance() {
        no.Spoon.bend("hxd.App", (fields, cls) -> {
            fields.find("new").kind(/*get new expr + macro instance = this;*/ switch -> FFun(f).expr += macro instance = this;);
            fields.patch("hxd.App", macro class {
                public static var instance: hxd.App;
                public function new() {
                    //combined expr
                }
            });
        });
        haxe.macro.Compiler.define("staticAppReference", "true");
    }
}