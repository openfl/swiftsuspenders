/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.typedescriptions;

import org.swiftsuspenders.Injector;

@:keepSub
class InjectionPoint {
	//----------------------              Public Properties             ----------------------//
	public var next:InjectionPoint;
	public var last:InjectionPoint;
	public var injectParameters:Map<Dynamic, Dynamic>;

	//----------------------               Public Methods               ----------------------//
	public function new() {}

	public function applyInjection(target:Dynamic, targetType:Class<Dynamic>, injector:Injector):Void {}
}
