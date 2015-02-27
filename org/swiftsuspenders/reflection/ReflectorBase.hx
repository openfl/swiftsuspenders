/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection;
import org.swiftsuspenders.utils.CallProxy;

//import flash.utils.Proxy;
//import flash.utils.getDefinitionByName;

@:keepSub
class ReflectorBase
{
	//----------------------              Public Properties             ----------------------//

	//----------------------               Public Methods               ----------------------//
	public function new()
	{
	}

	public function getClass(value:Dynamic):Class<Dynamic>
	{
		/*
		 There are several types for which the 'constructor' property doesn't work:
		 - instances of Proxy, Xml and XMLList throw exceptions when trying to access 'constructor'
		 - instances of Vector, always returns Array<Dynamic> as their constructor except numeric vectors
		 - for numeric vectors 'value is Array<Dynamic>' wont work, but 'value.constructor' will return correct result
		 - Int and UInt return Float as their constructor
		 For these, we have to fall back to more verbose ways of getting the constructor.
		 */
		// FIX (add XMLList, Float)
		/*if (Std.is(value, Proxy))
		{
			return Proxy;
		}*/
		/*else if (Std.is(value, Float))
		{
			return Float;
		}*/
		/*else */if (Std.is(value, Xml))
		{
			return Xml;
		}
		else if (Std.is(value, Array))
		{
			return Array;
		}
		
		/*if (Std.is(value, Proxy) || Std.is(value, Float) || Std.is(value, Xml) || Std.is(value, XMLList) || Std.is(value, Array))
		{
			var classReference = Type.resolveClass("flash.display.Sprite");
			var instance = Type.createEmptyInstance(classReference);
			
			return cast(getDefinitionByName(CallProxy.replaceClassName(value)), Class<Dynamic>);
			
			//return cast(getDefinitionByName(CallProxy.replaceClassName(value)), Class<Dynamic>);
		}*/
		
		
		
		/*#if js
			return untyped __typeof__(value);
		#else */
			return value.constructor;
		//#end
	}

	public function getFQCN(value :Dynamic, replaceColons:Bool = false):String
	{
		var fqcn:String;
		if (Std.is(value, String))
		{
			fqcn = value;
			// Add colons if missing and desired.
			if (!replaceColons && fqcn.indexOf('::') == -1)
			{
				var lastDotIndex:Int = fqcn.lastIndexOf('.');
				if (lastDotIndex == -1)
				{
					return fqcn;
				}
				return fqcn.substring(0, lastDotIndex) + '::' +
						fqcn.substring(lastDotIndex + 1);
			}
		}
		else
		{
			fqcn = CallProxy.replaceClassName(value);
		}
		
		if (replaceColons == true) {
			return fqcn.split('::').join('.');
		}
		return fqcn;
	}

	//----------------------         Private / Protected Methods        ----------------------//
}