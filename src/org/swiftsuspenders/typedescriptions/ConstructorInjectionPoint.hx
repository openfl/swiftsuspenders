/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.typedescriptions;

import org.swiftsuspenders.Injector;
import org.swiftsuspenders.errors.InjectorError;
import org.swiftsuspenders.utils.CallProxy;

@:keepSub
class ConstructorInjectionPoint extends MethodInjectionPoint
{
	//----------------------               Public Methods               ----------------------//
	public function new(parameters:Array<Dynamic>, requiredParameters:UInt, injectParameters:Map<Dynamic,Dynamic>)
	{
		super('ctor', parameters, requiredParameters, false, injectParameters);
	}

	public function createInstance(type:Class<Dynamic>, injector:Injector):Dynamic
	{
		var p:Array<Dynamic> = gatherParameterValues(type, type, injector);
		var result:Dynamic;
		//the only way to implement ctor injections, really!
		
		switch (p.length)
		{
			case 0:result = CallProxy.createInstance( type, [] );
			case 1:result = CallProxy.createInstance( type, [p[0]] );
			case 2:result = CallProxy.createInstance( type, [p[0], p[1]] );
			case 3:result = CallProxy.createInstance( type, [p[0], p[1], p[2]] );
			case 4:result = CallProxy.createInstance( type, [p[0], p[1], p[2], p[3]] );
			case 5:result = CallProxy.createInstance( type, [p[0], p[1], p[2], p[3], p[4]] );
			case 6:result = CallProxy.createInstance( type, [p[0], p[1], p[2], p[3], p[4], p[5]] );
			case 7:result = CallProxy.createInstance( type, [p[0], p[1], p[2], p[3], p[4], p[5], p[6]] );
			case 8:result = CallProxy.createInstance( type, [p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]] );
			case 9:result = CallProxy.createInstance( type, [p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]] );
			case 10:result = CallProxy.createInstance( type, [p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9]] );
			default: throw new InjectorError("The constructor for " + type + " has too many arguments, maximum is 10");
		}
		p = [];
		return result;
	}
}