(*
 * Copyright yutopp 2015 - .
 *
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *)

%parameter <Mi : Module_info.INFO_TYPE>
%start <Ast.t> program_entry

%nonassoc IFX
%nonassoc KEYWORD_ELSE

%{
    let templatefy name node opt_tparams =
        match opt_tparams with
        | Some tparams -> Ast.TemplateStmt (name, tparams, node)
        | None -> node
%}

%%

(**)
program_entry:
                prog_module EOF { $1 }

prog_module:
                m = module_decl
                body = top_level_statements
                {
                    let (full_base_dir, pkg_names, mod_name) = m in
                    Ast.Module (body, pkg_names, mod_name, full_base_dir, ())
                }

module_decl:
                (* empty *)
                { (Mi.full_filepath, Mi.package_names, Mi.module_name) }

        |       xs = separated_nonempty_list(DOT, rel_id_has_no_op_as_raw)
                {
                    let rev_xs = List.rev xs in
                    let pkg_names = List.rev (List.tl rev_xs) in
                    let mod_name = List.hd rev_xs in
                    (Mi.full_filepath, pkg_names, mod_name)
                }


top_level_statements:
                top_level_statement* { Ast.StatementList $1 }


(* statements *)

top_level_statement:
                attribute top_level_statement_ { Ast.AttrWrapperStmt ($1, $2) }
        |       top_level_statement_ { $1 }

top_level_statement_:
                empty_statement { $1 }
        |       function_decl_statement { $1 }
        |       class_decl_statement { $1 }
        |       extern_statement { $1 }
        |       import_statement { $1 }

empty_statement:
                SEMICOLON { Ast.EmptyStmt }

import_statement:
                KEYWORD_IMPORT
                xs = separated_nonempty_list(DOT, rel_id_has_no_op_as_raw)
                {
                    let rev_xs = List.rev xs in
                    let pkg_names = List.rev (List.tl rev_xs) in
                    let mod_name = List.hd rev_xs in
                    Ast.ImportStmt (pkg_names, mod_name, ())
                }


function_decl_statement:
                KEYWORD_DEF
                name = rel_id_as_s
                opt_tparams = template_parameter_variables_decl_list?
                params = parameter_variables_decl_list
                ret_type = type_specifier?
                t_cond = when_cond?
                body = function_decl_body_block
                {
                    let n = Ast.FunctionDefStmt (name, params, ret_type, t_cond, body, None, ()) in
                    templatefy name n opt_tparams
                }

when_cond:
                KEYWORD_WHEN expression { $2 }

function_decl_body_block:
                function_body_block             { $1 }
        |       function_lambda_block SEMICOLON { $1 }

function_body_block:
                LBLOCK
                program_body_statements_list
                RBLOCK
                { $2 }

function_lambda_block:
                FAT_ARROW
                expr = expression
                { Ast.ExprStmt expr }


member_function_declaration_statement:
                KEYWORD_DEF
                name = rel_id_as_s
                opt_tparams = template_parameter_variables_decl_list?
                params = parameter_variables_decl_list
                ret_type = type_specifier?
                body = function_decl_body_block
                {
                    let n = Ast.MemberFunctionDefStmt (name, params, ret_type, body, None, ()) in
                    templatefy name n opt_tparams
                }


(**)
parameter_variables_decl_list:
                LPAREN
                separated_list(COMMA, parameter_variable_declaration)
                RPAREN { Ast.ParamsList $2 }

parameter_variable_decl_introducer:
                rv = rv_attr
                mut = mut_attr
                {
                    let attr = {
                        Type_attr.ta_ref_val = rv;
                        Type_attr.ta_mut = mut;
                    } in
                    attr
                }

parameter_variable_declaration:
                parameter_variable_initializer_unit { $1 }

parameter_variable_initializer_unit:
                parameter_variable_decl_introducer
                rel_id_has_no_op_as_raw?
                value_initializer_unit { ($1, $2, $3) }


(**)
template_parameter_variables_decl_list:
                NOT
                LPAREN
                separated_nonempty_list(COMMA, template_parameter_variable_declaration)
                RPAREN { Ast.TemplateParamsList $3 }

template_parameter_variable_declaration:
                template_parameter_variable_initializer_unit { $1 }

template_parameter_variable_initializer_unit:
                rel_id_has_no_op_as_raw
                value_initializer_unit? { ($1, $2) }


(*
    = 5
    :int
    :int = 5
*)
value_initializer_unit:
                value_initializer_unit_only_value { (None, Some $1) }
        |       type_specifier value_initializer_unit_only_value? { (Some $1, $2) }


value_initializer_unit_only_value:
                ASSIGN expression { $2 }


(**)
class_decl_statement:
                class_decl_statement_ { $1 }

class_decl_statement_:
                KEYWORD_CLASS
                name = rel_id_as_s
                ml = meta_level
                body = class_decl_body_block
                { Ast.ClassDefStmt (name, body, None, () )}

class_decl_body_block:
                class_body_block    { $1 }

class_body_block:
                LBLOCK
                class_body_statements_list
                RBLOCK
                { $2 }

class_body_statement:
                attribute class_body_statement_ { Ast.AttrWrapperStmt ($1, $2) }
        |       class_body_statement_ { $1 }

class_body_statement_:
                member_variable_declaration_statement { $1 }
        |       member_function_declaration_statement { $1 }
        |       empty_statement { $1 }

class_body_statements_list:
                class_body_statement* { Ast.StatementList ($1) }


member_variable_declaration_statement:
                member_variable_declararion SEMICOLON
                {
                    Ast.MemberVariableDefStmt ($1, ())
                }

member_variable_declararion:
                member_variable_initializer_unit
                {
                    Ast.VarInit $1
                }

(* TODO: change rel_id_has_no_op_as_raw to generic_rel_id_has_no_op to support template variables *)
member_variable_initializer_unit:
                member_variable_decl_introducer
                rel_id_has_no_op_as_raw
                value_initializer_unit { ($1, $2, $3) }

member_variable_decl_introducer:
                rv = rv_attr_val
                mut = mut_attr_mutable_def
                {
                    let attr = {
                        Type_attr.ta_ref_val = rv;
                        Type_attr.ta_mut = mut;
                    } in
                    attr
                }


(**)
extern_statement:
                KEYWORD_EXTERN
                extern_statement_ { $2 }

extern_statement_:
                extern_function_statement { $1 }
        |       extern_class_statement { $1 }

extern_function_statement:
                KEYWORD_DEF
                rel_id_as_s
                parameter_variables_decl_list
                type_specifier
                ASSIGN
                STRING (*string_lit*)
                { Ast.ExternFunctionDefStmt ($2, $3, $4, $6, None, ()) }

extern_class_statement:
                KEYWORD_CLASS
                name = rel_id_as_s
                opt_tparams = template_parameter_variables_decl_list?
                ml = meta_level
                ASSIGN
                body_name = STRING (*string_lit*)
                {
                    let n = Ast.ExternClassDefStmt (name, body_name, None, ()) in
                    templatefy name n opt_tparams
                }

return_statement:
                KEYWORD_RETURN
                e = expression?
                SEMICOLON
                { Ast.ReturnStmt e }


(**)
program_body_statement:
                attribute program_body_statement_ { Ast.AttrWrapperStmt ($1, $2) }
        |       program_body_statement_ { $1 }

program_body_statement_:
                empty_statement { $1 }
        |       expression_statement { $1 }
        |       variable_declaration_statement { $1 }
        |       return_statement { $1 }

program_body_statements_list:
                program_body_statement* { Ast.StatementList ($1) }


(**)
type_specifier:
                COLON id_expression { $2 }


(**)
rv_attr_force:
                KEYWORD_VAL { Type_attr.Val }
        |       KEYWORD_REF { Type_attr.Ref }

rv_attr_val:
                KEYWORD_VAL { Type_attr.Val }

rv_attr:
                { Type_attr.Ref }   (* default *)
        |       rv_attr_force { $1 }

mut_attr_force:
                KEYWORD_IMMUTABLE   { Type_attr.Immutable }
        |       KEYWORD_CONST       { Type_attr.Const }
        |       KEYWORD_MUTABLE     { Type_attr.Mutable }

mut_attr:
                { Type_attr.Const } (* default *)
        |       mut_attr_force { $1 }

mut_attr_mutable_def:
                { Type_attr.Mutable } (* default *)
        |       mut_attr_force { $1 }


meta_level:
                { Meta_level.Runtime }  (* default *)
        |       KEYWORD_ONLY_META       { Meta_level.OnlyMeta }
        |       KEYWORD_META            { Meta_level.Meta }
        |       KEYWORD_RUNTIME         { Meta_level.Runtime }
        |       KEYWORD_ONLY_RUNTIME    { Meta_level.OnlyRuntime }


variable_declaration_statement:
                meta_level
                variable_declararion
                SEMICOLON
                {
                    Ast.VariableDefStmt ($1, $2, ())
                }

variable_declararion:
                vi = variable_initializer_unit
                {
                    Ast.VarInit vi
                }

(* TODO: change rel_id_has_no_op_as_raw to generic_rel_id_has_no_op to support template variables *)
variable_initializer_unit:
                variable_decl_introducer
                rel_id_has_no_op_as_raw
                value_initializer_unit { ($1, $2, $3) }

variable_decl_introducer:
                rv = rv_attr_force
                mut = mut_attr
                {
                    let attr = {
                        Type_attr.ta_ref_val = rv;
                        Type_attr.ta_mut = mut;
                    } in
                    attr
                }


(**)
argument_list:
                LPAREN
                l = separated_list(COMMA, expression)
                RPAREN { l }

template_argument_list:
                NOT
                LPAREN
                l = separated_nonempty_list(COMMA, expression)
                RPAREN
                { l }

        |       NOT
                v = primary_value
                { [v] }

(**)
expression_statement:
                expression SEMICOLON { Ast.ExprStmt $1 }


(**)
id_expression:
                logical_or_expression { $1 }


expression:
                assign_expression { $1 }

assign_expression:  (* right to left *)
                logical_or_expression { $1 }
        |       logical_or_expression ASSIGN assign_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "=", $3) }
        |       if_expression { $1 }
        |       for_expression { $1 }

if_expression:
                KEYWORD_IF
                LPAREN cond = expression RPAREN
                then_n = expression %prec IFX
                { Ast.IfExpr (cond, then_n, None) }
        |       KEYWORD_IF
                LPAREN cond = expression RPAREN
                then_n = expression
                KEYWORD_ELSE
                else_n = expression
                { Ast.IfExpr (cond, then_n, Some else_n) }

for_expression:
                KEYWORD_FOR
                LPAREN
                opt_decl = variable_declararion?
                SEMICOLON
                opt_cond = expression?
                SEMICOLON
                opt_inc = expression?
                RPAREN
                body = expression
                {
                    let opt_decl_stmt = match opt_decl with
                      | Some decl ->
                          Some (Ast.VariableDefStmt (Meta_level.Runtime, decl, ()))
                      | None -> None
                    in
                    Ast.ForExpr (opt_decl_stmt, opt_cond, opt_inc, body)
                }

logical_or_expression:
                logical_and_expression { $1 }
        |       logical_or_expression LOGICAL_OR logical_and_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "||", $3) }

logical_and_expression:
                bitwise_or_expression { $1 }
        |       logical_and_expression LOGICAL_AND bitwise_or_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "&&", $3) }

bitwise_or_expression:
                bitwise_xor_expression { $1 }
        |       bitwise_or_expression BITWISE_OR bitwise_xor_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "|", $3) }

bitwise_xor_expression:
                bitwise_and_expression { $1 }
        |       bitwise_xor_expression BITWISE_XOR bitwise_and_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "^", $3) }

bitwise_and_expression:
                equality_expression { $1 }
        |       bitwise_and_expression BITWISE_AND equality_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "&", $3) }

equality_expression:
                relational_expression { $1 }
        |       equality_expression EQUALS relational_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "==", $3) }
        |       equality_expression NOT_EQUALS relational_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "!=", $3) }

relational_expression:
                shift_expression { $1 }
        |       relational_expression LTE shift_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "<=", $3) }
        |       relational_expression LT shift_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "<", $3) }
        |       relational_expression GTE shift_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp ">=", $3) }
        |       relational_expression GT shift_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp ">", $3) }

shift_expression:
                add_sub_expression { $1 }
        |       shift_expression LSHIFT add_sub_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "<<", $3) }
        |       shift_expression RSHIFT add_sub_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp ">>", $3) }

add_sub_expression:
                mul_div_rem_expression { $1 }
        |       add_sub_expression PLUS mul_div_rem_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "+", $3) }
        |       add_sub_expression MINUS mul_div_rem_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "-", $3) }

mul_div_rem_expression:
                unary_expression { $1 }
        |       mul_div_rem_expression TIMES unary_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "*", $3) }
        |       mul_div_rem_expression DIV unary_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "/", $3) }
        |       mul_div_rem_expression MOD unary_expression
                { Ast.BinaryOpExpr ($1, Nodes.BinaryOp "%", $3) }

unary_expression:
                postfix_expression { $1 }
        |       op = MINUS postfix_expression
                { Ast.UnaryOpExpr( Nodes.UnaryPreOp op, $2) }
        |       op = INCREMENT postfix_expression
                { Ast.UnaryOpExpr( Nodes.UnaryPreOp op, $2) }
        |       op = DECREMENT postfix_expression
                { Ast.UnaryOpExpr( Nodes.UnaryPreOp op, $2) }
        |       op = NOT postfix_expression
                { Ast.UnaryOpExpr( Nodes.UnaryPreOp op, $2) }


postfix_expression:
                primary_expression { $1 }
        |       postfix_expression DOT rel_generic_id
                { Ast.ElementSelectionExpr ($1, $3, ()) }
        |       postfix_expression LBRACKET expression? RBRACKET
                { Ast.SubscriptingExpr ($1, $3) }
        |       traits_expression { $1 }
        |       postfix_expression argument_list
                { Ast.CallExpr ($1, $2) }

traits_expression:
                statement_traits_expression { $1 }

statement_traits_expression:
                KEYWORD_UU_STMT_TRAITS
                LPAREN
                t = rel_id_has_no_op_as_raw
                COMMA
                s = scope_expression
                RPAREN
                { Ast.StatementTraitsExpr (t, s) }

primary_expression:
                primary_value { $1 }
        |       LPAREN expression RPAREN { $2 }
        |       scope_expression { $1 }

scope_expression:
                LBLOCK
                stmts = program_body_statements_list
                RBLOCK
                { Ast.ScopeExpr (stmts) }

(**)
primary_value:
                boolean_literal { $1 }
        |       numeric_literal { $1 }
        |       string_literal { $1 }
        |       array_literal { $1 }
        |       generic_id { $1 }


(**)
rel_id:         rel_id_as_s { Ast.Id ($1, ()) }

rel_template_instance_id:
                rel_id_as_s template_argument_list
                { Ast.InstantiatedId ($1, $2, ()) }

rel_generic_id:
                rel_id { $1 }
        |       rel_template_instance_id { $1 }

(* TODO: implement root_generic_id *)

generic_id:
                rel_generic_id { $1 }


(**)
rel_id_has_no_op_as_raw:
                ID { $1 }

rel_id_has_no_op_as_s:
                rel_id_has_no_op_as_raw { Nodes.Pure ($1) }

rel_id_as_s:
                binary_operator_as_s { $1 }
        |       unary_operator_as_s { $1 }
        |       rel_id_has_no_op_as_s { $1 }

binary_operator_as_raw:
                PLUS { $1 }
        |       MINUS { $1 }
        |       TIMES { $1 }
        |       DIV { $1 }
        |       MOD { $1 }
        |       GT { $1 }
        |       GTE { $1 }
        |       LT { $1 }
        |       LTE { $1 }
        |       LSHIFT { $1 }
        |       RSHIFT { $1 }
        |       EQUALS { $1 }
        |       NOT_EQUALS { $1 }
        |       LOGICAL_OR { $1 }
        |       LOGICAL_AND { $1 }
        |       BITWISE_AND { $1 }
        |       BITWISE_OR { $1 }
        |       BITWISE_XOR { $1 }

binary_operator_as_s:
                KEYWORD_OPERATOR
                op = binary_operator_as_raw { Nodes.BinaryOp (op) }

unary_operator_as_raw:
                INCREMENT { $1 }
        |       DECREMENT { $1 }
        |       NOT { $1 }

unary_operator_as_s:
                KEYWORD_OPERATOR
                order = ID
                op = unary_operator_as_raw
                {
                    match order with
                    | "pre" -> Nodes.UnaryPreOp (op)
                    | "post" -> Nodes.UnaryPostOp (op)
                    | _ -> failwith "[ICE] ..."
                }


(**)
boolean_literal:
                LIT_TRUE { Ast.BoolLit (true, ()) }
        |       LIT_FALSE { Ast.BoolLit (false, ()) }

numeric_literal:
                INT { Ast.Int32Lit ($1, ()) }

string_literal:
                STRING { Ast.StringLit ($1, ()) }

array_literal:
                LBRACKET
                elems = separated_list(COMMA, expression)
                RBRACKET
                { Ast.ArrayLit (elems, ()) }

(**)
attribute:
                SHARP LBRACKET separated_list(COMMA, attribute_pair) RBRACKET
                {
                    let pair_list = $3 in
                    let m = Hashtbl.create (List.length pair_list) in
                    List.iter (fun (k, v) -> Hashtbl.add m k v) pair_list;
                    m
                }

attribute_pair:
                attribute_key attribute_value? { ($1, $2) }

attribute_key:
                rel_id_has_no_op_as_raw { $1 }

attribute_value:
                ASSIGN logical_or_expression { $2 }
