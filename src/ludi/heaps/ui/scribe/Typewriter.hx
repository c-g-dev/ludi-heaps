package ui;


import h2d.Object;
import h2d.Text;
import h2d.Font;
import hxd.Timer;

// Tokenization
private enum Token { Word(s:String); Space(n:Int); Newline; }

/**
 * Typewriter that renders text one letter at a time, wrapping words before they start,
 * honoring newlines, and managing a fixed number of visible lines within a width/height box.
 * When the last visible line is full, the widget waits for `advance()` to slide lines up,
 * freeing a new last line before continuing.
 *
 * Use `fillVisibleLines()` to immediately fill the remaining visible space.
 */
class Typewriter extends Object {
    // Public configuration
    public var widthPx:Int;
    public var heightPx:Int;
    public var font:Font;
    public var textScale:Float;
    public var textColor:Int;
    public var lineSpacingMultiplier:Float;
    public var letterDelaySeconds:Float; // delay between letters while auto-typing
    public var scrollDurationSeconds:Float; // duration of the slide-up animation

    // Callbacks
    public var onWaitForAdvance:Void->Void; // called when the writer needs advance() to proceed
    public var onComplete:Void->Void; // called when all text has been fully written

    // Internal layout and state
    var lineHeight:Float;
    var maxLines:Int;

    var lineRoots:Array<Object> = [];
    var lineCursorX:Array<Float> = [];

    var measureNode:Text; // used only for measuring widths

    // Typing state
    var tokens:Array<Token> = [];
    var tokenIndex:Int = 0;
    var pendingSpaces:Int = 0; // spaces queued before the next word (ignored at start of line)
    var currentWord:String = null; // word currently being emitted (after pre-check)
    var currentWordPos:Int = 0;
    var splittingLongWord:Bool = false; // if true, emit chars even if the word doesn't fit on a clean line

    var currentLine:Int = 0;
    var waitingForAdvance:Bool = false;
    var typingEnabled:Bool = true;
    var accum:Float = 0.0;

    // Scroll animation state
    var animScrolling:Bool = false;
    var animT:Float = 0.0;

    public function new(width:Int, height:Int, ?font:Font, ?textScale:Float, ?textColor:Int, ?lineSpacingMultiplier:Float, ?letterDelaySeconds:Float, ?scrollDurationSeconds:Float) {
        super();
        this.widthPx = width;
        this.heightPx = height;
        this.font = font != null ? font : hxd.Res.fonts.plex_mono_64.toFont();
        this.textScale = textScale != null ? textScale : 0.30;
        this.textColor = textColor != null ? textColor : 0xFFFFFF;
        this.lineSpacingMultiplier = lineSpacingMultiplier != null ? lineSpacingMultiplier : 1.35;
        this.letterDelaySeconds = letterDelaySeconds != null ? letterDelaySeconds : 0.035;
        this.scrollDurationSeconds = scrollDurationSeconds != null ? scrollDurationSeconds : 0.25;

        this.measureNode = new Text(this.font);
        this.measureNode.scaleX = 1.0; // use raw textWidth then multiply by textScale
        this.measureNode.scaleY = 1.0;

        recomputeLayout();
    }

    // Provide or replace the entire text buffer to type.
    public function setText(text:String):Void {
        clearAllLines();
        tokens = tokenize(text);
        tokenIndex = 0;
        pendingSpaces = 0;
        currentWord = null;
        currentWordPos = 0;
        splittingLongWord = false;
        currentLine = 0;
        waitingForAdvance = false;
        typingEnabled = true;
        animScrolling = false;
        animT = 0.0;
    }

    // Append additional text to the buffer.
    public function appendText(text:String):Void {
        var more = tokenize(text);
        for (t in more) tokens.push(t);
    }

    // Immediately fill the currently visible lines (consumes tokens until reaching the need-to-advance boundary or done).
    public function fillVisibleLines():Void {
        if (animScrolling || waitingForAdvance) return;
        var guard = 0;
        while (guard++ < 100000) {
            if (waitingForAdvance) return;
            if (!stepType(true)) break; // false means no more progress possible now
        }
    }

    // Signal that we can scroll up to free a new line. Triggers slide animation if needed.
    public function advance():Void {
        if (!waitingForAdvance || animScrolling) return;
        waitingForAdvance = false;
        startScrollAnimation();
    }

    public inline function isWaiting():Bool return waitingForAdvance;
    public inline function isComplete():Bool return tokenIndex >= tokens.length && currentWord == null && pendingSpaces == 0;

    // Auto-typing tick
    override function sync(ctx:h2d.RenderContext) {
        super.sync(ctx);

        if (animScrolling) {
            updateScrollAnimation();
            return;
        }

        if (!typingEnabled || waitingForAdvance) return;

        accum += Timer.dt;
        if (accum < letterDelaySeconds) return;
        accum -= letterDelaySeconds;

        var madeProgress = stepType(false);
        if (!madeProgress) {
            if (isComplete() && onComplete != null) onComplete();
        }
    }

    // Core typing step. If fast=true, emit as much as possible in one go until boundary; otherwise emit one character.
    function stepType(fast:Bool):Bool {
        var emitted:Bool = false;

        // Emit pending spaces first
        if (pendingSpaces > 0 && lineCursorX[currentLine] > 0) {
            while (pendingSpaces > 0) {
                var sWidth = measureString(" ");
                if (!ensureRoomOrWait(sWidth)) return emitted; // might toggle waiting
                emitChar(" ", sWidth);
                pendingSpaces--;
                emitted = true;
                if (!fast) return true;
            }
        } else if (pendingSpaces > 0 && lineCursorX[currentLine] == 0) {
            // skip leading spaces at start of line
            pendingSpaces = 0;
        }

        // If currently in a word, continue emitting it
        if (currentWord != null) {
            while (currentWordPos < currentWord.length) {
                var ch = currentWord.charAt(currentWordPos);
                var cw = measureString(ch);
                if (!splittingLongWord) {
                    // We pre-validated fit for the full word; only remaining risk is numerical drift
                    if (!ensureRoomOrWait(cw)) return emitted;
                } else {
                    // Split long word: wrap as soon as the next char would not fit
                    if (!hasRoom(cw)) {
                        if (!gotoNextLineOrWait()) return emitted;
                    }
                }
                emitChar(ch, cw);
                currentWordPos++;
                emitted = true;
                if (!fast) return true;
            }
            // Finished current word
            currentWord = null;
            currentWordPos = 0;
            splittingLongWord = false;
        }

        // Consume tokens until we either schedule a word to emit or hit boundaries
        while (tokenIndex < tokens.length && currentWord == null && !waitingForAdvance) {
            switch (tokens[tokenIndex]) {
                case Newline:
                    tokenIndex++;
                    if (!gotoNextLineOrWait()) return emitted; // may set waiting
                    emitted = true;
                    if (!fast) return true;
                    continue;
                case Space(n):
                    tokenIndex++;
                    pendingSpaces += n;
                    continue;
                case Word(w):
                    // Pre-calc widths for wrap decision
                    var preSpaceWidth = (lineCursorX[currentLine] > 0) ? measureSpaces(pendingSpaces) : 0.0;
                    var wordWidth = measureString(w);
                    var totalNeeded = preSpaceWidth + wordWidth;

                    if (totalNeeded <= remainingWidth()) {
                        // Commit to emitting spaces (if any) and this word
                        // Spaces are emitted above; just set the current word and proceed
                        tokenIndex++;
                        currentWord = w;
                        currentWordPos = 0;
                        splittingLongWord = false;
                        if (!fast) return true; // defer emission to next tick for per-letter effect
                    } else {
                        // Need to wrap before starting this word
                        if (lineCursorX[currentLine] == 0) {
                            // Word alone is too long for the line; split by chars
                            tokenIndex++;
                            currentWord = w;
                            currentWordPos = 0;
                            splittingLongWord = true;
                            if (!fast) return true;
                        } else {
                            if (!gotoNextLineOrWait()) return emitted; // may set waiting
                            emitted = true;
                            if (!fast) return true;
                        }
                    }
            }
        }

        return emitted;
    }

    // Layout and measurement helpers
    function recomputeLayout():Void {
        lineHeight = font.lineHeight * textScale * lineSpacingMultiplier;
        maxLines = Std.int(heightPx / lineHeight);
        if (maxLines < 1) maxLines = 1;

        // Initialize line roots
        lineRoots = [];
        lineCursorX = [];
        for (i in 0...maxLines) {
            var r = new Object(this);
            r.x = 0;
            r.y = Std.int(i * lineHeight);
            lineRoots.push(r);
            lineCursorX.push(0);
        }
    }

    function clearAllLines():Void {
        for (r in lineRoots) {
            r.removeChildren();
        }
        for (i in 0...lineCursorX.length) lineCursorX[i] = 0;
        currentLine = 0;
    }

    inline function measureString(s:String):Float {
        measureNode.text = s;
        return measureNode.textWidth * textScale;
    }

    inline function measureSpaces(n:Int):Float {
        if (n <= 0) return 0.0;
        var b = new StringBuf();
        for (i in 0...n) b.add(" ");
        return measureString(b.toString());
    }

    inline function remainingWidth():Float {
        return widthPx - lineCursorX[currentLine];
    }

    inline function hasRoom(w:Float):Bool {
        return w <= remainingWidth();
    }

    // Ensures there's room for width w on the current line; if not, attempts to go to next line or waits on advance.
    function ensureRoomOrWait(w:Float):Bool {
        if (hasRoom(w)) return true;
        return gotoNextLineOrWait();
    }

    // Move to next line, or if on last line start waiting for advance. Returns true if we have a new line to continue now.
    function gotoNextLineOrWait():Bool {
        if (currentLine < maxLines - 1) {
            currentLine++;
            return true;
        }
        waitingForAdvance = true;
        if (onWaitForAdvance != null) onWaitForAdvance();
        return false;
    }

    function emitChar(ch:String, w:Float):Void {
        var t = new Text(font, lineRoots[currentLine]);
        t.text = ch;
        t.scaleX = textScale;
        t.scaleY = textScale;
        t.textColor = textColor;
        t.x = Std.int(lineCursorX[currentLine]);
        t.y = 0;
        lineCursorX[currentLine] += w;
    }

    // Scrolling animation: slide all lines up by one lineHeight, discard top content, reuse it as a clean last line
    function startScrollAnimation():Void {
        animScrolling = true;
        animT = 0.0;
    }

    function updateScrollAnimation():Void {
        animT += Timer.dt;
        var r = animT / scrollDurationSeconds;
        if (r > 1) r = 1;
        var offset = -lineHeight * r;
        for (i in 0...lineRoots.length) {
            lineRoots[i].y = Std.int(i * lineHeight + offset);
        }
        if (r >= 1) {
            // finalize: shift roots, clear new last
            var first = lineRoots.shift();
            var firstCursor = lineCursorX.shift(); // not needed, just keep arrays in sync
            first.removeChildren();
            first.y = Std.int((maxLines - 1) * lineHeight);
            lineRoots.push(first);
            lineCursorX.push(0);
            // reset exact y positions
            for (i in 0...lineRoots.length) {
                lineRoots[i].y = Std.int(i * lineHeight);
            }
            currentLine = maxLines - 1;
            animScrolling = false;
        }
    }

    static function tokenize(s:String):Array<Token> {
        var out:Array<Token> = [];
        var i = 0;
        var n = s.length;
        while (i < n) {
            var c = s.charAt(i);
            if (c == "\n") {
                out.push(Newline);
                i++;
                continue;
            }
            if (c == " ") {
                var start = i;
                while (i < n && s.charAt(i) == " ") i++;
                out.push(Space(i - start));
                continue;
            }
            // word: run of non-space, non-newline characters
            var wStart = i;
            while (i < n) {
                var cc = s.charAt(i);
                if (cc == " " || cc == "\n") break;
                i++;
            }
            if (i > wStart) out.push(Word(s.substr(wStart, i - wStart)));
        }
        return out;
    }
}
