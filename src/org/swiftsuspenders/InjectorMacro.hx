package org.swiftsuspenders;

// #if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author P.J.Shand
 */
class InjectorMacro {
	static var keptTypes = new Map<String, Bool>();

	public function new() {}

	public static macro function keep(expr:Expr) {
		switch (Context.typeof(expr)) {
			case TType(t, _):
				var type = t.get();

				var name = type.name;
				name = name.substring(6, name.length - 1);

				if (keptTypes.exists(name))
					return macro null;
				keptTypes.set(name, true);

				var module = Context.getModule(type.module);

				for (moduleType in module)
					switch (moduleType) {
						case TInst(t, _):
							var theClass = t.get();
							var className = theClass.pack.concat([theClass.name]).join('.');
							if (className != name)
								continue;
							if (theClass.constructor != null) theClass.constructor.get().meta.add(':keep', [], Context.currentPos());
						case _:
					}
			case _:
		}

		return macro null;
	}
}

// #end
