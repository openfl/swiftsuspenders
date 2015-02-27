/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.errors;

import openfl.errors.Error;

@:keepSub
class InjectorError extends Error
{
	public function new(message:Dynamic="", id:Dynamic=0)
	{
		super(message, id);
	}
}