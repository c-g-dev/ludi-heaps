package grid;

import ludi.heaps.grid.Trigger.ITrigger;
import ludi.heaps.grid.Trigger.TriggerEvent;
import ludi.heaps.grid.Trigger.TriggerFuture;
import ludi.heaps.grid.Trigger.TriggerArg;
import heaps.coroutine.Future;

class TestBlockingTrigger implements ITrigger {
    public var blockEnter: Bool = true;
    public var enteredCount: Int = 0;
    public var leftCount: Int = 0;
    public var tryEnterCount: Int = 0;
    
    public function new(blockEnter: Bool = true) {
        this.blockEnter = blockEnter;
    }
    
    public function onEvent<Req, Res>(event: TriggerEvent<Req, Res>, args: Req): TriggerFuture<Res> {
        switch (event) {
            case TryEnter:
                tryEnterCount++;
                var future = new TriggerFuture(!blockEnter);
                // For immediate results, the future will be checked via immediateData
                return cast future;
                
            case Entered:
                enteredCount++;
                var future = new TriggerFuture(cast null);
                return cast future;
                
            case Left:
                leftCount++;
                var future = new TriggerFuture(cast null);
                return cast future;
                
            default:
                var future = new TriggerFuture(cast null);
                return cast future;
        }
    }
}

class TestDelayedTrigger implements ITrigger {
    public var delayFrames: Int = 0;
    public var currentDelay: Int = 0;
    public var pendingFuture: TriggerFuture<Bool> = null;
    
    public function new(delayFrames: Int = 5) {
        this.delayFrames = delayFrames;
    }
    
    public function onEvent<Req, Res>(event: TriggerEvent<Req, Res>, args: Req): TriggerFuture<Res> {
        switch (event) {
            case TryEnter:
                var future = new TriggerFuture(true);
                pendingFuture = cast future;
                currentDelay = delayFrames;
                return cast future;
                
            default:
                var future = new TriggerFuture(cast null);
                return cast future;
        }
    }
    
    public function update(): Void {
        if (pendingFuture != null && currentDelay > 0) {
            currentDelay--;
            if (currentDelay == 0) {
                // For testing purposes, we'll just null out the future
                // In a real scenario, the mover checks immediateData
                pendingFuture = null;
            }
        }
    }
} 