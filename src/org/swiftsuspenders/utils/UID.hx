package org.swiftsuspenders.utils;

import haxe.ds.ObjectMap;

@:keepSub
class UID
{
	private static var _i:UInt;
	
	/**
	 * Generates a UID for a given source object or class
	 * @param source The source object or class
	 * @return Generated UID
	 */
	public static function create(source:Dynamic = null):String
	{
		var className = UID.classID(source);
		var random:Int = Math.floor(Math.random() * 255);
		var returnVal:String = "";// (source ? source + '-':'');
		if (source != null) returnVal = className;
		returnVal += '-';
		returnVal += random;
		
		return returnVal;
	}
	
	public static function classID(source:Dynamic):String
	{
		var className = "";
		if (Std.is(source, Class)) {
			className = CallProxy.replaceClassName(source); 
		}
		else if (Type.getClass(source) != null) {
			className = CallProxy.replaceClassName(Type.getClass(source)); 
		}
		return className;
	}
	
	// Be careful here (you are storing references to objects)
	private static var classRefs = new ObjectMap<Dynamic,String>();
	private static var count:Int = 0;
	
	public static function instanceID(source:Dynamic):String
	{
		if (!classRefs.exists(source)) {
			classRefs.set(source, "id"+ (count++));
		}
		return classRefs.get(source);
	}
	
	public static function clearInstanceID(source:Dynamic):String
	{
		var id:String = classRefs.get(source);
		if (id != null) {
			classRefs.remove(source);
			return id;
		}
		//throw new Error("instanceID: " + source + " is not in use");
		return "";
	}
}