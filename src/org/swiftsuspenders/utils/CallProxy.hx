package org.swiftsuspenders.utils;

/**
 * ...
 * @author P.J.Shand
 */
@:keepSub
class CallProxy
{

	public function new() 
	{
		
	}
	
	public static function replaceClassName(c:Class<Dynamic>):String
	{
		return Type.getClassName(c);
		/*var className = CallProxy.getClassName(c);
		if (className == null) return className;
		className = className.split("flash.").join("openfl.");
		return className;*/
	}
	
	public static function getClassName(c:Class<Dynamic>):String
	{
		return Type.getClassName(c);
	}
	
	public static function hasField( o:Dynamic, field:String):Bool
	{
		var fields;
		var clazz:Class<Dynamic>;
		if (Std.is(o, Class)) {
			clazz = o;
			fields = Type.getInstanceFields(clazz);
		}
		else {
			fields = Reflect.fields(o);	
		}
		
		for (i in 0...fields.length) 
		{
			if (fields[i] == field) return true;
		}

		#if (js)
			var f:Dynamic = Reflect.getProperty(o, field);
			if (untyped __js__('"undefined" !== typeof f')) return true;
			else return false;
		#elseif (cpp)
			var f:Dynamic = Reflect.getProperty(o, field);
			var isFunction = Reflect.isFunction(f);
			var isObject = Reflect.isObject(f);
			if (isFunction || isObject) return true;
			else return false;
		#else 
			var hasField = Reflect.hasField(o, field);
			return hasField;
		#end
	}
	
	public static function createInstance<T>( cl : Class<T>, args : Array<Dynamic> ) : T
	{
		var instance = Type.createInstance(cl, args);
		return instance;
	}
}