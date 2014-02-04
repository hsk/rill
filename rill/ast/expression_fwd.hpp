//
// Copyright yutopp 2013 - .
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#pragma once

#include <vector>

#include "detail/specifier.hpp"

#include "ast_base.hpp"


namespace rill
{
    namespace ast
    {
        // ----------------------------------------------------------------------
        // ----------------------------------------------------------------------
        //
        // expressions
        //
        // ----------------------------------------------------------------------
        // ----------------------------------------------------------------------
        RILL_AST_FWD_DECL( expression, expression )
        

        RILL_AST_FWD_DECL( binary_operator_expression, expression )

        RILL_AST_FWD_DECL( element_selector_expression, expression )
        RILL_AST_FWD_DECL( subscrpting_expression, expression )
        RILL_AST_FWD_DECL( call_expression, expression )
        RILL_AST_FWD_DECL( intrinsic_function_call_expression, expression )


        RILL_AST_FWD_DECL( term_expression, expression )


        RILL_AST_FWD_DECL( type_expression, expression )
        RILL_AST_FWD_DECL( type_identifier_expression, expression )
        RILL_AST_FWD_DECL( compiletime_return_type_expression, expression )

        // etc...
        typedef std::vector<expression_ptr> expression_list;

    } // namespace ast
} // namespace rill
