(*
 * Copyright yutopp 2015 - .
 *
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *)

open Batteries
open Type_sets


module TAst = Tagged_ast

type type_info_t = TAst.ast Env.type_info_t
type ctfe_value_t = type_info_t Ctfe_value.t

type 'env ctx_t = {
  sc_root_env       : 'env;
  mutable sc_builtin_m_env  : 'env option;

  sc_module_bag         : 'env Module_info.Bag.t;
  sc_module_search_dirs : string list;

  (* ctfe engine *)
  sc_ctfe_engine    : Ctfe_engine.t;

  (* type sets *)
  sc_tsets          : 'env type_sets_t;

  (* for template *)
  sc_unification_ctx    : (type_info_t, ctfe_value_t) Unification.t;
}


let check_env env =
  Env.update_status env Env.Checking

let complete_env env node =
  Env.update_status env Env.Complete;
  Env.update_rel_ast env node

let check_is_args_valid ty =
  (* TODO: implement *)
  ()

let complete_function_env env node s_name param_types return_type detail_r ctx =
  let r = Env.FunctionOp.get_record env in
  r.Env.fn_param_types <- param_types;
  r.Env.fn_return_type <- return_type;
  r.Env.fn_detail <- detail_r;

  let _ = match s_name with
    | s when s = Builtin_info.entrypoint_name ->
       begin
         (* TODO: check param_types and return_type *)
         r.Env.fn_mangled <- Some "main"
       end
    | _ ->
       begin
         let template_vars =
           r.Env.fn_templare_var_ids
           |> List.map (Unification.get_as_value ctx.sc_unification_ctx)
         in
         let mangled =
           Mangle.s_of_function (Env.get_full_module_name env) s_name
                                template_vars
                                param_types return_type
                                ctx.sc_tsets
         in
         r.Env.fn_mangled <- Some mangled
       end
  in

  complete_env env node


module FuncMatchLevel =
  struct
    type t =
      | ExactMatch
      | QualConv
      | ImplicitConv
      | NoMatch

    let to_int = function
      | ExactMatch      -> 0
      | QualConv        -> 1
      | ImplicitConv    -> 2
      | NoMatch         -> 3

    let of_int = function
      | 0 -> ExactMatch
      | 1 -> QualConv
      | 2 -> ImplicitConv
      | 3 -> NoMatch
      | _ -> failwith "invalid"

    let bottom a b =
      of_int (max (to_int a) (to_int b))

    (* ascending order, ExactMatch -> ... -> NoMatch *)
    let compare a b =
      compare (to_int a) (to_int b)

    (* if 'a' is matched than 'b', returns true *)
    let is_better a b =
      (to_int a) < (to_int b)

    let is_same a b =
      (to_int a) = (to_int b)

    let to_string = function
      | ExactMatch      -> "ExactMatch"
      | QualConv        -> "QualConv"
      | ImplicitConv    -> "ImplicitConv"
      | NoMatch         -> "NoMatch"
  end
