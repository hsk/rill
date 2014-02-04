//
// Copyright yutopp 2013 - .
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef RILL_ENVIRONMENT_TEMPLATE_ENVIRONMENT_HPP
#define RILL_ENVIRONMENT_TEMPLATE_ENVIRONMENT_HPP

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
    // template
    //
    class template_environment RILL_CXX11_FINAL
        : public single_identifier_environment_base
    {
    public:
        template_environment( environment_parameter_t&& pp, environment_id_t const& template_set_env_id )
            : single_identifier_environment_base( std::move( pp ) )
        {}

    public:
        auto get_symbol_kind() const
            -> kind::type_value RILL_CXX11_OVERRIDE
        {
            assert( has_parent() );
            return get_parent_env()->get_symbol_kind();
        }

    private:
    };

} // namespace rill

#endif /*RILL_ENVIRONMENT_TEMPLATE_ENVIRONMENT_HPP*/
