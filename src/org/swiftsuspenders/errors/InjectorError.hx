/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.errors;

#if openfl
import openfl.errors.Error;
#end

@:keepSub
class InjectorError #if openfl extends Error #end
{
	public function new(message:Dynamic="", id:Dynamic=0)
	{
		#if openfl
			super(message, id);
		#else
			trace(["Error: ", message, id]);
		#end
	}
}