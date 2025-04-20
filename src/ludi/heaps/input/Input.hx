package ludi.heaps.input;


//var i = Input.scope("Controls");
    //i.isKeyPressed (this.enabled && window.isKeyPressed)
    //i.of(ControlType).
    //i.get("tag") //direct access
    //i.createBehavior(); //behavior to allow for listener reactions

//Input.stashPush();
//Input.scope("GUI").only();
//...
//Input.stashPop();

class Input {
    public static function stashPush(): Void {

    }
    public static function stashPop(): Void {

    }
    public static function scope(name: String): InputNode {
        return null;
    }

}

class InputNode {

    var name: String;

    public function addChild(){}
    public function on(){}
    public function off(){}
    public function only(){}

    public function isKeyDown(code: Int): Bool { return false; }
    public function isKeyPressed(code: Int): Bool { return false; }
    public function isKeyReleased(code: Int): Bool { return false; }
    
    public macro function of(ct: haxe.macro.Expr): haxe.macro.Expr  { return macro null; }

    public function get(tag: String): Dynamic  { return false; }
}


class InputListenBehavior extends Behavior {

}