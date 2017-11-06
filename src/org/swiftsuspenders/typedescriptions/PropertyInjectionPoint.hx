/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.typedescriptions;



import org.swiftsuspenders.Injector;
import org.swiftsuspenders.errors.InjectorMissingMappingError;
import org.swiftsuspenders.dependencyproviders.DependencyProvider;
import org.swiftsuspenders.utils.CallProxy;

@:keepSub
class PropertyInjectionPoint extends InjectionPoint
{
	//----------------------       Private / Protected Properties       ----------------------//
	private var _propertyName:String;
	private var _mappingId:String;
	private var _optional:Bool;
	
	//----------------------               Public Methods               ----------------------//
	public function new(mappingId:String, propertyName:String, optional:Bool, injectParameters:Map<Dynamic,Dynamic>)
	{
		_propertyName = propertyName;
		_mappingId = mappingId;
		_optional = optional;
		this.injectParameters = injectParameters;
		super();
	}
	
	override public function applyInjection(target:Dynamic, targetType:Class<Dynamic>, injector:Injector):Void
	{
		var provider:DependencyProvider = injector.getProvider(_mappingId);
		if (provider == null)
		{
			if (_optional)
			{
				return;
			}
			
			var targetStr:String;
			#if js
				targetStr = Type.getClassName(Type.getClass(target)); // Calling toString in JS can go recursive
			#else
				targetStr = Std.string(target);
			#end
			
			
			throw(new InjectorMissingMappingError('Injector is missing a mapping to handle injection into property "' + _propertyName + '" of object "' + target + '" with type "' +Type.getClassName(targetType) +'". Target dependency: "' + _mappingId + '"'));
		}
		Reflect.setProperty(target, _propertyName, provider.apply(targetType, injector, injectParameters));
	}
}