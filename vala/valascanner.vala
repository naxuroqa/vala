/* valascanner.vala
 *
 * Copyright (C) 2008-2009  Jürg Billeter
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
 * 	Jürg Billeter <j@bitron.ch>
 */

using GLib;
using Gee;

/**
 * Lexical scanner for Vala source files.
 */
public class Vala.Scanner {
	public SourceFile source_file { get; private set; }

	char* current;
	char* end;

	int line;
	int column;

	string _comment;

	Conditional[] conditional_stack;

	struct Conditional {
		public bool matched;
		public bool else_found;
		public bool skip_section;
	}

	public Scanner (SourceFile source_file) {
		this.source_file = source_file;

		char* begin = source_file.get_mapped_contents ();
		end = begin + source_file.get_mapped_length ();

		current = begin;

		line = 1;
		column = 1;
	}

	bool is_ident_char (char c) {
		return (c.isalnum () || c == '_');
	}

	TokenType get_identifier_or_keyword (char* begin, int len) {
		switch (len) {
		case 2:
			switch (begin[0]) {
			case 'a':
				if (matches (begin, "as")) return TokenType.AS;
				break;
			case 'd':
				if (matches (begin, "do")) return TokenType.DO;
				break;
			case 'i':
				switch (begin[1]) {
				case 'f':
					return TokenType.IF;
				case 'n':
					return TokenType.IN;
				case 's':
					return TokenType.IS;
				}
				break;
			}
			break;
		case 3:
			switch (begin[0]) {
			case 'f':
				if (matches (begin, "for")) return TokenType.FOR;
				break;
			case 'g':
				if (matches (begin, "get")) return TokenType.GET;
				break;
			case 'n':
				if (matches (begin, "new")) return TokenType.NEW;
				break;
			case 'o':
				if (matches (begin, "out")) return TokenType.OUT;
				break;
			case 'r':
				if (matches (begin, "ref")) return TokenType.REF;
				break;
			case 's':
				if (matches (begin, "set")) return TokenType.SET;
				break;
			case 't':
				if (matches (begin, "try")) return TokenType.TRY;
				break;
			case 'v':
				if (matches (begin, "var")) return TokenType.VAR;
				break;
			}
			break;
		case 4:
			switch (begin[0]) {
			case 'b':
				if (matches (begin, "base")) return TokenType.BASE;
				break;
			case 'c':
				if (matches (begin, "case")) return TokenType.CASE;
				break;
			case 'e':
				switch (begin[1]) {
				case 'l':
					if (matches (begin, "else")) return TokenType.ELSE;
					break;
				case 'n':
					if (matches (begin, "enum")) return TokenType.ENUM;
					break;
				}
				break;
			case 'l':
				if (matches (begin, "lock")) return TokenType.LOCK;
				break;
			case 'n':
				if (matches (begin, "null")) return TokenType.NULL;
				break;
			case 't':
				switch (begin[1]) {
				case 'h':
					if (matches (begin, "this")) return TokenType.THIS;
					break;
				case 'r':
					if (matches (begin, "true")) return TokenType.TRUE;
					break;
				}
				break;
			case 'v':
				if (matches (begin, "void")) return TokenType.VOID;
				break;
			case 'w':
				if (matches (begin, "weak")) return TokenType.WEAK;
				break;
			}
			break;
		case 5:
			switch (begin[0]) {
			case 'b':
				if (matches (begin, "break")) return TokenType.BREAK;
				break;
			case 'c':
				switch (begin[1]) {
				case 'a':
					if (matches (begin, "catch")) return TokenType.CATCH;
					break;
				case 'l':
					if (matches (begin, "class")) return TokenType.CLASS;
					break;
				case 'o':
					if (matches (begin, "const")) return TokenType.CONST;
					break;
				}
				break;
			case 'f':
				if (matches (begin, "false")) return TokenType.FALSE;
				break;
			case 'o':
				if (matches (begin, "owned")) return TokenType.OWNED;
				break;
			case 't':
				if (matches (begin, "throw")) return TokenType.THROW;
				break;
			case 'u':
				if (matches (begin, "using")) return TokenType.USING;
				break;
			case 'w':
				if (matches (begin, "while")) return TokenType.WHILE;
				break;
			case 'y':
				if (matches (begin, "yield")) return TokenType.YIELD;
				break;
			}
			break;
		case 6:
			switch (begin[0]) {
			case 'd':
				if (matches (begin, "delete")) return TokenType.DELETE;
				break;
			case 'e':
				if (matches (begin, "extern")) return TokenType.EXTERN;
				break;
			case 'i':
				if (matches (begin, "inline")) return TokenType.INLINE;
				break;
			case 'p':
				switch (begin[1]) {
				case 'a':
					if (matches (begin, "params")) return TokenType.PARAMS;
					break;
				case 'u':
					if (matches (begin, "public")) return TokenType.PUBLIC;
					break;
				}
				break;
			case 'r':
				if (matches (begin, "return")) return TokenType.RETURN;
				break;
			case 's':
				switch (begin[1]) {
				case 'i':
					switch (begin[2]) {
					case 'g':
						if (matches (begin, "signal")) return TokenType.SIGNAL;
						break;
					case 'z':
						if (matches (begin, "sizeof")) return TokenType.SIZEOF;
						break;
					}
					break;
				case 't':
					switch (begin[2]) {
					case 'a':
						if (matches (begin, "static")) return TokenType.STATIC;
						break;
					case 'r':
						if (matches (begin, "struct")) return TokenType.STRUCT;
						break;
					}
					break;
				case 'w':
					if (matches (begin, "switch")) return TokenType.SWITCH;
					break;
				}
				break;
			case 't':
				switch (begin[1]) {
				case 'h':
					if (matches (begin, "throws")) return TokenType.THROWS;
					break;
				case 'y':
					if (matches (begin, "typeof")) return TokenType.TYPEOF;
					break;
				}
				break;
			case 'y':
				if (matches (begin, "yields")) return TokenType.YIELDS;
				break;
			}
			break;
		case 7:
			switch (begin[0]) {
			case 'd':
				switch (begin[1]) {
				case 'e':
					if (matches (begin, "default")) return TokenType.DEFAULT;
					break;
				case 'y':
					if (matches (begin, "dynamic")) return TokenType.DYNAMIC;
					break;
				}
				break;
			case 'e':
				if (matches (begin, "ensures")) return TokenType.ENSURES;
				break;
			case 'f':
				switch (begin[1]) {
				case 'i':
					if (matches (begin, "finally")) return TokenType.FINALLY;
					break;
				case 'o':
					if (matches (begin, "foreach")) return TokenType.FOREACH;
					break;
				}
				break;
			case 'p':
				if (matches (begin, "private")) return TokenType.PRIVATE;
				break;
			case 'u':
				if (matches (begin, "unowned")) return TokenType.UNOWNED;
				break;
			case 'v':
				if (matches (begin, "virtual")) return TokenType.VIRTUAL;
				break;
			}
			break;
		case 8:
			switch (begin[0]) {
			case 'a':
				if (matches (begin, "abstract")) return TokenType.ABSTRACT;
				break;
			case 'c':
				if (matches (begin, "continue")) return TokenType.CONTINUE;
				break;
			case 'd':
				if (matches (begin, "delegate")) return TokenType.DELEGATE;
				break;
			case 'i':
				if (matches (begin, "internal")) return TokenType.INTERNAL;
				break;
			case 'o':
				if (matches (begin, "override")) return TokenType.OVERRIDE;
				break;
			case 'r':
				if (matches (begin, "requires")) return TokenType.REQUIRES;
				break;
			case 'v':
				if (matches (begin, "volatile")) return TokenType.VOLATILE;
				break;
			}
			break;
		case 9:
			switch (begin[0]) {
			case 'c':
				if (matches (begin, "construct")) return TokenType.CONSTRUCT;
				break;
			case 'i':
				if (matches (begin, "interface")) return TokenType.INTERFACE;
				break;
			case 'n':
				if (matches (begin, "namespace")) return TokenType.NAMESPACE;
				break;
			case 'p':
				if (matches (begin, "protected")) return TokenType.PROTECTED;
				break;
			}
			break;
		case 11:
			if (matches (begin, "errordomain")) return TokenType.ERRORDOMAIN;
			break;
		}
		return TokenType.IDENTIFIER;
	}

	TokenType read_number () {
		var type = TokenType.INTEGER_LITERAL;

		// integer part
		if (current < end - 2 && current[0] == '0'
		    && current[1] == 'x' && current[2].isxdigit ()) {
			// hexadecimal integer literal
			current += 2;
			while (current < end && current[0].isxdigit ()) {
				current++;
			}
		} else {
			// decimal number
			while (current < end && current[0].isdigit ()) {
				current++;
			}
		}

		// fractional part
		if (current < end - 1 && current[0] == '.' && current[1].isdigit ()) {
			type = TokenType.REAL_LITERAL;
			current++;
			while (current < end && current[0].isdigit ()) {
				current++;
			}
		}

		// exponent part
		if (current < end && current[0].tolower () == 'e') {
			type = TokenType.REAL_LITERAL;
			current++;
			if (current < end && (current[0] == '+' || current[0] == '-')) {
				current++;
			}
			while (current < end && current[0].isdigit ()) {
				current++;
			}
		}

		// type suffix
		if (current < end) {
			bool real_literal = (type == TokenType.REAL_LITERAL);

			switch (current[0]) {
			case 'l':
			case 'L':
				if (type == TokenType.INTEGER_LITERAL) {
					current++;
					if (current < end && current[0].tolower () == 'l') {
						current++;
					}
				}
				break;
			case 'u':
			case 'U':
				if (type == TokenType.INTEGER_LITERAL) {
					current++;
					if (current < end && current[0].tolower () == 'l') {
						current++;
						if (current < end && current[0].tolower () == 'l') {
							current++;
						}
					}
				}
				break;
			case 'f':
			case 'F':
			case 'd':
			case 'D':
				type = TokenType.REAL_LITERAL;
				current++;
				break;
			}

			if (!real_literal && is_ident_char (current[0])) {
				// allow identifiers to start with a digit
				// as long as they contain at least one char
				while (current < end && is_ident_char (current[0])) {
					current++;
				}
				type = TokenType.IDENTIFIER;
			}
		}

		return type;
	}

	public TokenType read_token (out SourceLocation token_begin, out SourceLocation token_end) {
		space ();

		TokenType type;
		char* begin = current;
		token_begin.pos = begin;
		token_begin.line = line;
		token_begin.column = column;

		int token_length_in_chars = -1;

		if (current >= end) {
			type = TokenType.EOF;
		} else if (current[0].isalpha () || current[0] == '_') {
			int len = 0;
			while (current < end && is_ident_char (current[0])) {
				current++;
				len++;
			}
			type = get_identifier_or_keyword (begin, len);
		} else if (current[0] == '@') {
			token_begin.pos++; // @ is not part of the identifier
			current++;
			int len = 0;
			while (current < end && is_ident_char (current[0])) {
				current++;
				len++;
			}
			type = TokenType.IDENTIFIER;
		} else if (current[0].isdigit ()) {
			type = read_number ();
		} else {
			switch (current[0]) {
			case '{':
				type = TokenType.OPEN_BRACE;
				current++;
				break;
			case '}':
				type = TokenType.CLOSE_BRACE;
				current++;
				break;
			case '(':
				type = TokenType.OPEN_PARENS;
				current++;
				break;
			case ')':
				type = TokenType.CLOSE_PARENS;
				current++;
				break;
			case '[':
				type = TokenType.OPEN_BRACKET;
				current++;
				break;
			case ']':
				type = TokenType.CLOSE_BRACKET;
				current++;
				break;
			case '.':
				type = TokenType.DOT;
				current++;
				if (current < end - 1) {
					if (current[0] == '.' && current[1] == '.') {
						type = TokenType.ELLIPSIS;
						current += 2;
					}
				}
				break;
			case ':':
				type = TokenType.COLON;
				current++;
				if (current < end && current[0] == ':') {
					type = TokenType.DOUBLE_COLON;
					current++;
				}
				break;
			case ',':
				type = TokenType.COMMA;
				current++;
				break;
			case ';':
				type = TokenType.SEMICOLON;
				current++;
				break;
			case '#':
				type = TokenType.HASH;
				current++;
				break;
			case '?':
				type = TokenType.INTERR;
				current++;
				break;
			case '|':
				type = TokenType.BITWISE_OR;
				current++;
				if (current < end) {
					switch (current[0]) {
					case '=':
						type = TokenType.ASSIGN_BITWISE_OR;
						current++;
						break;
					case '|':
						type = TokenType.OP_OR;
						current++;
						break;
					}
				}
				break;
			case '&':
				type = TokenType.BITWISE_AND;
				current++;
				if (current < end) {
					switch (current[0]) {
					case '=':
						type = TokenType.ASSIGN_BITWISE_AND;
						current++;
						break;
					case '&':
						type = TokenType.OP_AND;
						current++;
						break;
					}
				}
				break;
			case '^':
				type = TokenType.CARRET;
				current++;
				if (current < end && current[0] == '=') {
					type = TokenType.ASSIGN_BITWISE_XOR;
					current++;
				}
				break;
			case '~':
				type = TokenType.TILDE;
				current++;
				break;
			case '=':
				type = TokenType.ASSIGN;
				current++;
				if (current < end) {
					switch (current[0]) {
					case '=':
						type = TokenType.OP_EQ;
						current++;
						break;
					case '>':
						type = TokenType.LAMBDA;
						current++;
						break;
					}
				}
				break;
			case '<':
				type = TokenType.OP_LT;
				current++;
				if (current < end) {
					switch (current[0]) {
					case '=':
						type = TokenType.OP_LE;
						current++;
						break;
					case '<':
						type = TokenType.OP_SHIFT_LEFT;
						current++;
						if (current < end && current[0] == '=') {
							type = TokenType.ASSIGN_SHIFT_LEFT;
							current++;
						}
						break;
					}
				}
				break;
			case '>':
				type = TokenType.OP_GT;
				current++;
				if (current < end && current[0] == '=') {
					type = TokenType.OP_GE;
					current++;
				}
				break;
			case '!':
				type = TokenType.OP_NEG;
				current++;
				if (current < end && current[0] == '=') {
					type = TokenType.OP_NE;
					current++;
				}
				break;
			case '+':
				type = TokenType.PLUS;
				current++;
				if (current < end) {
					switch (current[0]) {
					case '=':
						type = TokenType.ASSIGN_ADD;
						current++;
						break;
					case '+':
						type = TokenType.OP_INC;
						current++;
						break;
					}
				}
				break;
			case '-':
				type = TokenType.MINUS;
				current++;
				if (current < end) {
					switch (current[0]) {
					case '=':
						type = TokenType.ASSIGN_SUB;
						current++;
						break;
					case '-':
						type = TokenType.OP_DEC;
						current++;
						break;
					case '>':
						type = TokenType.OP_PTR;
						current++;
						break;
					}
				}
				break;
			case '*':
				type = TokenType.STAR;
				current++;
				if (current < end && current[0] == '=') {
					type = TokenType.ASSIGN_MUL;
					current++;
				}
				break;
			case '/':
				type = TokenType.DIV;
				current++;
				if (current < end && current[0] == '=') {
					type = TokenType.ASSIGN_DIV;
					current++;
				}
				break;
			case '%':
				type = TokenType.PERCENT;
				current++;
				if (current < end && current[0] == '=') {
					type = TokenType.ASSIGN_PERCENT;
					current++;
				}
				break;
			case '\'':
			case '"':
				if (begin[0] == '\'') {
					type = TokenType.CHARACTER_LITERAL;
				} else if (current < end - 6 && begin[1] == '"' && begin[2] == '"') {
					type = TokenType.VERBATIM_STRING_LITERAL;
					token_length_in_chars = 6;
					current += 3;
					while (current < end - 4) {
						if (current[0] == '"' && current[1] == '"' && current[2] == '"') {
							break;
						} else if (current[0] == '\n') {
							current++;
							line++;
							column = 1;
							token_length_in_chars = 3;
						} else {
							unichar u = ((string) current).get_char_validated ((long) (end - current));
							if (u != (unichar) (-1)) {
								current += u.to_utf8 (null);
								token_length_in_chars++;
							} else {
								Report.error (new SourceReference (source_file, line, column + token_length_in_chars, line, column + token_length_in_chars), "invalid UTF-8 character");
							}
						}
					}
					if (current[0] == '"' && current[1] == '"' && current[2] == '"') {
						current += 3;
					} else {
						Report.error (new SourceReference (source_file, line, column + token_length_in_chars, line, column + token_length_in_chars), "syntax error, expected \"\"\"");
					}
					break;
				} else {
					type = TokenType.STRING_LITERAL;
				}
				token_length_in_chars = 2;
				current++;
				while (current < end && current[0] != begin[0]) {
					if (current[0] == '\\') {
						current++;
						token_length_in_chars++;
						if (current < end && current[0] == 'x') {
							// hexadecimal escape character
							current++;
							token_length_in_chars++;
							while (current < end && current[0].isxdigit ()) {
								current++;
								token_length_in_chars++;
							}
						} else {
							current++;
							token_length_in_chars++;
						}
					} else if (current[0] == '\n') {
						break;
					} else {
						unichar u = ((string) current).get_char_validated ((long) (end - current));
						if (u != (unichar) (-1)) {
							current += u.to_utf8 (null);
							token_length_in_chars++;
						} else {
							Report.error (new SourceReference (source_file, line, column + token_length_in_chars, line, column + token_length_in_chars), "invalid UTF-8 character");
						}
					}
				}
				if (current < end && current[0] != '\n') {
					current++;
				} else {
					Report.error (new SourceReference (source_file, line, column + token_length_in_chars, line, column + token_length_in_chars), "syntax error, expected %c".printf (begin[0]));
				}
				break;
			default:
				unichar u = ((string) current).get_char_validated ((long) (end - current));
				if (u != (unichar) (-1)) {
					current += u.to_utf8 (null);
					Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, unexpected character");
				} else {
					current++;
					Report.error (new SourceReference (source_file, line, column, line, column), "invalid UTF-8 character");
				}
				column++;
				return read_token (out token_begin, out token_end);
			}
		}

		if (token_length_in_chars < 0) {
			column += (int) (current - begin);
		} else {
			column += token_length_in_chars;
		}

		token_end.pos = current;
		token_end.line = line;
		token_end.column = column - 1;

		return type;
	}

	bool matches (char* begin, string keyword) {
		char* keyword_array = keyword;
		long len = keyword.len ();
		for (int i = 0; i < len; i++) {
			if (begin[i] != keyword_array[i]) {
				return false;
			}
		}
		return true;
	}

	bool pp_whitespace () {
		bool found = false;
		while (current < end && current[0].isspace () && current[0] != '\n') {
			found = true;
			current++;
			column++;
		}
		return found;
	}

	void pp_directive () {
		// hash sign
		current++;
		column++;

		pp_whitespace ();

		char* begin = current;
		int len = 0;
		while (current < end && current[0].isalnum ()) {
			current++;
			column++;
			len++;
		}

		if (len == 2 && matches (begin, "if")) {
			parse_pp_if ();
		} else if (len == 4 && matches (begin, "elif")) {
			parse_pp_elif ();
		} else if (len == 4 && matches (begin, "else")) {
			parse_pp_else ();
		} else if (len == 5 && matches (begin, "endif")) {
			parse_pp_endif ();
		} else {
			Report.error (new SourceReference (source_file, line, column - len, line, column), "syntax error, invalid preprocessing directive");
		}

		if (conditional_stack.length > 0
		    && conditional_stack[conditional_stack.length - 1].skip_section) {
			// skip lines until next preprocessing directive
			bool bol = false;
			while (current < end) {
				if (bol && current[0] == '#') {
					// go back to begin of line
					current -= column;
					column = 0;
					return;
				}
				if (current[0] == '\n') {
					line++;
					column = 0;
					bol = true;
				} else if (!current[0].isspace ()) {
					bol = false;
				}
				current++;
				column++;
			}
		}
	}

	void pp_eol () {
		pp_whitespace ();
		if (current >= end || current[0] != '\n') {
			Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, expected newline");
		}
	}

	void parse_pp_if () {
		pp_whitespace ();

		bool condition = parse_pp_expression ();

		pp_eol ();

		conditional_stack += Conditional ();

		if (condition && (conditional_stack.length == 1 || !conditional_stack[conditional_stack.length - 2].skip_section)) {
			// condition true => process code within if
			conditional_stack[conditional_stack.length - 1].matched = true;
		} else {
			// skip lines until next preprocessing directive
			conditional_stack[conditional_stack.length - 1].skip_section = true;
		}
	}

	void parse_pp_elif () {
		pp_whitespace ();

		bool condition = parse_pp_expression ();

		pp_eol ();

		if (conditional_stack.length == 0 || conditional_stack[conditional_stack.length - 1].else_found) {
			Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, unexpected #elif");
			return;
		}

		if (condition && !conditional_stack[conditional_stack.length - 1].matched
		    && (conditional_stack.length == 1 || !conditional_stack[conditional_stack.length - 2].skip_section)) {
			// condition true => process code within if
			conditional_stack[conditional_stack.length - 1].matched = true;
			conditional_stack[conditional_stack.length - 1].skip_section = false;
		} else {
			// skip lines until next preprocessing directive
			conditional_stack[conditional_stack.length - 1].skip_section = true;
		}
	}

	void parse_pp_else () {
		pp_eol ();

		if (conditional_stack.length == 0 || conditional_stack[conditional_stack.length - 1].else_found) {
			Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, unexpected #else");
			return;
		}

		if (!conditional_stack[conditional_stack.length - 1].matched
		    && (conditional_stack.length == 1 || !conditional_stack[conditional_stack.length - 2].skip_section)) {
			// condition true => process code within if
			conditional_stack[conditional_stack.length - 1].matched = true;
			conditional_stack[conditional_stack.length - 1].skip_section = false;
		} else {
			// skip lines until next preprocessing directive
			conditional_stack[conditional_stack.length - 1].skip_section = true;
		}
	}

	void parse_pp_endif () {
		pp_eol ();

		if (conditional_stack.length == 0) {
			Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, unexpected #endif");
			return;
		}

		conditional_stack.length--;
	}

	bool parse_pp_symbol () {
		int len = 0;
		while (current < end && is_ident_char (current[0])) {
			current++;
			column++;
			len++;
		}

		if (len == 0) {
			Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, expected identifier");
			return false;
		}

		string identifier = ((string) (current - len)).ndup (len);
		bool defined;
		if (identifier == "true") {
			defined = true;
		} else if (identifier == "false") {
			defined = false;
		} else {
			defined = source_file.context.is_defined (identifier);
		}

		return defined;
	}

	bool parse_pp_primary_expression () {
		if (current >= end) {
			Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, expected identifier");
		} else if (is_ident_char (current[0])) {
			return parse_pp_symbol ();
		} else if (current[0] == '(') {
			current++;
			column++;
			pp_whitespace ();
			bool result = parse_pp_expression ();
			pp_whitespace ();
			if (current < end && current[0] ==  ')') {
				current++;
				column++;
			} else {
				Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, expected `)'");
			}
			return result;
		} else {
			Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, expected identifier");
		}
		return false;
	}

	bool parse_pp_unary_expression () {
		if (current < end && current[0] == '!') {
			current++;
			column++;
			pp_whitespace ();
			return !parse_pp_unary_expression ();
		}

		return parse_pp_primary_expression ();
	}

	bool parse_pp_equality_expression () {
		bool left = parse_pp_unary_expression ();
		pp_whitespace ();
		while (true) {
			if (current < end - 1 && current[0] == '=' && current[1] == '=') {
				current += 2;
				column += 2;
				pp_whitespace ();
				bool right = parse_pp_unary_expression ();
				left = (left == right);
			} else if (current < end - 1 && current[0] == '!' && current[1] == '=') {
				current += 2;
				column += 2;
				pp_whitespace ();
				bool right = parse_pp_unary_expression ();
				left = (left != right);
			} else {
				break;
			}
		}
		return left;
	}

	bool parse_pp_and_expression () {
		bool left = parse_pp_equality_expression ();
		pp_whitespace ();
		while (current < end - 1 && current[0] == '&' && current[1] == '&') {
			current += 2;
			column += 2;
			pp_whitespace ();
			bool right = parse_pp_equality_expression ();
			left = left && right;
		}
		return left;
	}

	bool parse_pp_or_expression () {
		bool left = parse_pp_and_expression ();
		pp_whitespace ();
		while (current < end - 1 && current[0] == '|' && current[1] == '|') {
			current += 2;
			column += 2;
			pp_whitespace ();
			bool right = parse_pp_and_expression ();
			left = left || right;
		}
		return left;
	}

	bool parse_pp_expression () {
		return parse_pp_or_expression ();
	}

	bool whitespace () {
		bool found = false;
		bool bol = (column == 1);
		while (current < end && current[0].isspace ()) {
			if (current[0] == '\n') {
				line++;
				column = 0;
				bol = true;
			}
			found = true;
			current++;
			column++;
		}
		if (bol && current[0] == '#') {
			pp_directive ();
			return true;
		}
		return found;
	}

	bool comment () {
		if (current > end - 2
		    || current[0] != '/'
		    || (current[1] != '/' && current[1] != '*')) {
			return false;
		}

		if (current[1] == '/') {
			// single-line comment
			current += 2;
			char* begin = current;
			// skip until end of line or end of file
			while (current < end && current[0] != '\n') {
				current++;
			}
			push_comment (((string) begin).ndup ((long) (current - begin)), line == 1);
		} else {
			// delimited comment
			current += 2;
			char* begin = current;
			int begin_line = line;
			while (current < end - 1
			       && (current[0] != '*' || current[1] != '/')) {
				if (current[0] == '\n') {
					line++;
					column = 0;
				}
				current++;
				column++;
			}
			if (current == end - 1) {
				Report.error (new SourceReference (source_file, line, column, line, column), "syntax error, expected */");
				return true;
			}
			push_comment (((string) begin).ndup ((long) (current - begin)), begin_line == 1);
			current += 2;
			column += 2;
		}

		return true;
	}

	void space () {
		while (whitespace () || comment ()) {
		}
	}

	void push_comment (string comment_item, bool file_comment) {
		if (_comment == null) {
			_comment = comment_item;
		} else {
			_comment = "%s\n%s".printf (_comment, comment_item);
		}
		if (file_comment) {
			source_file.comment = _comment;
			_comment = null;
		}
	}
	
	/**
	 * Clears and returns the content of the comment stack.
	 *
	 * @return saved comment
	 */
	public string? pop_comment () {
		if (_comment == null) {
			return null;
		}
		
		var result_builder = new StringBuilder (_comment);
		_comment = null;
		
		weak string index;
		while ((index = result_builder.str.chr (-1, '\t')) != null) {
			result_builder.erase (result_builder.str.pointer_to_offset (index), 1);
		}
		
		return result_builder.str;
	}
}

