package org.swiftsuspenders.macros;


#if macro

import haxe.macro.Context;
import haxe.macro.Expr.Field;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type.ClassType;
import haxe.macro.MacroStringTools;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.FieldKind;
import haxe.macro.Type.TypeParameter;
import haxe.macro.TypeTools;



#end

/**
 * This macro adds a __init__ magic method that creates a 
 * TypeDescription object for the class in question.
 * 
 * If this __init__ method already exists then the new code
 * will be added to the end of this function.
 * 
 * An example of the code that gets built:
 * 
 * <pre>
 * class MyClass{
 * 		
 * 		// Start macro generated code
 * 		static var __TYPE_DESC:TypeDescription;
 * 
 * 		static function __init__(){
 * 			__TYPE_DESC = new TypeDescription(false);
 * 			__TYPE_DESC.setConstructor([ContextView], null, 1);
 * 			__TYPE_DESC.addFieldInjection("context", [ContextView], "myContext", 1);
 * 		}
 * 		// End macro generated code
 * 
 * 		@inject("name=myContext")
 * 		public var context:IContext
 * 
 * 		public function new(contextView:ContextView){
 * 		}
 * }
 *</pre>
 * 
 * 
 * @author Thomas Byrne
 */
class ReflectorMacro 
{
	
	macro static public function check():Array<Field> {
		return checkType();
	}
	
#if macro

	static function checkType() : Array<Field>
	{
		var typename = Context.getLocalClass().toString();
		
		var fields = Context.getBuildFields();
		var typeDescExpr:Array<Expr> = [];
		var constDescExpr:Array<Expr> = [];
		var firstPos:Position = Context.currentPos();
		
		var classType:ClassType = null;
        switch (Context.getLocalType()) {
            case TInst(r, _):
                classType = r.get();
            case _:
        }
		
		if (classType != null){
			checkForSuperFields(classType, constDescExpr, typeDescExpr);
		}
		
		var initFunction:Function = checkFields(fields, constDescExpr, typeDescExpr);
		
		var noConstructor:Bool = constDescExpr.length == 0;
		
		var ex = macro __TYPE_DESC = new org.swiftsuspenders.typedescriptions.TypeDescription($v{noConstructor});
		typeDescExpr.unshift(ex);
		
		if (!noConstructor){
			// Add the last constructor expression (as it is the last most sub-class's constructor)
			typeDescExpr.push(constDescExpr[constDescExpr.length - 1]);
		}
		
		
		if (initFunction != null){
			var initExpr = initFunction.expr;
			switch(initExpr.expr){
				case ExprDef.EBlock(exprs):
					initExpr = { expr:ExprDef.EBlock(exprs.concat(typeDescExpr)), pos:initExpr.pos };
				default:
					initExpr = { expr:ExprDef.EBlock([initExpr].concat(typeDescExpr)), pos:initExpr.pos };
			}
			initFunction.expr = initExpr;
		}else{
			var f:Function = { args:[], ret:null, expr: { expr:ExprDef.EBlock(typeDescExpr), pos:firstPos }};
			var initField:Field = { name:"__init__", kind:FieldType.FFun( f ), pos:firstPos, access:[Access.AStatic] };
			fields.push(initField);
		}
		
		var descField:Field = { name:"__TYPE_DESC", kind:FieldType.FVar(ComplexType.TPath( { pack:["org", "swiftsuspenders", "typedescriptions"], name: "TypeDescription" } )), pos:firstPos, access:[Access.AStatic] };
		fields.push(descField);
		
		return fields;
	}
	
	static private function checkForSuperFields(classType:ClassType, constDescExpr:Array<Expr>, typeDescExpr:Array<Expr>) 
	{
		if (classType.superClass == null) return;
		var superClass:ClassType = classType.superClass.t.get();
		checkForSuperFields(superClass, constDescExpr, typeDescExpr);
        checkFields(convertToFields(superClass.fields.get()), constDescExpr, typeDescExpr);
	}
	
	@:access(haxe.macro.TypeTools.toField)
	static private function convertToFields(classFields:Array<ClassField>) : Array<Field>
	{
		var ret = [];
		for (classField in classFields){
			try{
				var field = TypeTools.toField(classField);
				ret.push(field);
			}catch(e:Dynamic){}
		}
		return ret;
	}
	
	static private function checkFields(fields:Array<Field>, constDescExpr:Array<Expr>, typeDescExpr:Array<Expr>) : Null<Function>
	{
		var initFunction:Function = null;
		
		for(field in fields){
			var optional = false;
			var functionInfo:FunctionInfo = null;
			
			var fieldName = field.name;
			var metalist = field.meta;
			
			if (field.name == "__init__" && field.access.indexOf(Access.AStatic) != -1){
				switch(field.kind){
					case FieldType.FFun(f):
						 initFunction = f;
					default: // ignore
				}
			}
			
			if (field.name == "new"){
				if (functionInfo == null){
					switch(field.kind){
						case FieldType.FFun(f):
							 functionInfo = getFunctionInfo(f);
						default: // ignore
					}
				}
				
				if(functionInfo != null){
					
					var ex = macro __TYPE_DESC.setConstructor($a{functionInfo.parameterTypes}, null, $v{functionInfo.required});
					constDescExpr.push(ex);
					
					continue; // Don't do meta search on constructor
				}
			}
			
			if (metalist != null){
				
				var keepAdded = false;
				
				for (meta in metalist){
					var name = meta.name;
					if (name.charAt(0) == ":") name = name.substr(1);
					
					var postConstruct = false;
					var preDestroy = false;
					var inject = false;
					var names = null;
					
					if (name == "postConstruct"){
						postConstruct = true;
						
					}else if (name == "preDestroy"){
						preDestroy = true;
						
					}else if (name == "inject"){
						inject = true;
					}
					
					if (postConstruct || preDestroy || inject){
						
						if (!keepAdded){
							keepAdded = true;
							metalist.push({ name: ":keep", pos:field.pos });
						}
						
						for (k in 0 ... meta.params.length){
							var param:Expr = meta.params[k];
							switch(param.expr){
								case ExprDef.EConst(c):
									switch(c){
										case Constant.CString(s):
											var parts = s.split("=");
											if(parts.length == 2){
												var name = parts[0].toLowerCase();
												var value = parts[1];
												switch(name){
													case "optional":
														optional = (value == "true");
													case "name":
														if (names == null) names = [value];
														else names.push(value);
												}
											}
											
										default:
											// ignore
									}
								default:
									// ignore
							}
						}
						
						switch(field.kind){
							case FieldType.FFun(f):
								if (functionInfo == null) functionInfo = getFunctionInfo(f);
								
								var namesExpr:Expr;
								if (names == null){
									namesExpr = macro null;
								}else{
									namesExpr = macro $v{names};
								}
								var ex;
								if(inject){
									ex = macro __TYPE_DESC.addMethodInjection($v{fieldName}, $a{functionInfo.parameterTypes}, ${namesExpr}, $v{functionInfo.required}, $v{optional});
								}else if (postConstruct){
									ex = macro __TYPE_DESC.addPostConstructMethod($v{fieldName}, $a{functionInfo.parameterTypes}, ${namesExpr}, $v{functionInfo.required});
								}else if (preDestroy){
									ex = macro __TYPE_DESC.addPreDestroyMethod($v{fieldName}, $a{functionInfo.parameterTypes}, ${namesExpr}, $v{functionInfo.required});
								}
								typeDescExpr.push(ex);
								
							case FieldType.FVar(t, e) | FieldType.FProp(_, _, t, e):
							
								var typename = t==null ? null : ComplexTypeTools.toString(t);
								var typepath:Expr;
								if (typename == null){
									typepath = macro null;
								}else{
									typepath = MacroStringTools.toFieldExpr(typename.split("."));
								}
								var name = (names == null ? null : names[0]);
								var ex = macro __TYPE_DESC.addFieldInjection($v{fieldName}, ${typepath}, $v{name}, $v{optional});
								typeDescExpr.push(ex);
						}
					}
				}
			}
		}
		
		return initFunction;
	}
	
	static private function getFunctionInfo(func:Function) : FunctionInfo
	{
		var parameterTypes:Array<Expr> = [];
		var required = func.args.length;
		for (arg in func.args){
			if (arg.opt || arg.value != null){
				required--;
			}
			var paramtype = ComplexTypeTools.toString(arg.type);
			if (paramtype.indexOf("Array<") == 0 || paramtype.indexOf("Map<") == 0){
				paramtype = "Dynamic";
			}
			parameterTypes.push(MacroStringTools.toFieldExpr(paramtype.split(".")));
		}
		return { parameterTypes:parameterTypes, required:required };
	}
	
#end
}

#if macro

typedef FunctionInfo =
{
	var parameterTypes:Array<Expr>;
	var required:Int;
}

#end