/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection;

import flash.utils.Proxy;

class ReflectorBase {
	//----------------------              Public Properties             ----------------------//
	//----------------------               Public Methods               ----------------------//
	public function new() {}

	public function getClass(value:Dynamic):Class<Dynamic> /*
		There are several types for which the 'constructor' property doesn't work:
		- instances of Proxy, XML and XMLList throw exceptions when trying to access 'constructor'
		- instances of Vector, always returns Vector.<*> as their constructor except numeric vectors
		- for numeric vectors 'value is Vector.<*>' wont work, but 'value.constructor' will return correct result
		- int and uint return Number as their constructor
		For these, we have to fall back to more verbose ways of getting the constructor.
	 */
	{
		// if (Std.isOfType(value, Proxy) || Std.isOfType(value, Float) || Std.isOfType(value, FastXML) || Std.isOfType(value, FastXMLList) || Std.isOfType(value, Array/*Vector.<T> call?*/))
		if (Std.isOfType(value, Proxy) || Std.isOfType(value, Float) || Std.isOfType(value, Xml) || Std.isOfType(value, Array)) {
			return Type.resolveClass(Type.getClassName(value));
		}
		return value.constructor;
	}

	public function getFQCN(value:Dynamic, replaceColons:Bool = false):String {
		var fqcn:String;
		if (Std.isOfType(value, String)) {
			fqcn = value;
			// Add colons if missing and desired.
			if (!replaceColons && fqcn.indexOf("::") == -1) {
				var lastDotIndex:Int = fqcn.lastIndexOf(".");
				if (lastDotIndex == -1) {
					return fqcn;
				}
				return fqcn.substring(0, lastDotIndex) + "::" + fqcn.substring(lastDotIndex + 1);
			}
		} else {
			fqcn = Type.getClassName(value);
		}
		return (replaceColons) ? StringTools.replace(fqcn, "::", ".") : fqcn;
	}
}
