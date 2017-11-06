/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection;

import avmplus.DescribeTypeJSON;
import flash.utils.Dictionary;
import org.swiftsuspenders.errors.InjectorError;
import org.swiftsuspenders.reflection.traits.Meta;
import org.swiftsuspenders.reflection.traits.RawDescription;
import org.swiftsuspenders.reflection.traits.Traits;
import org.swiftsuspenders.typedescriptions.ConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.MethodInjectionPoint;
import org.swiftsuspenders.typedescriptions.NoParamsConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.OrderedInjectionPoint;
import org.swiftsuspenders.typedescriptions.PostConstructInjectionPoint;
import org.swiftsuspenders.typedescriptions.PreDestroyInjectionPoint;
import org.swiftsuspenders.typedescriptions.PropertyInjectionPoint;
import org.swiftsuspenders.typedescriptions.TypeDescription;
import org.swiftsuspenders.utils.MaxInt;

class DescribeTypeJSONReflector extends ReflectorBase implements Reflector
{
    //----------------------       Private / Protected Properties       ----------------------//
    //private var _descriptor(default, never):DescribeTypeJSON = new DescribeTypeJSON();
    
    //----------------------               Public Methods               ----------------------//
    public function typeImplements(type:Class<Dynamic>, superType:Class<Dynamic>):Bool
    {
        if (type == superType)
        {
            return true;
        }
        var superClassName:String = Type.getClassName(superType);
        
        var traits:Dynamic = DescribeTypeJSON.getInstanceDescription(type).traits;
        return (try cast(traits.bases, Array<Dynamic>) catch(e:Dynamic) null).indexOf(superClassName) > -1 || (try cast(traits.interfaces, Array<Dynamic>) catch(e:Dynamic) null).indexOf(superClassName) > -1;
    }
    
    public function describeInjections(type:Class<Dynamic>):TypeDescription
    {
        var rawDescription:RawDescription = DescribeTypeJSON.getInstanceDescription(type);
        var traits:Traits = rawDescription.traits;
        var typeName:String = rawDescription.name;
        var description:TypeDescription = new TypeDescription(false);
        addCtorInjectionPoint(description, traits, typeName);
        //addFieldInjectionPoints(description, traits.variables);
		
        addFieldInjectionPoints(description, type);
        addFieldInjectionPoints(description, traits.accessors);
        addMethodInjectionPoints(description, traits.methods, typeName);
        addPostConstructMethodPoints(description, traits.variables, typeName);
        addPostConstructMethodPoints(description, traits.accessors, typeName);
        addPostConstructMethodPoints(description, traits.methods, typeName);
        addPreDestroyMethodPoints(description, traits.methods, typeName);
        return description;
    }
    
    //----------------------         Private / Protected Methods        ----------------------//
    private function addCtorInjectionPoint(description:TypeDescription, traits:Dynamic, typeName:String):Void
    {
        var parameters:Array<Dynamic> = traits.constructor;
        if (parameters == null)
        {
            description.ctor = (traits.bases.length > 0) ? new NoParamsConstructorInjectionPoint():null;
            return;
        }
        var injectParameters:Map<Dynamic, Dynamic> = extractTagParameters("inject", traits.metadata);
        var parameterNamesStr:String = "";
		if (injectParameters != null) {
			if (injectParameters.exists("name")) parameterNamesStr = injectParameters.get("name");
		}
		var parameterNames:Array<Dynamic> = parameterNamesStr.split(",");
        var requiredParameters:Int = gatherMethodParameters(parameters, parameterNames, typeName);
        description.ctor = new ConstructorInjectionPoint(parameters, requiredParameters, injectParameters);
    }
    
    private function addMethodInjectionPoints(description:TypeDescription, methods:Array<Dynamic>, typeName:String):Void
    {
        if (methods == null)
        {
            return;
        }
        var length:Int = methods.length;
        for (i in 0...length)
        {
            var method:Dynamic = methods[i];
            var injectParameters:Map<Dynamic, Dynamic> = extractTagParameters("inject", method.metadata);
            if (injectParameters == null)
            {
                continue;
            }
            var optional:Bool = injectParameters.get("optional") == "true";
            var parameterNamesStr:String = injectParameters.get("name");
			if (parameterNamesStr == null) parameterNamesStr = "";
            var parameterNames:Array<Dynamic> = parameterNamesStr.split(",");
            var parameters:Array<Dynamic> = method.parameters;
            var requiredParameters:Int = 
            gatherMethodParameters(parameters, parameterNames, typeName);
            var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(method.name, parameters, requiredParameters, optional, injectParameters);
            description.addInjectionPoint(injectionPoint);
        }
    }
    
    private function addPostConstructMethodPoints(
            description:TypeDescription, methods:Array<Dynamic>, typeName:String):Void
    {
        var injectionPoints:Array<Dynamic> = gatherOrderedInjectionPointsForTag(PostConstructInjectionPoint, "PostConstruct", methods, typeName
        );
        var i:Int = 0;
        var length:Int = injectionPoints.length;
        while (i < length)
        {
            description.addInjectionPoint(injectionPoints[i]);
            i++;
        }
    }
    
    private function addPreDestroyMethodPoints(
            description:TypeDescription, methods:Array<Dynamic>, typeName:String):Void
    {
        var injectionPoints:Array<Dynamic> = gatherOrderedInjectionPointsForTag(PreDestroyInjectionPoint, "PreDestroy", methods, typeName
        );
        if (injectionPoints.length == 0)
        {
            return;
        }
        description.preDestroyMethods = injectionPoints[0];
        description.preDestroyMethods.last = injectionPoints[0];
        var i:Int = 1;
        var length:Int = injectionPoints.length;
        while (i < length)
        {
            description.preDestroyMethods.last.next = injectionPoints[i];
            description.preDestroyMethods.last = injectionPoints[i];
            i++;
        }
    }
    
	
	
    //private function addFieldInjectionPoints(description:TypeDescription, fields:Array<Dynamic>):Void
    private function addFieldInjectionPoints(description:TypeDescription, type:Class<Dynamic>):Void
    {
		var meta:Meta = Reflect.getProperty(type, "__meta__");
		var fields:Array<Dynamic> = [];
		
		var fs:Array<String> = Reflect.fields(meta.fields);
		for (f in fs) 
		{
			var _f = Reflect.getProperty(meta.fields, f);
			fields.push(_f);
		}
		
        if (fields == null)
        {
            return;
        }
        var length:Int = fields.length;
        for (i in 0...length)
        {
            var field:Dynamic = fields[i];
            var injectParameters:Map<Dynamic, Dynamic> = extractTagParameters("inject", field.metadata);
            if (injectParameters == null)
            {
                continue;
            }
            var mappingName:String = "";
			if (injectParameters.exists("name")) {
				mappingName = injectParameters.get("name");
			}
            var optional:Bool = injectParameters.get("optional") == "true";
            var injectionPoint:PropertyInjectionPoint = new PropertyInjectionPoint(field.type + "|" + mappingName, field.name, optional, injectParameters);
            description.addInjectionPoint(injectionPoint);
        }
    }
    
    private function gatherMethodParameters(parameters:Array<Dynamic>, parameterNames:Array<Dynamic>, typeName:String):Int
    {
        var requiredLength:Int = 0;
        var length:Int = parameters.length;
        for (i in 0...length)
        {
            var parameter:Dynamic = parameters[i];
            var injectionName:String = parameterNames[i];
			if (injectionName == null) injectionName = "";
			
            var parameterTypeName:String = parameter.type;
            if (parameterTypeName == "*")
            {
                if (!parameter.optional)
                {
                    throw new InjectorError("Error in method definition of injectee \"" +
                    typeName + ". Required parameters can\'t have type \"*\".");
                }
                else
                {
                    parameterTypeName = null;
                }
            }
            if (!parameter.optional)
            {
                requiredLength++;
            }
            parameters[i] = parameterTypeName + "|" + injectionName;
        }
        return requiredLength;
    }
    
    private function gatherOrderedInjectionPointsForTag(injectionPointClass:Class<OrderedInjectionPoint>, tag:String, methods:Array<Dynamic>, typeName:String):Array<Dynamic>
    {
        var injectionPoints:Array<OrderedInjectionPoint> = [];
        if (methods == null)
        {
            return injectionPoints;
        }
        var length:Int = methods.length;
        for (i in 0...length)
        {
            var method:Dynamic = methods[i];
            var injectParameters:Dynamic = extractTagParameters(tag, method.metadata);
            if (injectParameters == null)
            {
                continue;
            }
			
            var parameterNamesStr:String = injectParameters.name;
			if (parameterNamesStr == null) parameterNamesStr = "";
            var parameterNames:Array<Dynamic> = parameterNamesStr.split(",");
            var parameters:Array<Dynamic> = method.parameters;
            var requiredParameters:Int;
            if (parameters != null)
            {
                requiredParameters =
                        gatherMethodParameters(parameters, parameterNames, typeName);
            }
            else
            {
                parameters = [];
                requiredParameters = 0;
            }
			
            var order:Int = Std.parseInt(injectParameters.order);
            //int can't be NaN, so we have to verify that parsing succeeded by comparison
            if (Std.string(order) != injectParameters.order)
            {
				order = MaxInt.INT_MAX;
            }
            injectionPoints.push(Type.createInstance(injectionPointClass, [method.name, parameters, requiredParameters, order]));
        }
        if (injectionPoints.length > 0)
        {
			injectionPoints.sort(function(i1:OrderedInjectionPoint, i2:OrderedInjectionPoint):Int
			{
				if (i1.order > i2.order) return 1;
				else if (i1.order < i2.order) return -1;
				else return 0;
			});
        }
        return injectionPoints;
    }
    private function extractTagParameters(tag:String, metadata:Array<Dynamic>):Map<String, Dynamic>
    {
        var length:Int = (metadata != null) ? metadata.length:0;
        for (i in 0...length)
        {
            var entry:Dynamic = metadata[i];
            if (entry.name == tag)
            {
                var parametersList:Array<Dynamic> = entry.value;
                var parametersMap:Map<String, Dynamic> = new Map<String, Dynamic>();
                var parametersCount:Int = parametersList.length;
                for (j in 0...parametersCount)
                {
                    var parameter:Dynamic = parametersList[j];
                    parametersMap[parameter.key] = (parametersMap[parameter.key] != null) ? parametersMap[parameter.key] + "," + parameter.value:parameter.value;
                }
                return parametersMap;
            }
        }
        return null;
    }

    public function new()
    {
		DescribeTypeJSON.init();
        super();
    }
}
