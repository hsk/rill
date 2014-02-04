//
// Copyright yutopp 2013 - .
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#pragma once


#include <cassert>
#include <memory>
//#include <unordered_map>
//#include <bitset>
//#include <vector>
//#include <utility>
//#include <boost/range/adaptor/transformed.hpp>

//#include <boost/algorithm/string/join.hpp>

//#include <boost/detail/bitmask.hpp>
//#include <boost/optional.hpp>

#include "../config/macros.hpp"

#include "environment_fwd.hpp"


namespace rill
{
    //
    // variable
    //
    class variable_symbol_environment RILL_CXX11_FINAL
        : public single_identifier_environment_base
    {
    public:
        static kind::type_value const KindValue = kind::type_value::e_variable;

    public:
        variable_symbol_environment( environment_parameter_t&& pp )
            : single_identifier_environment_base( std::move( pp ) )
            , parent_class_env_id_( environment_id_undefined )
            , value_type_id_( type_id_undefined )
        {}

    public:
        auto get_symbol_kind() const
            -> kind::type_value RILL_CXX11_OVERRIDE
        {
            return KindValue;
        }

        auto complete(
            type_id_t const& type_id,
            native_string_type const& name
            )
            -> void
        {
            value_type_id_ = type_id;
            name_ = name;

            change_progress_to_completed();
        }


        auto get_type_id() const
            -> type_id_t
        {
            return value_type_id_;
        }

        auto dump( std::ostream& os, std::string const& indent ) const
            -> std::ostream& RILL_CXX11_OVERRIDE
        {
            os << indent << "varialbe_environment" << std::endl;
    //        os << indent << "  = return type  " << value_type_env_id_ << std::endl;
            return dump_include_env( os, indent );
        }

        auto mangled_name() const -> native_string_type
        {
            // TODO: call parent mangled_name()
            return name_;
        }

        void set_parent_class_env_id( environment_id_t const& parent_class_env_id )
        {
            parent_class_env_id_ = parent_class_env_id;
        }

        auto get_parent_class_env_id() const
            -> environment_id_t const&
        {
            return parent_class_env_id_;
        }

        bool is_in_class() const
        {
            return parent_class_env_id_ != environment_id_undefined;
        }

    private:
        environment_id_t parent_class_env_id_;

        type_id_t value_type_id_;

        native_string_type name_;
    };

} // namespace rill
