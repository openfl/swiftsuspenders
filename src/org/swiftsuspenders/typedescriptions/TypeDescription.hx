/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.typedescriptions;

import org.swiftsuspenders.errors.InjectorError;
import org.swiftsuspenders.utils.CallProxy;

@:keepSub
class TypeDescription {
	//----------------------              Public Properties             ----------------------//
	public var ctor:ConstructorInjectionPoint;
	public var injectionPoints:InjectionPoint;
	public var preDestroyMethods:PreDestroyInjectionPoint;

	//----------------------       Private / Protected Properties       ----------------------//
	private var _postConstructAdded:Bool;

	//----------------------               Public Methods               ----------------------//
	public function new(useDefaultConstructor:Bool = true) {
		if (useDefaultConstructor) {
			ctor = new NoParamsConstructorInjectionPoint();
		}
	}

	public function setConstructor(parameterTypes:Array<Class<Dynamic>>, parameterNames:Array<String> = null, requiredParameters:UInt = 0x3FFFFFFF,
			metadata:Map<Dynamic, Dynamic> = null):TypeDescription {
		var param:Array<String>;
		if (parameterNames != null)
			param = parameterNames;
		else
			param = [];

		ctor = new ConstructorInjectionPoint(createParameterMappings(parameterTypes, param), requiredParameters, metadata);
		return this;
	}

	public function addFieldInjection(fieldName:String, type:Class<Dynamic>, injectionName:String = '', optional:Bool = false,
			metadata:Map<Dynamic, Dynamic> = null):TypeDescription {
		if (_postConstructAdded) {
			throw new InjectorError('Can\'t add injection point after post construct method');
		}
		addInjectionPoint(new PropertyInjectionPoint(Type.getClassName(type) + '|' + injectionName, fieldName, optional, metadata));
		return this;
	}

	public function addMethodInjection(methodName:String, parameterTypes:Array<Class<Dynamic>>, parameterNames:Array<String> = null,
			requiredParameters:UInt = 0x3FFFFFFF, optional:Bool = false, metadata:Map<Dynamic, Dynamic> = null):TypeDescription {
		if (_postConstructAdded) {
			throw new InjectorError('Can\'t add injection point after post construct method');
		}
		var param:Array<String>;
		if (parameterNames != null)
			param = parameterNames;
		else
			param = [];

		addInjectionPoint(new MethodInjectionPoint(methodName, createParameterMappings(parameterTypes, param),
			cast(Math.min(requiredParameters, parameterTypes.length), UInt), optional, metadata));
		return this;
	}

	public function addPostConstructMethod(methodName:String, parameterTypes:Array<Class<Dynamic>>, parameterNames:Array<String> = null,
			requiredParameters:UInt = 0x3FFFFFFF):TypeDescription {
		var param:Array<String>;
		if (parameterNames != null)
			param = parameterNames;
		else
			param = [];

		_postConstructAdded = true;
		addInjectionPoint(new PostConstructInjectionPoint(methodName, createParameterMappings(parameterTypes, param),
			cast(Math.min(requiredParameters, parameterTypes.length), UInt), 0));
		return this;
	}

	public function addPreDestroyMethod(methodName:String, parameterTypes:Array<Class<Dynamic>>, parameterNames:Array<String> = null,
			requiredParameters:UInt = 0x3FFFFFFF):TypeDescription {
		var param:Array<String>;
		if (parameterNames != null)
			param = parameterNames;
		else
			param = [];

		var method:PreDestroyInjectionPoint = new PreDestroyInjectionPoint(methodName, createParameterMappings(parameterTypes, param),
			cast(Math.min(requiredParameters, parameterTypes.length), UInt), 0);
		if (preDestroyMethods != null) {
			preDestroyMethods.last.next = method;
			preDestroyMethods.last = method;
		} else {
			preDestroyMethods = method;
			preDestroyMethods.last = method;
		}
		return this;
	}

	public function addInjectionPoint(injectionPoint:InjectionPoint):Void {
		if (injectionPoints != null) {
			injectionPoints.last.next = injectionPoint;
			injectionPoints.last = injectionPoint;
		} else {
			injectionPoints = injectionPoint;
			injectionPoints.last = injectionPoint;
		}
	}

	//----------------------         Private / Protected Methods        ----------------------//
	private function createParameterMappings(parameterTypes:Array<Class<Dynamic>>, parameterNames:Array<String>):Array<String> {
		var parameters = new Array<String>();
		for (i in 0...parameterTypes.length) {
			parameters[i] = Type.getClassName(parameterTypes[i]) + '|';
			if (parameterNames[i] != null)
				parameters[i] += parameterNames[i];
		}
		return parameters;
	}
}
