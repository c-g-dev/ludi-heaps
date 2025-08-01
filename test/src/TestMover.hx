import ludi.heaps.grid.Mover.GridActorMover;
import ludi.heaps.grid.Mover.MoveTest;
import ludi.heaps.grid.Grid;
import ludi.heaps.grid.Cell;
import ludi.heaps.grid.Actor.IGridActor;
import ludi.heaps.grid.Driver.IGridActorDriver;
import ludi.heaps.grid.Animator.IGridActorAnimator;
import ludi.heaps.grid.Headless.HeadlessGridActor;
import ludi.heaps.grid.Headless.HeadlessGridAnimator;

class BoundaryCheckingMover extends GridActorMover {
    
    public function new(actor: IGridActor, animator: IGridActorAnimator, driver: IGridActorDriver) {
        super(actor, animator, driver);
    }
    
    override public function testCell(grid: Grid<Dynamic>, x: Int, y: Int): MoveTest {
        // Check grid boundaries
        if (x < 0 || x >= grid.width || y < 0 || y >= grid.height) {
            return MoveTest.Blocked;
        }
        
        // Check for other actors
        var targetCell = new Cell(x, y);
        var cellInfo = grid.getCellAt(targetCell);
        
        if (cellInfo != null) {
            // Check if cell is reserved by another actor
            if (cellInfo.reservedBy != null && cellInfo.reservedBy != actor.uuid) {
                return MoveTest.Blocked;
            }
            
            // Check for triggers
            if (cellInfo.trigger != null) {
                return MoveTest.Trigger(cellInfo.trigger);
            }
        }
        
        // Check if another actor is on the cell
        for (actorInfo in grid.actors) {
            if (actorInfo.actor.uuid != actor.uuid && 
                actorInfo.gridX == x && 
                actorInfo.gridY == y) {
                return MoveTest.Blocked;
            }
        }
        
        return MoveTest.Free;
    }
}

class TestableHeadlessActor extends HeadlessGridActor {
    
    public function new(uuid: String, useBoundaryChecking: Bool = true) {
        super(uuid);
        
        if (useBoundaryChecking) {
            // Replace the mover with boundary-checking version
            var driver = getDriver();
            var animator = @:privateAccess cast(mover.animator, HeadlessGridAnimator);
            this.mover = new BoundaryCheckingMover(this, animator, driver);
        }
    }
} 