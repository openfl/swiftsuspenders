/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders;

import openfl.events.Event;

@:keepSub
class InjectionEvent extends Event {
	//----------------------              Public Properties             ----------------------//

	/**
	 * @eventType postInstantiate
	 */
	public static var POST_INSTANTIATE:String = 'postInstantiate';

	/**
	 * @eventType preConstruct
	 */
	public static var PRE_CONSTRUCT:String = 'preConstruct';

	/**
	 * @eventType postConstruct
	 */
	public static var POST_CONSTRUCT:String = 'postConstruct';

	public var instance:Dynamic;
	public var instanceType:Class<Dynamic>;

	//----------------------               Public Methods               ----------------------//
	public function new(type:String, instance:Dynamic, instanceType:Class<Dynamic>) {
		super(type);
		this.instance = instance;
		this.instanceType = instanceType;
	}

	override public function clone():Event {
		return new InjectionEvent(type, instance, instanceType);
	}
}
