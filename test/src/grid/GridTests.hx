package grid;

import ludi.heaps.grid.*;
import ludi.heaps.grid.Mover.MoveDirection;
import ludi.heaps.grid.Driver.MoveRequest;
import ludi.heaps.grid.Headless.HeadlessGridActor;
import ludi.heaps.grid.Headless.HeadlessGridDriver;
import ludi.heaps.grid.Headless.HeadlessGridAnimator;
import ludi.heaps.grid.Grid.CellInfo;
import TestTriggers.TestBlockingTrigger;
import TestTriggers.TestDelayedTrigger;
import TestMover.TestableHeadlessActor;

class GridTests {
    
    static var testsPassed: Int = 0;
    static var testsFailed: Int = 0;
    
    static function assert(condition: Bool, message: String): Void {
        if (!condition) {
            trace('FAILED: $message');
            testsFailed++;
        } else {
            testsPassed++;
        }
    }
    
    static function assertEquals<T>(expected: T, actual: T, message: String): Void {
        assert(expected == actual, '$message - Expected: $expected, Actual: $actual');
    }
    
    public static function runAll(): Void {
        trace("=== Starting Grid System Tests ===");
        
        testGridInitialization();
        testCellCreation();
        testActorPlacement();
        testActorMovement();
        testCellReservation();
        testMultipleActors();
        testTriggerSystem();
        testMovementDirections();
        testMoveRequestTypes();
        testGridBoundaries();
        testActorPositionTracking();
        testMovementAnimation();
        testCollisionDetection();
        testDelayedTriggers();
        
        trace("\n=== Test Results ===");
        trace('Passed: $testsPassed');
        trace('Failed: $testsFailed');
        trace('Total: ${testsPassed + testsFailed}');
        trace(testsFailed == 0 ? "All tests passed!" : 'Some tests failed.');
    }
    
    public static function testGridInitialization(): Void {
        trace("\n--- Test: Grid Initialization ---");
        
        var grid = new Grid<Dynamic>(10, 8, 32);
        assertEquals(10, grid.width, "Grid width should be 10");
        assertEquals(8, grid.height, "Grid height should be 8");
        assertEquals(32, grid.cellSize, "Cell size should be 32");
        assert(grid.actors != null, "Actors map should be initialized");
    }
    
    public static function testCellCreation(): Void {
        trace("\n--- Test: Cell Creation ---");
        
        var cell = new Cell(5, 3);
        assertEquals(5, cell.x, "Cell x should be 5");
        assertEquals(3, cell.y, "Cell y should be 3");
        
        var translated = cell.translate(2, -1);
        assertEquals(7, translated.x, "Translated cell x should be 7");
        assertEquals(2, translated.y, "Translated cell y should be 2");
        
        // Original cell should be unchanged
        assertEquals(5, cell.x, "Original cell x should still be 5");
        assertEquals(3, cell.y, "Original cell y should still be 3");
    }
    
    public static function testActorPlacement(): Void {
        trace("\n--- Test: Actor Placement ---");
        
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actor = new HeadlessGridActor("actor1");
        var cell = new Cell(3, 4);
        
        var placed = grid.placeActor(actor, cell);
        assert(placed == true, "Actor should be placed successfully");
        
        var pos = grid.getActorPos(actor);
        assert(pos != null, "Actor position should not be null");
        assertEquals(3, pos.x, "Actor x position should be 3");
        assertEquals(4, pos.y, "Actor y position should be 4");
        
        // Test placing same actor in different position 
        var newCell = new Cell(5, 6);
        placed = grid.placeActor(actor, newCell);
        assert(placed == true, "Actor should be moved to new position");
        
        pos = grid.getActorPos(actor);
        assertEquals(5, pos.x, "Actor x position should be updated to 5");
        assertEquals(6, pos.y, "Actor y position should be updated to 6");
    }
    
    public static function testActorMovement(): Void {
        trace("\n--- Test: Actor Movement ---");
        
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actor = new HeadlessGridActor("mover1");
        var startCell = new Cell(5, 5);
        
        grid.placeActor(actor, startCell);
        @:privateAccess actor.mover.origin = startCell;
        
        // Request move right
        actor.getDriver().requestMove(Right);
        
        // Simulate update cycle
        actor.mover.update(grid, 0.016); // First frame starts movement
        
        // Verify movement state
        var newPos = grid.getActorPos(actor);
        assertEquals(5, newPos.x, "Actor should still be at original x during movement");
        assertEquals(5, newPos.y, "Actor should still be at original y during movement");
        
        // Complete movement
        for (i in 0...100) {
            actor.mover.update(grid, 0.016);
        }
        
        actor.getDriver().clearRequest();
        
        // Check final position
        newPos = grid.getActorPos(actor);
        assertEquals(6, newPos.x, "Actor should have moved right to x=6");
        assertEquals(5, newPos.y, "Actor y should remain at 5");
    }
    
    public static function testCellReservation(): Void {
        trace("\n--- Test: Cell Reservation ---");
        
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actor1 = new HeadlessGridActor("reserve1");
        var actor2 = new HeadlessGridActor("reserve2");
        
        var cell = new Cell(2, 2);
        
        // Reserve cell for actor1
        grid.reserve(cell, actor1);
        
        // Try to place actor2 on reserved cell
        var placed = grid.placeActor(actor2, cell);
        assert(placed == false, "Should not place actor2 on reserved cell");
        
        // Place actor1 on reserved cell should work
        placed = grid.placeActor(actor1, cell);
        assert(placed == true, "Should place actor1 on its reserved cell");
        
        // Release the cell
        grid.release(cell);
        
        // Now actor2 should be able to be placed
        placed = grid.placeActor(actor2, cell);
        assert(placed == true, "Should place actor2 after cell is released");
    }
    
    public static function testMultipleActors(): Void {
        trace("\n--- Test: Multiple Actors ---");
        
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actors = [];
        
        // Create and place 5 actors
        for (i in 0...5) {
            var actor = new HeadlessGridActor('multi_${i}');
            actors.push(actor);
            grid.placeActor(actor, new Cell(i, i));
        }
        
        // Verify all actors are placed correctly
        for (i in 0...5) {
            var pos = grid.getActorPos(actors[i]);
            assertEquals(i, pos.x, 'Actor $i x position');
            assertEquals(i, pos.y, 'Actor $i y position');
        }
        
        // Test simultaneous movement (non-conflicting)
        for (i in 0...3) {
            @:privateAccess actors[i].mover.origin = new Cell(i, i);
            actors[i].getDriver().requestMove(Down);
        }
        
        // Update all actors
        for (i in 0...100) {
            for (actor in actors) {
                actor.mover.update(grid, 0.016);
            }
        }
        
        // Clear requests
        for (actor in actors) {
            actor.getDriver().clearRequest();
        }
        
        // Check positions
        for (i in 0...3) {
            var pos = grid.getActorPos(actors[i]);
            assertEquals(i, pos.x, 'Actor $i should remain at x=$i');
            assertEquals(i + 1, pos.y, 'Actor $i should have moved down to y=${i+1}');
        }
    }
    
    public static function testTriggerSystem(): Void {
        trace("\n--- Test: Trigger System ---");
        
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actor = new TestableHeadlessActor("trigger_test", true);
        
        // Create blocking trigger
        var blockingTrigger = new TestBlockingTrigger(true);
        var targetCell = new Cell(5, 5);
        
        // Set up trigger on cell
        var cellInfo = grid.getCellAt(targetCell);
        if (cellInfo == null) {
            cellInfo = new CellInfo<Dynamic>(null);
            @:privateAccess grid.cells.add(targetCell.x, targetCell.y, cellInfo);
        }
        cellInfo.trigger = blockingTrigger;
        
        // Place actor next to trigger
        var startCell = new Cell(4, 5);
        grid.placeActor(actor, startCell);
        @:privateAccess actor.mover.origin = startCell;
        
        // Try to move into trigger cell
        actor.getDriver().requestMove(Right);
        actor.mover.update(grid, 0.016);
        
        // Should be blocked
        var pos = grid.getActorPos(actor);
        assertEquals(4, pos.x, "Actor should be blocked at x=4");
        assertEquals(1, blockingTrigger.tryEnterCount, "Trigger should have been checked");
        
        // Make trigger non-blocking
        blockingTrigger.blockEnter = false;
        
        // Clear previous request first
        actor.getDriver().clearRequest();
        
        // Try again
        actor.getDriver().requestMove(Right);
        actor.mover.update(grid, 0.016);
        
        // Should start moving
        for (i in 0...100) {
            actor.mover.update(grid, 0.016);
        }
        
        actor.getDriver().clearRequest();
        
        pos = grid.getActorPos(actor);
        assertEquals(5, pos.x, "Actor should have moved to x=5");
        // Note: The trigger may be checked multiple times during movement state transitions
        assert(blockingTrigger.tryEnterCount >= 2, "Trigger should have been checked at least twice");
        assertEquals(1, blockingTrigger.enteredCount, "Trigger entered event should fire");
    }
    
    public static function testMovementDirections(): Void {
        trace("\n--- Test: Movement Directions ---");
        
        // Test direction properties
        assertEquals(0, MoveDirection.Up.dx, "Up dx should be 0");
        assertEquals(-1, MoveDirection.Up.dy, "Up dy should be -1");
        
        assertEquals(0, MoveDirection.Down.dx, "Down dx should be 0");
        assertEquals(1, MoveDirection.Down.dy, "Down dy should be 1");
        
        assertEquals(-1, MoveDirection.Left.dx, "Left dx should be -1");
        assertEquals(0, MoveDirection.Left.dy, "Left dy should be 0");
        
        assertEquals(1, MoveDirection.Right.dx, "Right dx should be 1");
        assertEquals(0, MoveDirection.Right.dy, "Right dy should be 0");
        
        // Test movement in all directions
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actor = new TestableHeadlessActor("dir_test", true);
        var center = new Cell(5, 5);
        
        grid.placeActor(actor, center);
        
        var directions = [Up, Down, Left, Right];
        var expectedPositions = [
            {x: 5, y: 4}, // Up
            {x: 5, y: 6}, // Down  
            {x: 4, y: 5}, // Left
            {x: 6, y: 5}  // Right
        ];
        
        for (i in 0...directions.length) {
            // Reset position
            grid.placeActor(actor, center);
            @:privateAccess actor.mover.origin = center;
            @:privateAccess actor.mover.state = Idle;
            
            // Clear any previous requests
            actor.getDriver().clearRequest();
            
            // Move in direction
            actor.getDriver().requestMove(directions[i]);
            
            // First update to start movement
            actor.mover.update(grid, 0.016);
            
            for (j in 1...100) {
                actor.mover.update(grid, 0.016);
            }
            
            actor.getDriver().clearRequest();
            
            var pos = grid.getActorPos(actor);
            assertEquals(expectedPositions[i].x, pos.x, 'Movement ${directions[i]} (index $i) x position');
            assertEquals(expectedPositions[i].y, pos.y, 'Movement ${directions[i]} (index $i) y position');
        }
    }
    
    public static function testMoveRequestTypes(): Void {
        trace("\n--- Test: Move Request Types ---");
        
        var driver = new HeadlessGridDriver();
        
        // Test None state
        assertEquals(MoveRequest.None, driver.currentMoveRequest(), "Initial state should be None");
        
        // Test Walk request
        driver.requestMove(Up);
        var request = driver.currentMoveRequest();
        var isWalk = switch(request) {
            case Walk(_): true;
            default: false;
        }
        assert(isWalk, "Should be Walk request");
        
        // Test Stand request
        driver.requestStand(Left);
        request = driver.currentMoveRequest();
        var isStand = switch(request) {
            case Stand(_): true;
            default: false;
        }
        assert(isStand, "Should be Stand request");
        
        // Test clear
        driver.clearRequest();
        assertEquals(MoveRequest.None, driver.currentMoveRequest(), "Should be None after clear");
    }
    
    public static function testGridBoundaries(): Void {
        trace("\n--- Test: Grid Boundaries ---");
        
        var grid = new Grid<Dynamic>(5, 5, 32);
        var actor = new TestableHeadlessActor("boundary_test", true); // Use boundary checking
        
        // Place at edges and try to move out of bounds
        var testCases = [
            {start: new Cell(0, 2), dir: Left, desc: "left boundary"},
            {start: new Cell(4, 2), dir: Right, desc: "right boundary"},
            {start: new Cell(2, 0), dir: Up, desc: "top boundary"},
            {start: new Cell(2, 4), dir: Down, desc: "bottom boundary"}
        ];
        
        for (test in testCases) {
            grid.placeActor(actor, test.start);
            @:privateAccess actor.mover.origin = test.start;
            
            actor.getDriver().requestMove(test.dir);
            
            // Update multiple times to ensure no movement
            for (i in 0...10) {
                actor.mover.update(grid, 0.016);
            }
            
            var pos = grid.getActorPos(actor);
            assertEquals(test.start.x, pos.x, 'Should not move past ${test.desc} - x');
            assertEquals(test.start.y, pos.y, 'Should not move past ${test.desc} - y');
            
            actor.getDriver().clearRequest();
        }
    }
    
    public static function testActorPositionTracking(): Void {
        trace("\n--- Test: Actor Position Tracking ---");
        
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actor = new HeadlessGridActor("pos_track");
        
        // Test updateSpritePosition is called correctly
        grid.placeActor(actor, new Cell(0, 0));
        @:privateAccess actor.mover.origin = new Cell(0, 0);
        
        actor.mover.updateSpritePosition(grid, new Cell(0, 0), new Cell(1, 0), 0.5);
        
        // Check interpolated position
        assertEquals(16, actor.x, "X should be interpolated to 16 (halfway between 0 and 32)");
        assertEquals(0, actor.y, "Y should remain 0");
        
        // Full movement
        actor.mover.updateSpritePosition(grid, new Cell(0, 0), new Cell(1, 0), 1.0);
        assertEquals(32, actor.x, "X should be at full cell size (32)");
        assertEquals(0, actor.y, "Y should remain 0");
    }
    
    public static function testMovementAnimation(): Void {
        trace("\n--- Test: Movement Animation ---");
        
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actor = new HeadlessGridActor("anim_test");
        var animator = @:privateAccess cast(actor.mover.animator, HeadlessGridAnimator);
        
        grid.placeActor(actor, new Cell(5, 5));
        @:privateAccess actor.mover.origin = new Cell(5, 5);
        
        // Test idle animation
        assertEquals("idle", animator.lastPlayedAnimation, "Should start with idle animation");
        
        // Start movement
        actor.getDriver().requestMove(Right);
        actor.mover.update(grid, 0.016);
        
        // Check walk animation
        assertEquals("walk", animator.lastPlayedAnimation, "Should play walk animation");
        assertEquals(Right, animator.lastDirection, "Should store direction");
        
        var movementComplete = false;
        var updateCount = 0;
        while (!movementComplete && updateCount < 100) {
            actor.mover.update(grid, 0.016);
            var state = @:privateAccess actor.mover.state;
            if (state.match(Idle)) {
                movementComplete = true;
            }
            updateCount++;
        }
        
        // Check if actor has moved exactly one cell
        var finalPos = grid.getActorPos(actor);
        assertEquals(6, finalPos.x, "Actor should have moved one cell right");
        assertEquals(5, finalPos.y, "Actor y should remain the same");
        
        // Now clear the request to prevent further movement
        actor.getDriver().clearRequest();
        
        // Should return to idle
        assertEquals("idle", animator.lastPlayedAnimation, "Should return to idle after movement");
    }
    
    public static function testCollisionDetection(): Void {
        trace("\n--- Test: Collision Detection ---");
        
        var grid = new Grid<Dynamic>(5, 5, 32);
        var actor1 = new TestableHeadlessActor("collision1", true);
        var actor2 = new TestableHeadlessActor("collision2", true);
        
        // Place actors next to each other
        grid.placeActor(actor1, new Cell(2, 2));
        grid.placeActor(actor2, new Cell(3, 2));
        @:privateAccess actor1.mover.origin = new Cell(2, 2);
        @:privateAccess actor2.mover.origin = new Cell(3, 2);
        
        // Try to move actor1 into actor2's position
        actor1.getDriver().requestMove(Right);
        
        for (i in 0...50) {
            actor1.mover.update(grid, 0.016);
        }
        
        var pos1 = grid.getActorPos(actor1);
        assertEquals(2, pos1.x, "Actor1 should be blocked by actor2");
        assertEquals(2, pos1.y, "Actor1 y should remain unchanged");
        
        // Try to move both actors in opposite directions (they should swap)
        actor1.getDriver().clearRequest();
        actor2.getDriver().requestMove(Left);
        
        // Update actor2 first - should be blocked
        for (i in 0...10) {
            actor2.mover.update(grid, 0.016);
        }
        
        var pos2 = grid.getActorPos(actor2);
        assertEquals(3, pos2.x, "Actor2 should be blocked by actor1");
        
        // Now move actor1 away
        actor1.getDriver().requestMove(Down);
        
        for (i in 0...100) {
            actor1.mover.update(grid, 0.016);
        }
        
        pos1 = grid.getActorPos(actor1);
        assertEquals(2, pos1.x, "Actor1 x should remain 2");
        assertEquals(3, pos1.y, "Actor1 should have moved down");
        
        // Now actor2 should be able to move left
        for (i in 0...100) {
            actor2.mover.update(grid, 0.016);
        }
        
        pos2 = grid.getActorPos(actor2);
        assertEquals(2, pos2.x, "Actor2 should have moved left");
        assertEquals(2, pos2.y, "Actor2 y should remain 2");
    }
    
    public static function testDelayedTriggers(): Void {
        trace("\n--- Test: Delayed Triggers ---");
        
        var grid = new Grid<Dynamic>(10, 10, 32);
        var actor = new TestableHeadlessActor("delayed_trigger_test", true);
        
        // Create delayed trigger
        var delayedTrigger = new TestDelayedTrigger(5);
        var targetCell = new Cell(5, 5);
        
        // Set up trigger on cell
        var cellInfo = grid.getCellAt(targetCell);
        if (cellInfo == null) {
            cellInfo = new CellInfo<Dynamic>(null);
            @:privateAccess grid.cells.add(targetCell.x, targetCell.y, cellInfo);
        }
        cellInfo.trigger = delayedTrigger;
        
        // Place actor next to trigger
        var startCell = new Cell(4, 5);
        grid.placeActor(actor, startCell);
        @:privateAccess actor.mover.origin = startCell;
        
        // Try to move into trigger cell
        actor.getDriver().requestMove(Right);
        actor.mover.update(grid, 0.016);
        
        // Should be waiting
        var pos = grid.getActorPos(actor);
        assertEquals(4, pos.x, "Actor should be waiting at x=4");
        
        // Update trigger delay
        for (i in 0...4) {
            delayedTrigger.update();
            actor.mover.update(grid, 0.016);
            pos = grid.getActorPos(actor);
            assertEquals(4, pos.x, 'Actor should still be waiting at frame $i');
        }
        
        // Final update should resolve the trigger
        delayedTrigger.update();
        
        // Now actor should move
        for (i in 0...100) {
            actor.mover.update(grid, 0.016);
        }
        
        pos = grid.getActorPos(actor);
        assertEquals(5, pos.x, "Actor should have moved to x=5 after delay");
    }
}