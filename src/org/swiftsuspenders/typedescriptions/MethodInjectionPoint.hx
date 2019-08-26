/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.typedescriptions;

// import avmplus.getQualifiedClassName;
import org.swiftsuspenders.Injector;
import org.swiftsuspenders.errors.InjectorMissingMappingError;
import org.swiftsuspenders.dependencyproviders.DependencyProvider;
import org.swiftsuspenders.utils.CallProxy;

@:keepSub
class MethodInjectionPoint extends InjectionPoint {
	//----------------------       Private / Protected Properties       ----------------------//
	private var _parameterMappingIDs:Array<String>;
	private var _requiredParameters:Int;

	private var _isOptional:Bool;
	private var _methodName:String;

	//----------------------               Public Methods               ----------------------//
	public function new(methodName:String, parameters:Array<String>, requiredParameters:UInt, isOptional:Bool, injectParameters:Map<Dynamic, Dynamic>) {
		_methodName = methodName;
		_parameterMappingIDs = parameters;
		_requiredParameters = requiredParameters;
		_isOptional = isOptional;
		this.injectParameters = injectParameters;
		super();
	}

	override public function applyInjection(target:Dynamic, targetType:Class<Dynamic>, injector:Injector):Void {
		var p:Array<Dynamic> = gatherParameterValues(target, targetType, injector);

		if (p.length >= _requiredParameters) {
			var func = Reflect.getProperty(target, _methodName);
			if (Reflect.isFunction(func)) {
				Reflect.callMethod(target, func, p);
			}
		}
		p = [];
	}

	//----------------------         Private / Protected Methods        ----------------------//
	private function gatherParameterValues(target:Dynamic, targetType:Class<Dynamic>, injector:Injector):Array<Dynamic> {
		var length:Int = _parameterMappingIDs.length;
		var parameters:Array<Dynamic> = [];
		// CHECK
		// parameters.length = length;

		for (i in 0...length) {
			var parameterMappingId:String = _parameterMappingIDs[i];
			var provider:DependencyProvider = injector.getProvider(parameterMappingId);
			if (provider == null) {
				if (i >= _requiredParameters || _isOptional) {
					break;
				}

				var errorMsg:String = 'Injector is missing a mapping to handle injection into target "';
				errorMsg += target;
				errorMsg += '" of type "';
				errorMsg += Type.getClassName(targetType);
				errorMsg += '". Target dependency: ';
				errorMsg += parameterMappingId;
				errorMsg += ', method: ';
				errorMsg += _methodName;
				errorMsg += ', parameter: ';
				errorMsg += (i + 1);

				throw(new InjectorMissingMappingError(errorMsg));
			}

			parameters[i] = provider.apply(targetType, injector, injectParameters);
		}
		return parameters;
	}
}
