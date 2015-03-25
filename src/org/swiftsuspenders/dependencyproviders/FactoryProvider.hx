/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.dependencyproviders;

import org.swiftsuspenders.Injector;

@:keepSub
class FactoryProvider implements DependencyProvider
{
	//----------------------       Private / Protected Properties       ----------------------//
	private var _factoryClass:Class<Dynamic>;

	//----------------------               Public Methods               ----------------------//
	public function new(factoryClass:Class<Dynamic>)
	{
		_factoryClass = factoryClass;
	}

	public function apply(targetType:Class<Dynamic>, activeInjector:Injector, injectParameters:Map<Dynamic,Dynamic>):Dynamic
	{
		var dependencyProvider:DependencyProvider = cast(activeInjector.getInstance(_factoryClass));
		return dependencyProvider.apply(targetType, activeInjector, injectParameters);
	}

	public function destroy():Void
	{
	}
}