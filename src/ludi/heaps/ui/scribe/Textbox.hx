package ui;

import h2d.Object;
import h2d.Text;
import h2d.Interactive;
import h2d.Graphics;
import hxd.Key;
import hxd.Timer;
import heaps.coroutine.Coro;
import heaps.coroutine.Coroutine;
import heaps.coroutine.Coroutine.CoroutineContext;
import heaps.coroutine.Future;

/**
 * Textbox wraps a `Typewriter` and provides:
 * - User advance routing (keyboard/mouse) to `Typewriter.advance()`
 * - Customizable background and waiting cursor
 * - A `play()` API returning a Future that resolves when text is fully typed and advanced out
 * - A plugin system for future extensions (speaker title, portraits, etc.)
 */
class Textbox extends Object {
	public var widthPx:Int;
	public var heightPx:Int;
	public var waitForUserAtEnd:Bool = true; // if true, require user advance even when text fits without scroll

	static inline function imax(a:Int, b:Int):Int return a > b ? a : b;

	// Layout
	public var paddingX:Int = 12;
	public var paddingY:Int = 10;

	// Input
	public var allowMouseAdvance:Bool = true;
	public var advanceKeys:Array<Int> = [ Key.SPACE, Key.ENTER, Key.Z, Key.X ];

	// Components
	var background:Object; // optional, rendered behind content

	var interactive:Interactive; // for mouse/touch advance

	var contentRoot:Object; // holds typewriter and plugins content area

	public var typewriter:Typewriter; // exposed for advanced control

	var waitingCursor:Object; // optional indicator when waiting for advance

	// Plugins
	var plugins:Array<TextboxPlugin> = [];

	// Internal input flags
	var queuedClick:Bool = false;
	var blinkTime:Float = 0.0;
	var acceptingAdvanceInput:Bool = false; // only accept input when waiting
	var isEndConfirmWaiting:Bool = false; // end-of-text confirmation wait state

	public function new(width:Int, height:Int, ?typewriter:Typewriter) {
		super();
		this.widthPx = width;
		this.heightPx = height;

		// Interactive layer to capture clicks/taps
		interactive = new Interactive(width, height, this);
		interactive.onClick = (e) -> {
			if (!allowMouseAdvance) return;
			queuedClick = true; // handle immediately this frame; do not buffer beyond
		};

		contentRoot = new Object(this);

		if (typewriter != null) {
			this.typewriter = typewriter;
			contentRoot.addChild(this.typewriter);
		} else {
			this.typewriter = new Typewriter(imax(0, width - paddingX * 2), imax(0, height - paddingY * 2));
			contentRoot.addChild(this.typewriter);
		}

		this.typewriter.x = paddingX;
		this.typewriter.y = paddingY;

		this.typewriter.onWaitForAdvance = () -> {
			acceptingAdvanceInput = true;
			updateWaitingCursor(true);
			for (p in plugins) p.onWaitingChanged(true);
		};
	}

	// Background customization
	public function setBackground(bg:Object):Void {
		if (background != null) background.remove();
		background = bg;
		if (background != null) {
			addChildAt(background, 0);
			layoutBackground(background);
		}
	}

	function layoutBackground(bg:Object):Void {
		bg.x = 0;
		bg.y = 0;
	}

	// Cursor customization
	public function setWaitingCursor(cursor:Object):Void {
		if (waitingCursor != null) waitingCursor.remove();
		waitingCursor = cursor;
		if (waitingCursor != null) {
			addChild(waitingCursor);
			updateWaitingCursorLayout();
			updateWaitingCursor(typewriter.isWaiting());
		}
	}

	function updateWaitingCursorLayout():Void {
		if (waitingCursor == null) return;
		// bottom-right with a small margin
		var margin = 8;
		waitingCursor.x = widthPx - margin;
		waitingCursor.y = heightPx - margin;
	}

	function updateWaitingCursor(visible:Bool):Void {
		if (waitingCursor == null) return;
		waitingCursor.visible = visible;
	}

	// Plugin system
	public function registerPlugin(plugin:TextboxPlugin):Void {
		if (plugin == null) return;
		plugins.push(plugin);
		plugin.attach(this);
	}

	public function unregisterPlugin(plugin:TextboxPlugin):Void {
		if (plugin == null) return;
		if (plugins.remove(plugin)) plugin.detach();
	}

	// Control APIs
	public function setText(text:String):Void {
		typewriter.setText(text);
		updateWaitingCursor(false);
		for (p in plugins) p.onStartText(text);
	}

	public function appendText(text:String):Void {
		typewriter.appendText(text);
	}

	public function advance():Void {
		// Explicit programmatic advance
		var wasWaiting = typewriter.isWaiting();
		typewriter.advance();
		if (wasWaiting) {
			updateWaitingCursor(false);
			for (p in plugins) p.onWaitingChanged(false);
			for (p in plugins) p.onAdvance();
		}
	}

	public function fillVisibleLines():Void {
		typewriter.fillVisibleLines();
	}

	// Play a single block of text and resolve once it has finished typing and (if needed) has been advanced by the user.
	public function play(text:String):Future {
		return Coro.start((ctx:CoroutineContext) -> {
			Coro.once(() -> {
				// reset transient input state and UI
				queuedClick = false;
				acceptingAdvanceInput = false;
				isEndConfirmWaiting = false;
				updateWaitingCursor(false);
				for (p in plugins) p.onWaitingChanged(false);
				setText(text);
			});

			// If we're currently waiting for an advance (last visible line is full), only advance on explicit signal
			if (typewriter.isWaiting()) {
				acceptingAdvanceInput = true;
				updateWaitingCursor(true);
				for (p in plugins) p.onWaitingChanged(true);
				if (pollSignal()) {
					advance();
				}
				return WaitNextFrame;
			}

			// If we're still typing (not complete), a signal should fast-fill to the next boundary (wait or end)
			if (!typewriter.isComplete()) {
				if (pollSignal()) {
					typewriter.fillVisibleLines();
					if (typewriter.isWaiting()) {
						acceptingAdvanceInput = true;
						updateWaitingCursor(true);
						for (p in plugins) p.onWaitingChanged(true);
					} else if (typewriter.isComplete()) {
						if (waitForUserAtEnd) {
							acceptingAdvanceInput = true;
							isEndConfirmWaiting = true;
							updateWaitingCursor(true);
							for (p in plugins) p.onWaitingChanged(true);
						} else {
							return Stop;
						}
					}
				}
				return WaitNextFrame;
			}

			// Typing is complete and we're not waiting to scroll; optionally wait for user confirmation to finish
			if (typewriter.isComplete()) {
				if (waitForUserAtEnd) {
					acceptingAdvanceInput = true;
					isEndConfirmWaiting = true;
					updateWaitingCursor(true);
					for (p in plugins) p.onWaitingChanged(true);
					if (pollSignal()) {
						updateWaitingCursor(false);
						for (p in plugins) p.onWaitingChanged(false);
						acceptingAdvanceInput = false;
						isEndConfirmWaiting = false;
						return Stop;
					}
					return WaitNextFrame;
				} else {
					return Stop;
				}
			}

			return WaitNextFrame;
		}).future();
	}

	function pollSignal():Bool {
		var pressed = false;
		if (queuedClick) pressed = true;
		if (!pressed) {
			for (k in advanceKeys) {
				if (Key.isPressed(k)) { pressed = true; break; }
			}
		}
		if (pressed) queuedClick = false; // consume one-shot
		return pressed;
	}

	override function sync(ctx:h2d.RenderContext) {
		super.sync(ctx);
 
 		// Keep interactive hitbox sized and positioned
 		interactive.width = widthPx;
 		interactive.height = heightPx;
 		interactive.x = 0;
 		interactive.y = 0;
 
 		updateWaitingCursorLayout();
 
		// Input is handled in play(); here we only update visuals and plugins
 
		// Subtle blink for waiting cursor
		if (waitingCursor != null && waitingCursor.visible) {
			blinkTime += Timer.dt;
			var a = 0.5 + 0.5 * Math.sin(blinkTime * Math.PI * 2);
			waitingCursor.alpha = a;
		}
 
 		for (p in plugins) p.onUpdate(ctx.elapsedTime);
 	}
}

// Plugin interface for extensibility (titles, portraits, etc.)
interface TextboxPlugin {
 	function attach(tb:Textbox):Void;
 	function detach():Void;
 	function onStartText(text:String):Void;
 	function onWaitingChanged(waiting:Bool):Void;
 	function onAdvance():Void;
 	function onUpdate(dt:Float):Void;
}

// (reserved for future helpers)

