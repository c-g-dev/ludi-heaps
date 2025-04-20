package ludi.heaps.input;

interface IInputSystem {
    public function isKeyDown(code: Int): Bool;
    public function isKeyPressed(code: Int): Bool;
    public function isKeyReleased(code: Int): Bool;
    public function getCustomValue(tag: String): Dynamic;
}

class InputSystem {
    public static var instance: IInputSystem;
}

class BaseInputSystem implements IInputSystem {

    public function isKeyDown(code:Int):Bool {
        throw new haxe.exceptions.NotImplementedException();
    }

    public function isKeyPressed(code:Int):Bool {
        throw new haxe.exceptions.NotImplementedException();
    }

    public function isKeyReleased(code:Int):Bool {
        throw new haxe.exceptions.NotImplementedException();
    }

    public function getCustomValue(tag:String):Dynamic {
        throw new haxe.exceptions.NotImplementedException();
    }
}