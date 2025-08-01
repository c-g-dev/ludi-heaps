# Grid System Test Suite

This test suite validates the programmatic integrity of the grid system in the `/src/ludi/heaps/grid` directory.

## Overview

The test suite uses headless implementations of the grid system components, allowing tests to run without requiring Heaps rendering or visual components.

## Test Coverage

The test suite includes comprehensive tests for:

### Core Grid Functionality
- **Grid Initialization** - Tests grid creation with proper dimensions and cell size
- **Cell Creation** - Tests cell creation and translation operations
- **Actor Placement** - Tests placing and moving actors on the grid
- **Cell Reservation** - Tests cell reservation and release mechanisms

### Movement System
- **Actor Movement** - Tests basic movement from one cell to another
- **Movement Directions** - Tests movement in all four directions (Up, Down, Left, Right)
- **Movement Animation** - Tests animation state transitions during movement
- **Grid Boundaries** - Tests boundary checking to prevent out-of-bounds movement
- **Collision Detection** - Tests actor-to-actor collision prevention

### Advanced Features
- **Multiple Actors** - Tests multiple actors operating simultaneously on the grid
- **Trigger System** - Tests trigger events (TryEnter, Entered, Left)
- **Delayed Triggers** - Tests triggers with delayed responses
- **Move Request Types** - Tests different movement request types (Walk, Stand, None)
- **Actor Position Tracking** - Tests sprite position interpolation during movement

## Running the Tests

To run the test suite:

```bash
cd test
haxe test-simple.hxml
hl test.hl
```

## Test Infrastructure

### Headless Classes

The tests use headless implementations that don't require visual components:

- `HeadlessGridActor` - Implements IGridActor without visual representation
- `HeadlessGridDriver` - Provides movement input for testing
- `HeadlessGridAnimator` - Tracks animation states without actual animations
- `TestableHeadlessActor` - Extended actor with boundary checking
- `BoundaryCheckingMover` - Mover that respects grid boundaries and checks collisions

### Test Triggers

- `TestBlockingTrigger` - A trigger that can block or allow entry
- `TestDelayedTrigger` - A trigger that delays its response by a configurable number of frames

## Test Results

When all tests pass, you should see:
```
=== Test Results ===
Passed: 96
Failed: 0
Total: 96
All tests passed!
```

## Architecture Notes

The grid system uses a component-based architecture where:
- Actors have movers that handle their movement logic
- Movers use drivers for input and animators for visual feedback
- The grid manages cell reservations and actor positions
- Triggers can intercept and modify movement behavior

This test suite ensures all these components work together correctly. 