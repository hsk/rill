open Batteries

module AstContext =
  struct
    type 'a current_ctx_t = ('a Env.env_t) option
    type 'a prev_ctx_t = Ast.ast
  end

module TaggedAst = Nodes.Make(AstContext)


type 'env type_info = 'env Type.info_t

type 'env shared_info = {
  si_type_gen      : 'env Type.Generator.t;

  (* buildin primitive types *)
  mutable si_type_type     : 'env type_info;
  mutable si_int_type      : 'env type_info;
}


let is_type ty ctx =
  Type.has_same_class ty ctx.si_type_type


let make_default_env () =
  Env.make_root_env ()

let make_default_context root_env =
  let ctx = {
    si_type_gen = Type.Generator.default ();
    si_type_type = Type.Generator.dummy_ty;
    si_int_type = Type.Generator.dummy_ty;
  } in

  let create_builtin_class name =
    let env = Env.create_env root_env (Env.Class (Env.empty_lookup_table (),
                                                  {
                                                    Env.cls_name = name;
                                                  })
                                  ) in
    Env.update_status env Env.Complete;
    env
  in
  let register_builtin_type name setter =
    let cenv = create_builtin_class name in
    Env.add_inner_env root_env name cenv;
    let ty = Type.Generator.generate_type ctx.si_type_gen cenv in
    setter ty
  in

  register_builtin_type "type" (fun ty -> ctx.si_type_type <- ty);
  register_builtin_type "int" (fun ty -> ctx.si_int_type <- ty);
  ctx

let make_default_state () =
  let env = make_default_env () in
  let ctx = make_default_context env in
  (env, ctx)


let check_env env =
  Env.update_status env Env.Checking

let complete_env env node =
  Env.update_status env Env.Complete;
  Env.update_rel_ast env node

let check_is_args_valid ty =
  (* TODO: implement *)
  ()


let rec solve_forward_refs node parent_env =
  match node with
  | Ast.Module (inner, _) ->
     begin
       let name = "module" in   (* "module" is a temporary name *)
       let env = Env.create_env parent_env (
                                  Env.Module (Env.empty_lookup_table (),
                                              {
                                                Env.mod_name = name;
                                              })
                                ) in
       Env.add_inner_env parent_env name env;

       let res_node = solve_forward_refs inner env in
       let node = TaggedAst.Module (res_node, Some env) in
       Env.update_rel_ast env node;
       node
     end

  | Ast.StatementList (nodes) ->
     let tagged_nodes = nodes |> List.map (fun n -> solve_forward_refs n parent_env) in
     TaggedAst.StatementList tagged_nodes

  | Ast.FunctionDefStmt (name, params, opt_ret_type, body, _) ->
     begin
       let name_s = Nodes.string_of_id_string name in
       let base_env = Env.find_or_add_multi_env parent_env name_s Env.Kind.Function in
       let fenv = Env.create_env parent_env (
                                   Env.Function (Env.empty_lookup_table ())
                                 ) in
       Env.MultiSetOp.add_candidates base_env fenv;

       let node = TaggedAst.FunctionDefStmt (
                      name,
                      TaggedAst.PrevPassNode params,
                      Option.map (fun x -> TaggedAst.PrevPassNode x) opt_ret_type,
                      TaggedAst.PrevPassNode body,
                      Some fenv
                    ) in
       Env.update_rel_ast fenv node;
       node
     end

  | Ast.ExternFunctionDefStmt (name, params, ret_type, extern_fname, _) ->
     begin
       let name_s = Nodes.string_of_id_string name in
       let base_env = Env.find_or_add_multi_env parent_env name_s Env.Kind.Function in
       let fenv = Env.create_env parent_env (
                                   Env.Function (Env.empty_lookup_table ~init:0 ())
                                 ) in
       Env.MultiSetOp.add_candidates base_env fenv;

       let node = TaggedAst.ExternFunctionDefStmt (
                      name,
                      TaggedAst.PrevPassNode params,
                      TaggedAst.PrevPassNode ret_type,
                      extern_fname,
                      Some fenv
                    ) in
       Env.update_rel_ast fenv node;
       node
     end

  | Ast.VariableDefStmt (rv, v, _) ->
     TaggedAst.VariableDefStmt (rv, TaggedAst.PrevPassNode v, None)

  | Ast.EmptyStmt -> TaggedAst.EmptyStmt

  | _ -> failwith "solve_forward_refs: unsupported node"


let rec construct_env node parent_env ctx =
  match node with
  | TaggedAst.Module (inner, Some env) ->
     begin
       construct_env inner env ctx
     end

  | TaggedAst.StatementList (nodes) ->
     let tagged_nodes = nodes |> List.map (fun n -> construct_env n parent_env ctx) in
     TaggedAst.StatementList tagged_nodes

  | TaggedAst.FunctionDefStmt (name, params_node, opt_ret_type, body, Some env) ->
     if Env.is_checked env then Env.get_rel_ast env
     else begin
       let name_s = Nodes.string_of_id_string name in
       Printf.printf "function %s - unchecked\n" name_s;
       check_env env;

       (* check parameters *)
       let params = check_params env node params_node ctx in

       (* infer return type *)

       (* body *)
       let nbody = analyze_inner body env ctx in

       Printf.printf "function %s - complete\n" name_s;
       let node = TaggedAst.FunctionDefStmt (
                      name,
                      TaggedAst.ParamsList params,
                      opt_ret_type, (* TODO: fix *)
                      nbody,
                      Some env
                    ) in
       complete_env env node;
       node
     end

  | TaggedAst.ExternFunctionDefStmt (name, params_node, ret_type, extern_fname, Some env) ->
     if Env.is_checked env then Env.get_rel_ast env
     else begin
       let name_s = Nodes.string_of_id_string name in
       Printf.printf "function %s - unchecked\n" name_s;
       check_env env;

       (* check parameters *)
       let params = check_params env node params_node ctx in

       (* infer return type *)

       (* body *)
       Printf.printf "function %s - complete\n" name_s;
       let node = TaggedAst.ExternFunctionDefStmt (
                      name,
                      TaggedAst.ParamsList params,
                      ret_type, (* TODO: fix *)
                      extern_fname,
                      Some env
                    ) in
       complete_env env node;
       node
       end

  | TaggedAst.VariableDefStmt (rv, v, opt_env) ->
     begin
       match opt_env with
       | Some env -> failwith "unexpected"
       | None ->
          begin
            let (var_name, init_term) =
              match extract_prev_pass_node v with
              | Ast.VarInit vi -> vi
              | _ -> failwith "unexpected node"
            in
            check_id_is_defined_uniquely parent_env var_name;

            let venv = Env.create_env parent_env (
                                        Env.Variable {
                                            Env.var_name = var_name;
                                          }
                                      )
            in
            Env.add_inner_env parent_env var_name venv;

            let (opt_type, opt_init_value) = init_term in
            let opt_init_value_res = match opt_init_value with
              | Some init_value -> Some (analyze_expr init_value parent_env ctx)
              | None -> None
            in
            let (type_node, value_node, var_ty) = match opt_type with
              (* variable type is specified *)
              | Some var_type ->
                 begin
                   failwith "not implemented"
                 end

              (* var_type is infered from initial_value *)
              | None ->
                 begin
                   let (node, var_ty) = match opt_init_value_res with
                     | Some v -> v
                     | None -> failwith "[ERROR] initial value is required";
                   in
                   (* TODO: check void value *)

                   (None, node, var_ty)
                 end
            in

            let node = TaggedAst.VariableDefStmt (
                           rv,
                           TaggedAst.VarInit (var_name, (type_node, Some value_node)),
                           Some venv
                         ) in

            complete_env venv node;
            node
          end
     end

  | TaggedAst.EmptyStmt -> node

  | _ -> failwith "construct_env: unsupported node or nodes have no valid env"

and analyze_expr node parent_env ctx =
  match node with
  | Ast.BinaryOpExpr (lhs, op, rhs) ->
     begin
       let args = [lhs; rhs] in
       let eargs = args |> List.map @@ fun n -> evaluate_invocation_arg n parent_env ctx in
       let args_type_details = eargs |> List.map Tuple2.second in
       List.iter check_is_args_valid args_type_details;
       let args_ty_recs = args_type_details |> List.map Type.as_unique in

       let opt_f_ty =
         find_suitable_operator ~universal_search:true
                                op args_ty_recs node parent_env ctx in
       match opt_f_ty with
       | Some f_ty ->
          begin
            failwith "!!!!!!!!!!!!!"
          end
       | None ->
          (* TODO: error message *)
          failwith "binary operator is not found"
     end

  | Ast.UnaryOpExpr (op, expr) ->
     begin
       failwith "u op"
     end

  | Ast.Id (name) as id_node ->
     begin
       (* WIP *)
       let ty = match solve_identifier id_node parent_env ctx with
           Some v -> v
         | None -> failwith "id not found"  (* TODO: change to exception *)
       in
       let node = TaggedAst.Id name in

       (node, ty)
     end

  | Ast.Int32Lit (i) ->
     begin
       (* WIP *)
       let ty = ctx.si_int_type in
       let node = TaggedAst.Int32Lit i in

       (node, ty)
     end

  | _ -> failwith "analyze_expr: unsupported node"


and analyze_inner node parent_env ctx =
  let pre_node = extract_prev_pass_node node in
  analyze pre_node parent_env ctx

and extract_prev_pass_node node =
  match node with
  | TaggedAst.PrevPassNode n -> n
  | _ -> failwith "not prev node"


and check_params env node params_node ctx =
  match params_node with
  | TaggedAst.PrevPassNode (Ast.ParamsList ps) ->
     (declare_function_params env node ps ctx)
  | _ -> failwith ""

and declare_function_params f_env node params ctx =
  let params = match node with
    | TaggedAst.FunctionDefStmt _ -> params
    | TaggedAst.ExternFunctionDefStmt _ -> params
    (* TODO: support functions that have recievers. ex, member function (this/self) *)
    | _ -> failwith "declare_function_params: not supported"
  in
  let f = to_type_detail_from_function_param f_env ctx in
  let param_types = List.map f params in
  ignore param_types;
  []


and check_id_is_defined_uniquely env id =
  let res = Env.find_on_env env id in
  match res with
    Some _ -> failwith "same ids are defined"
  | None -> ()


and to_type_detail_from_function_param f_env ctx param =
  let (_, init_value) = param in
  match init_value with
  | (Some type_expr, opt_defalut_val) ->
     resolve_type type_expr f_env ctx

  | (None, Some defalut_val) ->
     begin
       (* type is inferenced from defalut_val *)
       failwith "not implemented"
     end

  | _ -> failwith "type or default value is required"


and solve_identifier ?(do_rec_search=true) id_node env ctx =
  match id_node with
  | Ast.Id (name) -> solve_simple_identifier ~do_rec_search:do_rec_search name env ctx
  | _ -> failwith "unsupported ID type"

and solve_simple_identifier ?(do_rec_search=true) name env ctx =
  let name_s = Nodes.string_of_id_string name in
  Printf.printf "-> finding identitifer = %s : rec = %b\n" name_s do_rec_search;
  let oenv = if do_rec_search then
               Env.lookup env name_s
             else
               Env.find_on_env env name_s
  in
  Env.print env;
  (* Ex, "int" -> { type: type, value: int } *)
  let single_type_id_node name cenv =
    try_to_complete_env cenv ctx;

    ctx.si_type_type
  in

  let solve env_r =
    match env_r with
    | Env.MultiSet (record) ->
       begin
         match record.Env.ms_kind with
         | Env.Kind.Class ->
            begin
              (* classes will not be overloaded. However, template classes have
               * some instances (specialized). Thus, type may be unclear...
               *)
              failwith "not implemented : class / multi-set"
            end
         | Env.Kind.Function ->
            begin
              (* functions will be overloaded *)
              failwith "not implemented : function / multi-set"
            end
         | _ -> failwith "unexpected env : multi-set kind"
       end

    (* only primitive classes may be matched *)
    | Env.Class (_) -> single_type_id_node name env

    (*| Env.Variable *)
    | _ -> failwith "unexpected env"
  in

  oenv |> Option.map (fun e -> solve e.Env.er)


and try_to_complete_env env ctx =
  if Env.is_incomplete env then
    match env.Env.rel_node with
    | Some (node) ->
       begin
         let parent_env = Option.get env.Env.parent_env in
         ignore (construct_env node parent_env ctx);
         ()
       end
    | None -> failwith ""
  else
    ()

and resolve_type expr env ctx =
  let ty = eval_expr_as_ctfe expr env ctx in
  ty

and eval_expr_as_ctfe expr env ctx =
  Printf.printf "-> eval_expr_as_ctfe : begin ; \n";
  let (_, type_of_expr) = analyze_expr expr env ctx in
  if not (Type.is_unique_ty type_of_expr) then
    failwith "[ICE] : non unique type";
  Printf.printf "<- eval_expr_as_ctfe : end\n";
  (* WIP WIP WIP WIP WIP WIP *)
  ctx.si_int_type


and evaluate_invocation_arg expr env ctx =
  (* TODO: check CTFE-able node *)
  analyze_expr expr env ctx

and find_suitable_operator ?(universal_search=false) op_name_id_s arg_types expr env ctx =
  let op_name = Ast.Id op_name_id_s in
  let callee_function_ty =
    select_member_element ~universal_search:universal_search
                          (List.hd arg_types) op_name env ctx
  in

  callee_function_ty

(* this function solves types of the following
* "some_class.some_method"
* When universal_search option is true, a following code will be also solved (for UFCS).
* "some_method"
*)
and select_member_element ?(universal_search=false) recv_ty_r t_id env ctx =
  let r_cenv = recv_ty_r.Type.ty_cenv in
  let opt_t_id_info = solve_identifier ~do_rec_search:false t_id r_cenv ctx in

  match opt_t_id_info with
  | Some (t_id_info) ->
     begin
       (* member env named id is found in recv_ty_r! *)
       failwith "select_member_element: not implemented / select"
     end
  | None ->
     begin
       (* not found *)
       (* first, find the member function like "opDispatch" in recv_ty_r *)
       (* TODO: implement *)

       (* second, do universal_search *)
       if universal_search then begin
         (* TODO: exclude class envs *)
         let opt_t_id_info = solve_identifier t_id env ctx in
         let solve t_id_info =
           t_id_info
         in
         Option.map solve opt_t_id_info
       end else
         None
     end


and analyze node env ctx =
  let snode = solve_forward_refs node env in
  construct_env snode env ctx
