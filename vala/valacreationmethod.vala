/* valacreationmethod.vala
 *
 * Copyright (C) 2007-2010  Jürg Billeter
 * Copyright (C) 2007-2008  Raffaele Sandrini
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *	Raffaele Sandrini <raffaele@sandrini.ch>
 * 	Jürg Billeter <j@bitron.ch>
 */

using GLib;

/**
 * Represents a type creation method.
 */
public class Vala.CreationMethod : Method {
	/**
	 * Specifies the name of the type this creation method belongs to.
	 */
	public string class_name { get; set; }

	/**
	 * Specifies whether this constructor chains up to a base
	 * constructor or a different constructor of the same class.
	 */
	public bool chain_up { get; set; }

	/**
	 * Creates a new method.
	 *
	 * @param name             method name
	 * @param source_reference reference to source code
	 * @return                 newly created method
	 */
	public CreationMethod (string? class_name, string? name, SourceReference? source_reference = null, Comment? comment = null) {
		base (name, new VoidType (), source_reference, comment);
		this.class_name = class_name;
	}

	public override void accept (CodeVisitor visitor) {
		visitor.visit_creation_method (this);
	}

	public override void accept_children (CodeVisitor visitor) {
		foreach (Parameter param in get_parameters()) {
			param.accept (visitor);
		}

		if (error_types != null) {
			foreach (DataType error_type in error_types) {
				error_type.accept (visitor);
			}
		}

		foreach (Expression precondition in get_preconditions ()) {
			precondition.accept (visitor);
		}

		foreach (Expression postcondition in get_postconditions ()) {
			postcondition.accept (visitor);
		}

		if (body != null) {
			body.accept (visitor);
		}
	}

	public override bool check (CodeContext context) {
		if (checked) {
			return !error;
		}

		checked = true;

		if (class_name != null && class_name != parent_symbol.name) {
			// class_name is null for constructors generated by GIdlParser
			Report.error (source_reference, "missing return type in method `%s.%s´".printf (context.analyzer.get_current_symbol (parent_node).get_full_name (), class_name));
			error = true;
			return false;
		}

		int i = 0;
		foreach (Parameter param in get_parameters()) {
			param.check (context);
			if (i == 0 && param.ellipsis && body != null) {
				error = true;
				Report.error (param.source_reference, "Named parameter required before `...'");
			}
			i++;
		}

		if (error_types != null) {
			foreach (DataType error_type in error_types) {
				error_type.check (context);
			}
		}

		foreach (Expression precondition in get_preconditions ()) {
			precondition.check (context);
		}

		foreach (Expression postcondition in get_postconditions ()) {
			postcondition.check (context);
		}

		if (body != null) {
			body.check (context);

			var cl = parent_symbol as Class;

			// ensure we chain up to base constructor
			if (!chain_up && cl != null && cl.base_class != null) {
				if (cl.base_class.default_construction_method != null
				    && !cl.base_class.default_construction_method.has_construct_function) {

					var stmt = new ExpressionStatement (new MethodCall (new MemberAccess (new MemberAccess.simple ("GLib", source_reference), "Object", source_reference), source_reference), source_reference);
					body.insert_statement (0, stmt);
					stmt.check (context);
				} else if (cl.base_class.default_construction_method == null
				    || cl.base_class.default_construction_method.access == SymbolAccessibility.PRIVATE) {
					Report.error (source_reference, "unable to chain up to private base constructor");
				} else if (cl.base_class.default_construction_method.get_required_arguments () > 0) {
					Report.error (source_reference, "unable to chain up to base constructor requiring arguments");
				} else {
					var stmt = new ExpressionStatement (new MethodCall (new BaseAccess (source_reference), source_reference), source_reference);
					body.insert_statement (0, stmt);
					stmt.check (context);
				}
			}
		}

		if (is_abstract || is_virtual || overrides) {
			Report.error (source_reference, "The creation method `%s' cannot be marked as override, virtual, or abstract".printf (get_full_name ()));
			return false;
		}

		// check that all errors that can be thrown in the method body are declared
		if (body != null) {
			var body_errors = new ArrayList<DataType> ();
			body.get_error_types (body_errors);
			foreach (DataType body_error_type in body_errors) {
				bool can_propagate_error = false;
				if (error_types != null) {
					foreach (DataType method_error_type in error_types) {
						if (body_error_type.compatible (method_error_type)) {
							can_propagate_error = true;
						}
					}
				}
				if (!can_propagate_error && !((ErrorType) body_error_type).dynamic_error) {
					Report.warning (body_error_type.source_reference, "unhandled error `%s'".printf (body_error_type.to_string()));
				}
			}
		}

		return !error;
	}
}
