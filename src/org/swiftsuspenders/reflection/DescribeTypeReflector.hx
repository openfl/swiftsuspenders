/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection;

import flash.errors.Error;
import flash.utils.Dictionary;
import org.swiftsuspenders.errors.InjectorError;
import org.swiftsuspenders.typedescriptions.ConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.MethodInjectionPoint;
import org.swiftsuspenders.typedescriptions.NoParamsConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.PostConstructInjectionPoint;
import org.swiftsuspenders.typedescriptions.PreDestroyInjectionPoint;
import org.swiftsuspenders.typedescriptions.PropertyInjectionPoint;
import org.swiftsuspenders.typedescriptions.TypeDescription;

class DescribeTypeReflector extends ReflectorBase implements Reflector
{
    //----------------------       Private / Protected Properties       ----------------------//
    private var _currentFactoryXML : FastXML;
    
    //----------------------               Public Methods               ----------------------//
    public function typeImplements(type : Class<Dynamic>, superType : Class<Dynamic>) : Bool
    {
        if (type == superType)
        {
            return true;
        }
        
        var factoryDescription : FastXML = describeType(type).factory[0];
        
        return null;
    }
    
    public function describeInjections(type : Class<Dynamic>) : TypeDescription
    {
        _currentFactoryXML = describeType(type).factory[0];
        var description : TypeDescription = new TypeDescription(false);
        addCtorInjectionPoint(description, type);
        addFieldInjectionPoints(description);
        addMethodInjectionPoints(description);
        addPostConstructMethodPoints(description);
        addPreDestroyMethodPoints(description);
        _currentFactoryXML = null;
        return description;
    }
    
    //----------------------         Private / Protected Methods        ----------------------//
    private function addCtorInjectionPoint(description : TypeDescription, type : Class<Dynamic>) : Void
    {
        var node : FastXML = _currentFactoryXML.nodes.constructor.get(0);
        if (node == null)
        {
            if (_currentFactoryXML.node.parent.innerData().att.name == "Object" || _currentFactoryXML.nodes.extendsClass.length() > 0)
            {
                description.ctor = new NoParamsConstructorInjectionPoint();
            }
            return;
        }
        var injectParameters : Dictionary = extractNodeParameters(node.node.parent.innerData().metadata.arg);
        var parameterNames : Array<Dynamic> = (injectParameters.name || "").split(",");
        var parameterNodes : FastXMLList = node.node.parameter.innerData;
        /*
			 In many cases, the flash player doesn't give us type information for constructors until
			 the class has been instantiated at least once. Therefore, we do just that if we don't get
			 type information for at least one parameter.
			 */
        //if (parameterNodes.(@type == '*').length() == parameterNodes.@type.length())
        //{
        //	createDummyInstance(node, type);
        //}
        var parameters : Array<Dynamic> = gatherMethodParameters(parameterNodes, parameterNames);
        var requiredParameters : Int = parameters.required;
        This is an intentional compilation error. See the README for handling the delete keyword
        delete parameters.required;
        description.ctor = new ConstructorInjectionPoint(parameters, requiredParameters, injectParameters);
    }
    private function extractNodeParameters(args : FastXMLList) : Dictionary
    {
        var parametersMap : Dictionary = new Dictionary();
        var length : Int = args.length();
        for (i in 0...length)
        {
            var parameter : FastXML = args.get(i);
            var key : String = parameter.att.key;
            Reflect.setField(parametersMap, key, (Reflect.field(parametersMap, key) != null) ? Reflect.field(parametersMap, key) + "," + parameter.node.attribute.innerData("value") : Std.string(parameter.node.attribute.innerData("value")));
        }
        return parametersMap;
    }
    private function addFieldInjectionPoints(description : TypeDescription) : Void
    {  //for each (var node : XML in _currentFactoryXML.*.(name() == 'variable' || name() == 'accessor').metadata.(@name == 'Inject'))  
        //{
        //var mappingId : String = node.parent().@type + '|' + node.arg.(@key == 'name').attribute('value');
        //var propertyName : String = node.parent().@name;
        //const injectParameters : Dictionary = extractNodeParameters(node.arg);
        //var injectionPoint : PropertyInjectionPoint = new PropertyInjectionPoint(mappingId, propertyName, injectParameters.optional == 'true', injectParameters);
        //description.addInjectionPoint(injectionPoint);
        //}
        
    }
    
    private function addMethodInjectionPoints(description : TypeDescription) : Void
    {
        for (node/* AS3HX WARNING could not determine type for var: node exp: EE4XFilter(EField(EField(EIdent(_currentFactoryXML),method),metadata),EBinop(==,EIdent(@name),EConst(CString(Inject)),false)) type: null */ in FastXML.filterNodes(_currentFactoryXML.nodes.method.node.metadata.innerData, function(x:FastXML) {
            if(x.att.name == "Inject")
                return true;
            return false;

        }))
        {
            var injectParameters : Dictionary = extractNodeParameters(node.arg);
            var parameterNames : Array<Dynamic> = (injectParameters.name || "").split(",");
            var parameters : Array<Dynamic> = gatherMethodParameters(node.parent().parameter, parameterNames);
            var requiredParameters : Int = parameters.required;
            This is an intentional compilation error. See the README for handling the delete keyword
            delete parameters.required;
            var injectionPoint : MethodInjectionPoint = new MethodInjectionPoint(node.parent().att.name, parameters, requiredParameters, injectParameters.optional == "true", injectParameters);
            description.addInjectionPoint(injectionPoint);
        }
    }
    
    private function addPostConstructMethodPoints(description : TypeDescription) : Void
    {
        var injectionPoints : Array<Dynamic> = gatherOrderedInjectionPointsForTag(PostConstructInjectionPoint, "PostConstruct");
        var i : Int = 0;
        var length : Int = injectionPoints.length;
        while (i < length)
        {
            description.addInjectionPoint(injectionPoints[i]);
            i++;
        }
    }
    
    private function addPreDestroyMethodPoints(description : TypeDescription) : Void
    {
        var injectionPoints : Array<Dynamic> = gatherOrderedInjectionPointsForTag(PreDestroyInjectionPoint, "PreDestroy");
        if (!injectionPoints.length)
        {
            return;
        }
        description.preDestroyMethods = injectionPoints[0];
        description.preDestroyMethods.last = injectionPoints[0];
        var i : Int = 1;
        var length : Int = injectionPoints.length;
        while (i < length)
        {
            description.preDestroyMethods.last.next = injectionPoints[i];
            description.preDestroyMethods.last = injectionPoints[i];
            i++;
        }
    }
    
    private function gatherMethodParameters(parameterNodes : FastXMLList, parameterNames : Array<Dynamic>) : Array<Dynamic>
    {
        var requiredParameters : Int = 0;
        var length : Int = parameterNodes.length();
        var parameters : Array<Dynamic> = new Array<Dynamic>(length);
        for (i in 0...length)
        {
            var parameter : FastXML = parameterNodes.get(i);
            var injectionName : String = parameterNames[i] || "";
            var parameterTypeName : String = parameter.att.type;
            var optional : Bool = parameter.att.optional == "true";
            if (parameterTypeName == "*")
            {
                if (!optional)
                {
                    throw new InjectorError("Error in method definition of injectee \"" +
                    _currentFactoryXML.att.type + "Required parameters can\'t have type \"*\".");
                }
                else
                {
                    parameterTypeName = null;
                }
            }
            if (!optional)
            {
                requiredParameters++;
            }
            parameters[i] = parameterTypeName + "|" + injectionName;
        }
        parameters.required = requiredParameters;
        return parameters;
    }
    
    private function gatherOrderedInjectionPointsForTag(injectionPointType : Class<Dynamic>, tag : String) : Array<Dynamic>
    {
        var injectionPoints : Array<Dynamic> = [];
        for (node/* AS3HX WARNING could not determine type for var: node exp: EE4XFilter(EE4XDescend(EIdent(_currentFactoryXML),EIdent(metadata)),EBinop(==,EIdent(@name),EIdent(tag),false)) type: null */ in FastXML.filterNodes(_currentFactoryXML.descendants("metadata"), function(x:FastXML) {
            if(x.att.name == x.node.tag.innerData)
                return true;
            return false;

        }))
        {
            var injectParameters : Dictionary = extractNodeParameters(node.arg);
            var parameterNames : Array<Dynamic> = (injectParameters.name || "").split(",");
            var parameters : Array<Dynamic> = gatherMethodParameters(node.parent().parameter, parameterNames);
            var requiredParameters : Int = parameters.required;
            This is an intentional compilation error. See the README for handling the delete keyword
            delete parameters.required;
            var order : Float = 0;  // parseInt(node.arg.(@key == 'order').@value);  
            injectionPoints.push(Type.createInstance(injectionPointType, [node.parent().att.name, parameters, requiredParameters, (Math.isNaN(order)) ? as3hx.Compat.INT_MAX : order]));
        }
        if (injectionPoints.length > 0)
        {
            injectionPoints.sortOn("order", Array.NUMERIC);
        }
        return injectionPoints;
    }
    
    private function createDummyInstance(constructorNode : FastXML, clazz : Class<Dynamic>) : Void
    {
        try
        {
            switch (constructorNode.node.children.innerData().length())
            {
                case 0:(Type.createInstance(clazz, []));
                case 1:(Type.createInstance(clazz, [null]));
                case 2:(Type.createInstance(clazz, [null, null]));
                case 3:(Type.createInstance(clazz, [null, null, null]));
                case 4:(Type.createInstance(clazz, [null, null, null, null]));
                case 5:(Type.createInstance(clazz, [null, null, null, null, null]));
                case 6:(Type.createInstance(clazz, [null, null, null, null, null, null]));
                case 7:(Type.createInstance(clazz, [null, null, null, null, null, null, null]));
                case 8:(Type.createInstance(clazz, [null, null, null, null, null, null, null, null]));
                case 9:(Type.createInstance(clazz, [null, null, null, null, null, null, null, null, null]));
                case 10:
                    (Type.createInstance(clazz, [null, null, null, null, null, null, null, null, null, null]));
            }
        }
        catch (error : Error)
        {
            trace("Exception caught while trying to create dummy instance for constructor " +
                    "injection. It\'s almost certainly ok to ignore this exception, but you " +
                    "might want to restructure your constructor to prevent errors from " +
                    "happening. See the Swiftsuspenders documentation for more details.\n" +
                    "The caught exception was:\n" + error);
        }
        constructorNode.node.setChildren.innerData(describeType(clazz).factory.constructor[0].children());
    }

    public function new()
    {
        super();
    }
}
