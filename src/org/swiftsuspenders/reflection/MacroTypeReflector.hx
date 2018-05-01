package org.swiftsuspenders.reflection;

import org.swiftsuspenders.reflection.Reflector;
import org.swiftsuspenders.typedescriptions.TypeDescription;

/**
 * ...
 * @author Thomas Byrne
 */
class MacroTypeReflector implements Reflector 
{
	var fallbackReflector:Reflector;
	
	public function new(?fallbackReflector:Reflector) 
	{
		this.fallbackReflector = fallbackReflector;
	}
	
	
	public function describeInjections(type:Class<Dynamic>):TypeDescription
	{
		var typeDesc = Reflect.field(type, "__TYPE_DESC");
		if (typeDesc == null){
			if(fallbackReflector != null){
				return fallbackReflector.describeInjections(type);
			}else{
				throw "Couldn't find type description on class: " + Type.getClassName(type)
					+ "\n\tMake sure class implements DescribedType";
			}
		}else{
			return typeDesc;
		}
	}
	
	public function getClass(value:Dynamic):Class<Dynamic> 
	{
		return Type.getClass(value);
	}
	
	public function getFQCN(value:Dynamic, replaceColons:Bool = false):String 
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
			fqcn = Type.getClassName(value);
		}
		
		if (replaceColons == true) {
			return fqcn.split('::').join('.');
		}
		return fqcn;
	}
	
	public function typeImplements(type:Class<Dynamic>, superType:Class<Dynamic>):Bool
	{
		return classExtendsOrImplements(type, superType);
	}
	
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
}

