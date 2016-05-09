//------------------------------------------------------------------------------
//  Copyright (c) 2009-2013 the original author or authors. All Rights Reserved. 
// 
//  NOTICE: You are permitted to use, modify, and distribute this file 
//  in accordance with the terms of the license agreement accompanying it. 
//------------------------------------------------------------------------------

package org.swiftsuspenders.utils;
import haxe.ds.ObjectMap;
import openfl.errors.Error;


/**
 * Utility for generating unique object IDs
 */

@:keepSub
class UID
{

	/*============================================================================*/
	/* Private Static Properties                                                  */
	/*============================================================================*/

	private static var _i:UInt;

	/*============================================================================*/
	/* Public Static Functions                                                    */
	/*============================================================================*/

	/**
	 * Generates a UID for a given source object or class
	 * @param source The source object or class
	 * @return Generated UID
	 */
	public static function create(source:Dynamic = null):String
	{
		var className = UID.classID(source);
		var random:Int = Math.floor(Math.random() * 255);
		//trace("source = " + source);
		var returnVal:String = "";// (source ? source + '-':'');
		if (source != null) returnVal = className;
		//returnVal = returnVal + _i;
		//_i = _i + 1;
		returnVal += '-';
		returnVal += random;
		
		//trace("returnVal = " + returnVal);
		
		return returnVal;
		
		/*var className = UID.classID(source);
		return (source ? source + '-':'')
			+ StringTools.hex(_i++, 16)
			+ '-'
			+ StringTools.hex(Math.floor(Math.random() * 255), 16);*/
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
	//private static var refs = new Array<Dynamic>();
	//private static var classRefs = new Map<String,Array<Dynamic>>();
	private static var classRefs = new ObjectMap<Dynamic,String>();
	private static var count:Int = 0;
	
	public static function instanceID(source:Dynamic):String
	{
		if (!classRefs.exists(source)) {
			classRefs.set(source, "id"+ (count++));
		}
		return classRefs.get(source);
		/*var classID = classID(source);
		if (Std.is(source, Class)) {
			// Instance can not be of type Class
			return classID;
		}
		if (classRefs[classID] == null) {
			classRefs[classID] = [];
		}
		var id:Int = -1;
		for (i in 0...classRefs[classID].length) 
		{
			if (classRefs[classID][i] == source) {
				id = i;
				break;
			}
		}
		if (id == -1) {
			id = classRefs[classID].length;
			classRefs[classID].push(source);
		}
		return UID.classID(source) + "-" + id;*/
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
		
		/*// Warning, the next time instanceID is called, a new ID will be assigned!
		var classID = classID(source);
		if (Std.is(source, Class)) {
			// Instance can not be of type Class
			return classID;
		}
		if (classRefs[classID] == null) {
			classRefs[classID] = [];
		}
		
		for (i in 0...classRefs[classID].length) 
		{
			if (classRefs[classID][i] == source) {
				classRefs[classID][i] = null;
				return UID.classID(source) + "-" + i;
			}
		}
		throw new Error("instanceID: " + source + " is not in use");
		return "";*/
	}
}