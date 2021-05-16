package org.swiftsuspenders.utils;

/**
 * ...
 * @author P.J.Shand
 */
class MaxInt {
	public static var INT_MAX(get, never):Int;

	#if flash
	static inline function get_INT_MAX():Int
		return untyped __global__['int'].MAX_VALUE;
	#elseif js
	static inline function get_INT_MAX():Int
		return untyped js.Syntax.code('Number.MAX_VALUE');
	#elseif cs
	static inline function get_INT_MAX():Int
		return untyped __cs__('int.MaxValue');
	#elseif java
	static inline function get_INT_MAX():Int
		return untyped __java__('Integer.MAX_VALUE');
	#elseif cpp
	static inline function get_INT_MAX():Int
		return untyped __cpp__('INT_MAX');
	#elseif hl
	static inline function get_INT_MAX():Int
		return 2147483647;
	#elseif python
	static inline function get_INT_MAX():Int
		return PythonSysAdapter.maxint;
	#elseif php
	static inline function get_INT_MAX():Int
		return untyped __php__('PHP_INT_MAX');
	#else
	static inline function get_INT_MAX():Int
		return 2 ^ 31 - 1;
	#end
}
