/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection;


//import flash.utils.describeType;
import haxe.rtti.Meta;
import haxe.xml.Fast;
import openfl.errors.Error;
import org.swiftsuspenders.utils.CallProxy;

import org.swiftsuspenders.errors.InjectorError;

import org.swiftsuspenders.typedescriptions.ConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.MethodInjectionPoint;
import org.swiftsuspenders.typedescriptions.NoParamsConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.PostConstructInjectionPoint;
import org.swiftsuspenders.typedescriptions.PreDestroyInjectionPoint;
import org.swiftsuspenders.typedescriptions.PropertyInjectionPoint;
import org.swiftsuspenders.typedescriptions.TypeDescription;

@:keepSub
@:rtti
class DescribeTypeRTTIReflector implements Reflector
{
	//----------------------       Private / Protected Properties       ----------------------//
	private var _currentFactoryXML:Xml;
	private var _currentFactoryXMLFast:Fast;
	var constructorElem:Fast;
	var rtti:String;
	var extendPath:String;
	
	private var extendDescribeTypeReflector:DescribeTypeRTTIReflector;
	var extendTypeDescription:org.swiftsuspenders.typedescriptions.TypeDescription;
	
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
		if (Std.is(value, Xml))
		{
			return Xml;
		}
		else if (Std.is(value, Array))
		{
			return Array;
		}
		
		#if cpp
			return Type.getClass(value);
		#else
			return value.constructor;
		#end
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
	
	//----------------------               Public Methods               ----------------------//
	public function typeImplements(type:Class<Dynamic>, superType:Class<Dynamic>):Bool
	{
		return classExtendsOrImplements(type, superType);
	}
	
	/*
	Method Credits: 2012-2014 Massive Interactive
	//package minject.Reflector;
	*/
	
	public function classExtendsOrImplements(classOrClassName:Dynamic, superClass:Class<Dynamic>):Bool
	{
		var actualClass:Class<Dynamic> = null;
		
		if (Std.is(classOrClassName, Class))
		{
			actualClass = cast(classOrClassName, Class<Dynamic>);
		}
		else if (Std.is(classOrClassName, String))
		{
			try
			{
				actualClass = Type.resolveClass(cast(classOrClassName, String));
			}
			catch (e:Dynamic)
			{
				throw "The class name " + classOrClassName + " is not valid because of " + e + "\n" + e.getStackTrace();
			}
		}
		
		if (actualClass == null)
		{
			throw "The parameter classOrClassName must be a Class or fully qualified class name.";
		}
		
		var classInstance = Type.createEmptyInstance(actualClass);
		return Std.is(classInstance, superClass);
	}
	
	
	
	
	
	public function describeInjections(_type:Class<Dynamic>):TypeDescription
	{
		if (extendDescribeTypeReflector == null) {
			extendDescribeTypeReflector = new DescribeTypeRTTIReflector();
		}
		
		#if cpp
			var type:Dynamic = _type;
		#else 
			var type:Class<Dynamic> = _type;
		#end
		
		rtti = untyped type.__rtti;
		if (rtti == null) {
			if (!isInterface(type)) {
				trace("Warning: " + CallProxy.getClassName(type) + " missing @:rtti matadata");
			}
		}
		
		if (rtti != null) {
			
			_currentFactoryXML = Xml.parse(rtti).firstElement();
			_currentFactoryXMLFast = new Fast(_currentFactoryXML);
			
			for (elem in _currentFactoryXMLFast.elements) {
				if (elem.name == 'new') constructorElem = elem;
				if (elem.name == 'extends') {
					extendPath = elem.att.path;
					var extendClass = Type.resolveClass(extendPath);
					extendTypeDescription = extendDescribeTypeReflector.describeInjections(extendClass);
				}
			}
		}
		
		var description:TypeDescription = new TypeDescription(false);
		addCtorInjectionPoint(description, type); // TEMP
		addFieldInjectionPoints(description, type); // FIX
		addMethodInjectionPoints(description, type); // FIX
		addPostConstructMethodPoints(description, type); // FIX
		addPreDestroyMethodPoints(description, type); // FIX
		
		_currentFactoryXML = null;
		_currentFactoryXMLFast = null;
		constructorElem = null;
		
		rtti = null;
		extendPath = null;
		extendTypeDescription = null;
		
		return description;
	}
	
	function isInterface(type:Class<Dynamic>):Bool
	{
		// Hack to check if class is an interface by looking at its class name and seeing if it Starts with a (IU)ppercase
		var classPath = CallProxy.replaceClassName(type);
		var split = classPath.split(".");
		var className:String = split[split.length - 1];
		if (className.length <= 1) {
			return false;
		}
		else {
			var r = ~/(I)([A-Z])/;
			var f2 = className.substr(0, 2);
			if (r.match(f2)) {
				return true;
			}
			else return false;
		}
	}

	//----------------------         Private / Protected Methods        ----------------------//
	private function addCtorInjectionPoint(description:TypeDescription, type:Class<Dynamic>):Void
	{
		// TEMP (no CtorInjectionPoints will be added)
		
		if (constructorElem == null) {
			description.ctor = new NoParamsConstructorInjectionPoint();
			return;
		}
		
		var className = CallProxy.getClassName(type);
		
		// CHECK add injectParameters
		var injectParameters:Map<String,Dynamic> = null;
		
		
		
		
		var parameterNames:Array<String> = constructorElem.node.f.att.a.split(":");
		var parameters:Array<String> = parametersFromXml(constructorElem.x);
		
		
		var requiredParameters:UInt = 0;
		for (j in 0...parameterNames.length) 
		{
			if (parameterNames[j].indexOf("?") != 0) {
				requiredParameters++;
			}
		}
		description.ctor = new ConstructorInjectionPoint(parameters, requiredParameters, injectParameters);
	}
	
	function parametersFromXml(x:Xml):Array<String>
	{
		var parameters:Array<String> = [];
		for (node in x.firstElement().iterator()) 
		{
			if(node.nodeType == Xml.Element ){
				var nodeFast = new Fast(node);
				parameters.push(nodeFast.att.path + "|");
			}
		}
		parameters.pop();
		return parameters;
	}
	
	// FIX
	/*private function extractNodeParameters(args:XMLList):Map<Dynamic,Dynamic>
	{
		var parametersMap:Map<Dynamic,Dynamic> = new Map<Dynamic,Dynamic>();
		var length:UInt = args.length();
		for (i in 0...length)
		{
			var parameter:Xml = args[i];
			var key:String = parameter.@key;
			parametersMap[key] = parametersMap[key]
				? parametersMap[key] + ',' + parameter.attribute('value')
				: parameter.attribute('value');
		}
		return parametersMap;
	}*/
	
	private function addFieldInjectionPoints(description:TypeDescription, type:Class<Dynamic>):Void
	{
		// CHECK
		var metaFields = Meta.getFields(type);
		var fields = Reflect.fields(metaFields);
		var injectFields:Array<String> = [];
		
		
		
		for (value in fields)
		{
			
			var metaFields1 = Reflect.getProperty(metaFields, value);
			var fields1 = Reflect.fields(metaFields1);
			if (fields1[0] == 'inject') {
				injectFields.push(value);
			}
			
			
		}
		
		if (extendTypeDescription != null) {
			description.injectionPoints = extendTypeDescription.injectionPoints;
		}
		
		for (propertyName in injectFields) {
			var optional = false;
			var injectParams:Array<String> = Reflect.getProperty(Reflect.getProperty(metaFields, propertyName), "inject");
			if (injectParams != null){
				for (i in 0...injectParams.length) 
				{
					if (injectParams[i].indexOf("optional=") != -1) {
						if (injectParams[i].split("optional=")[1].toLowerCase() == 'true') {
							optional = true;
						}
					}
				}
			}
			
			//var mappingId:String = CallProxy.replaceClassName(type) + '|';// + node.arg.(@key == 'name').attribute('value');
			
			var mappingId:String = "";
			for (elem in _currentFactoryXMLFast.elements) {
				if (elem.name == propertyName) {
					// FIX missing key 
					var pathFast = new Fast(elem.x.firstElement());
					if (pathFast.has.path) mappingId = pathFast.att.path + '|';// + node.arg.(@key == 'name').attribute('value');
				}
			}
			
			/*<init public="1" set="method" line="54">
				<f a=""><x path="Void"/></f>
				<meta><m n="PostConstruct"/></meta>
			</init>
			*/
			/*<init public="1" set="method" line="54">
				<f a=""><x path="Void"/></f>
			</init>*/
			
			//var optional = Reflect.getProperty(injectParams, "optional");
			
			// FIX missing injectParameters
			//var injectParameters:Map<String,Dynamic> = extractNodeParameters(node.arg);
			var injectParameters = new Map<String,Dynamic>();
			
			var injectionPoint:PropertyInjectionPoint = new PropertyInjectionPoint(mappingId, propertyName, optional, injectParameters);
			description.addInjectionPoint(injectionPoint);
			
		}
		
		// FIX
		/*for (var node:Xml in _currentFactoryXML.*.
				(name() == 'variable' || name() == 'accessor').metadata.(@name == 'Inject'))
		{
			var mappingId:String =
					node.parent().@type + '|' + node.arg.(@key == 'name').attribute('value');
			var propertyName:String = node.parent().@name;
			var injectParameters:Map<Dynamic,Dynamic> = extractNodeParameters(node.arg);
			var injectionPoint:PropertyInjectionPoint = new PropertyInjectionPoint(mappingId,
				propertyName, injectParameters.optional == 'true', injectParameters);
			description.addInjectionPoint(injectionPoint);
		}*/
	}

	private function addMethodInjectionPoints(description:TypeDescription, type:Class<Dynamic>):Void
	{
		// FIX
		/*for each (var node:Xml in _currentFactoryXML.method.metadata.(@name == 'Inject'))
		{
			var injectParameters:Map<Dynamic,Dynamic> = extractNodeParameters(node.arg);
			var parameterNames:Array = (injectParameters.name || '').split(',');
			var parameters:Array =
					gatherMethodParameters(node.parent().parameter, parameterNames);
			var requiredParameters:UInt = parameters.required;
			delete parameters.required;
			var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(
				node.parent().@name, parameters, requiredParameters,
				injectParameters.optional == 'true', injectParameters);
			description.addInjectionPoint(injectionPoint);
		}*/
	}

	private function addPostConstructMethodPoints(description:TypeDescription, type:Class<Dynamic>):Void
	{
		var injectionPoints:Array<Dynamic> = gatherOrderedInjectionPointsForTag(PostConstructInjectionPoint, 'PostConstruct', type);
		
		var length = injectionPoints.length;
		for (i in 0...length)
		{
			description.addInjectionPoint(injectionPoints[i]);
		}
	}

	private function addPreDestroyMethodPoints(description:TypeDescription, type:Class<Dynamic>):Void
	{
		var injectionPoints:Array<Dynamic> = gatherOrderedInjectionPointsForTag(PreDestroyInjectionPoint, 'PreDestroy', type);
		
		if (injectionPoints.length == 0)
		{
			return;
		}
		description.preDestroyMethods = injectionPoints[0];
		description.preDestroyMethods.last = injectionPoints[0];
		var length = injectionPoints.length;
		for (i in 0...length)
		{
			description.preDestroyMethods.last.next = injectionPoints[i];
			description.preDestroyMethods.last = injectionPoints[i];
		}
	}

	private function gatherOrderedInjectionPointsForTag(injectionPointType:Class<Dynamic>, tag:String, type:Class<Dynamic>):Array<Dynamic>
	{
		var injectionPoints:Array<Dynamic> = [];
		
		var metaFields = Meta.getFields(type);
		var fields = Reflect.fields(metaFields);
		var injectMethods:Array<String> = [];
		
		for (value in fields) {
			
			var metaFields1 = Reflect.getProperty(metaFields, value);
			var fields1 = Reflect.fields(metaFields1);
			
			//trace("tag = " + tag);
			//trace("fields1[0] = " + fields1[0]);
			if (fields1[0].toLowerCase() == tag.toLowerCase()) {
				injectMethods.push(value);
				
				
					
				for (node in _currentFactoryXML.iterator()) 
				{
					if (node.nodeType == Xml.Element ) {
						
						if (node.nodeName == value){
							//trace("node = " + node);
							var parameterNames:Array<String> = new Fast(node).node.f.att.a.split(":");
							var requiredParameters:Int = 0;
							for (i in 0...parameterNames.length) 
							{
								//trace('parameterNames[i] = ' + parameterNames[i]);
								//trace("parameterNames[i].indexOf('?') = " + parameterNames[i].indexOf("?"));
								if (parameterNames[i].indexOf("?") != 0) {
									requiredParameters++;
								}
							}
							requiredParameters--;
							var parameters:Array<String> = parametersFromXml(node);
							//trace("parameterNames = " + parameterNames);
							//trace("parameters = " + parameters);
							//trace("requiredParameters = " + requiredParameters);
							
							// FIX ORDER
							//var injectionPoint = Type.createInstance(injectionPointType, [node.nodeName, parameters, requiredParameters, 0x3FFFFFFF]); // ORDER: isNaN(order) ? Limits.IntMax:order
							var injectionPoint = CallProxy.createInstance(injectionPointType, [node.nodeName, parameters, requiredParameters, 0x3FFFFFFF]); // ORDER: isNaN(order) ? Limits.IntMax:order
							
							injectionPoints.push(injectionPoint);
						}
						//var nodeFast = new Fast(node);
						//parameters.push(nodeFast.att.path + "|");
						
						
					}
				}
			}
		}
		
		return injectionPoints;
	}
}