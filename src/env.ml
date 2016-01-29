open Batteries

type checked_state =
    InComplete
  | Checking
  | Complete

module Kind =
  struct
    type t =
        Module
      | Class
      | Function
      | Variable
      | MultiSet of t
  end

type builtin_t =
    TypeTy
  | Int32Ty


type id_t = Num.num
let id_counter = ref @@ Num.num_of_int 0


type 'ast env_t = {
   env_id           : id_t;
   parent_env       : 'ast env_t option;
   er               : 'ast env_record_t;
   mutable state    : checked_state;

   mutable rel_node : 'ast option;
}

 and 'ast env_record_t =
  | Root of 'ast lookup_table_t
  | MultiSet of 'ast multiset_record

  | Module of 'ast lookup_table_t * module_record
  | Function of 'ast lookup_table_t
  | Class of 'ast lookup_table_t * class_record

  | Variable of variable_record

 and 'ast name_env_mapping = (string, 'ast env_t) Hashtbl.t

 and 'ast lookup_table_t = {
   scope            : 'ast name_env_mapping;
 }

 and 'ast multiset_record = {
   ms_kind                  : Kind.t;
   mutable ms_candidates    : 'ast env_t list;
 }


 and module_record = {
   mod_name     : string;
 }

 and variable_record = {
   var_name     : string;
 }

 and class_record = {
   cls_name     : string;
 }

let get_lookup_record e =
  let { er = er; _ } = e in
  match er with
  | Root (r) -> r
  | Module (r, _) -> r
  | Function (r) -> r
  | Class (r, _) -> r
  | _ -> failwith "has no lookup table"

let get_symbol_table e =
  let lt = get_lookup_record e in
  lt.scope


let is_root e =
  let { er = er; _ } = e in
  match er with
    Root _  -> true
  | _       -> false

let parent_env e =
  if is_root e then
    failwith "root env has no parent env"
  else
    let { parent_env = opt_penv } = e in
    match opt_penv with
      Some penv -> penv
    | None -> failwith ""

(* *)
let find_on_env e name =
  let t = get_symbol_table e in
  try
    Some (Hashtbl.find t name)
  with
    Not_found -> None

(*  *)
let rec lookup e name =
  let target = find_on_env e name in
  match target with
    Some _ as te -> te
  | None -> if is_root e then
              None
            else
              let penv = parent_env e in
              lookup penv name

(*  *)
let add_inner_env (target_env : 'a env_t) (name : string) (e : 'a env_t) =
  let t = get_symbol_table target_env in
  Hashtbl.add t name e


let empty_lookup_table ?(init=8) () =
  {
    scope = Hashtbl.create init;
  }

let create_env parent_env er =
  let cur_id = !id_counter in
  Num.incr_num id_counter;
  {
    env_id = cur_id;
    parent_env = Some parent_env;
    er = er;
    state = InComplete;
    rel_node = None;
  }

(**)
let is_checked e =
  let { state = s; _ } = e in
  s = Checking || s = Complete

let is_incomplete e =
  not (is_checked e)


let update_status e ns =
  e.state <- ns


(**)
let update_rel_ast e node =
  e.rel_node <- Some node

let get_rel_ast e =
  Option.get e.rel_node


(**)
let make_root_env () =
  let tbl = empty_lookup_table () in
  let cur_id = !id_counter in
  Num.incr_num id_counter;
  {
    env_id = cur_id;
    parent_env = None;
    er = Root (tbl);
    state = Complete;
    rel_node = None;
  }

let find_or_add_multi_env env name k =
  let oe = find_on_env env name in
  match oe with
  (* *)
  | Some ({ er = (MultiSet { ms_kind = k; _ }); _} as e) ->
     e

  (* *)
  | None ->
     let e = create_env env (MultiSet {
                                 ms_kind = k;
                                 ms_candidates = [];
                               }) in
     add_inner_env env name e;
     e

  | _ -> failwith "multienv is not found"


module MultiSetOp =
  struct
    let add_candidates menv env =
      let { er = mer; _ } = menv in
      match mer with
      | MultiSet (record) ->
         begin
           (* add env to lists as candidates *)
           record.ms_candidates <- env :: record.ms_candidates;
           ()
         end
      | _ -> failwith "can not add candidate"
  end


module ClassOp =
  struct
  end


let print env =
  let print_table tbl indent =
    let open Printf in
    let p name =
      printf "%s+ %s\n" indent name
    in
    tbl |> Hashtbl.iter @@ fun name _ -> p name
  in
  let print_ er f indent =
    let open Printf in
    let nindent = (indent ^ "  ") in
    match er with
    | Root (lt) ->
       begin
         printf "%sRootEnv\n" indent;
         print_table lt.scope indent;
         f nindent;
       end
    | Module (lt, r) ->
       begin
         printf "%sModuleEnv - %s\n" indent r.mod_name;
         print_table lt.scope indent;
         f nindent;
       end
    | Function (lt) ->
       begin
         printf "%sFunction\n" indent;
         print_table lt.scope indent;
         f nindent;
       end
    | Class (lt, r) ->
       begin
         printf "%sClassEnv - %s\n" indent r.cls_name;
         print_table lt.scope indent;
         f nindent;
       end
    | _ -> failwith "print: unsupported env"
  in
  let rec dig env f =
    if is_root env then begin
      let { er = er; _ } = env in
      print_ er f ""
    end else begin
      let pr = parent_env env in
      let { er = er; _ } = env in
      let newf indent = print_ er f indent in
      dig pr newf
    end
  in
  dig env (fun _ -> ())
