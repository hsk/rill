(*
 * Copyright yutopp 2015 - .
 *
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *)

type type_id_ref_t = int64   (* type id is represented by int64 *)

module IdType = Int64
let is_type_id_signed = true

type 'env t = {
  ti_id                 : type_id_ref_t option;
  ti_sort               : 'env type_sort_t;
  ti_template_args      : 'env ctfe_val_t list;
  ti_attr               : Type_attr.attr_t;
}

 and 'env ctfe_val_t = ('env t) Ctfe_value.t

 and 'env type_sort_t =
    UniqueTy of 'env
  | ClassSetTy of 'env
  | FunctionSetTy of 'env
  | Undef
  | NotDetermined of Unification.id_t


let undef_ty =
  {
    ti_id = None;
    ti_sort = Undef;
    ti_template_args = [];
    ti_attr = Type_attr.undef;
  }
