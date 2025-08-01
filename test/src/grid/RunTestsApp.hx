package grid;



class RunTestsApp extends hxd.App {
    
    override function init() {
        // Run the grid tests
        GridTests.runAll();
        
        // Exit after tests complete
        haxe.Timer.delay(() -> {
            Sys.exit(0);
        }, 1000);
    }
    
    static function main() {
        new TestGridApp();
    }
}