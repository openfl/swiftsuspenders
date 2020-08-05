package polyfill.events;

#if openfl
import openfl.events.EventPhase as OpenFlEventPhase;

typedef EventPhase = OpenFlEventPhase;
#else
@:enum abstract EventPhase(Int) from Int to Int {
	public var AT_TARGET = 2;
	public var BUBBLING_PHASE = 3;
	public var CAPTURING_PHASE = 1;
}
#end
