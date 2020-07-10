/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.dependencyproviders;

import org.swiftsuspenders.Injector;

@:keepSub
class ValueProvider implements DependencyProvider {
	//----------------------       Private / Protected Properties       ----------------------//
	private var _value:Dynamic;
	private var _creatingInjector:Injector;

	//----------------------               Public Methods               ----------------------//
	public function new(value:Dynamic, creatingInjector:Injector = null) {
		_value = value;
		_creatingInjector = creatingInjector;
	}

	/**
	 * @inheritDoc
	 *
	 * @return The value provided to this provider's constructor
	 */
	public function apply(targetType:Class<Dynamic>, activeInjector:Injector, injectParameters:Map<Dynamic, Dynamic>):Dynamic {
		return _value;
	}

	public function destroy():Void {
		if (_value != null && _creatingInjector != null && _creatingInjector.hasManagedInstance(_value)) {
			_creatingInjector.destroyInstance(_value);
		}
		_creatingInjector = null;
		_value = null;
	}
}
