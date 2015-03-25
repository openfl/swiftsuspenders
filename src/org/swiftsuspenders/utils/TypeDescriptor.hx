/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.utils;

import org.swiftsuspenders.reflection.Reflector;
import org.swiftsuspenders.typedescriptions.TypeDescription;

@:keepSub
class TypeDescriptor
{
	//----------------------       Private / Protected Properties       ----------------------//
	public var _descriptionsCache:Map<String,TypeDescription>;
	private var _reflector:Reflector;


	//----------------------               Public Methods               ----------------------//
	public function new(reflector:Reflector, descriptionsCache:Map<String,TypeDescription>)
	{
		_descriptionsCache = descriptionsCache;
		_reflector = reflector;
	}

	public function getDescription(type:Class<Dynamic>):TypeDescription
	{
		var id = UID.classID(type);
		
		//trace("id = " + id);
		//trace("type = " + type);
		
		//get type description or cache it if the given type wasn't encountered before
		if (_descriptionsCache[id] == null) {
			
			_descriptionsCache[id] = _reflector.describeInjections(type);
			
		}
		
		//_descriptionsCache[type] = _descriptionsCache[type] || _reflector.describeInjections(type);
		return _descriptionsCache[id];
	}

	public function addDescription(type:Class<Dynamic>, description:TypeDescription):Void
	{
		_descriptionsCache[UID.classID(type)] = description;
	}
}