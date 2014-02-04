//
// Copyright yutopp 2013 - .
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#pragma once

#include <vector>
#include <string>
#include <functional>

#include "../environment/environment_fwd.hpp"
#include "../behavior/intrinsic_function_holder_fwd.hpp"

#include "detail/tree_visitor_base.hpp"
#include "detail/dispatch_assets.hpp"

#include "expression_fwd.hpp"

#include "value.hpp"


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
        struct expression
            : public ast_base
        {
        public:
            RILL_AST_ADAPT_VISITOR_VIRTUAL( expression )

        public:
            virtual ~expression() {}
        };



        struct binary_operator_expression
            : public expression
        {
        public:
            RILL_AST_ADAPT_VISITOR( binary_operator_expression )

        public:
            binary_operator_expression(
                expression_ptr const& lhs,
                identifier_value_ptr const& op,
                expression_ptr const& rhs
                )
                : lhs_( lhs )
                , op_( op )
                , rhs_( rhs )
            {}

        public:
            expression_ptr const lhs_;
            identifier_value_ptr const op_;
            expression_ptr const rhs_;
        };


        struct subscrpting_expression
            : public expression
        {
        public:
            RILL_AST_ADAPT_VISITOR( subscrpting_expression )

        public:
            subscrpting_expression(
                expression_ptr const& lhs,
                boost::optional<expression_ptr> const& rhs
                )
                : lhs_( lhs )
                , rhs_( rhs )
            {}

        public:
            expression_ptr const lhs_;
            boost::optional<expression_ptr> const rhs_;
        };


        //
        struct element_selector_expression
            : public expression
        {
        public:
            RILL_AST_ADAPT_VISITOR( element_selector_expression )

        public:
            element_selector_expression(
                expression_ptr const& reciever,
                identifier_value_base_ptr const& selector_id
                )
                : reciever_( reciever )
                , selector_id_( selector_id )
            {}

        public:
            expression_ptr const reciever_;
            identifier_value_base_ptr const selector_id_;
        };




        struct call_expression
            : public expression
        {
        public:
            RILL_AST_ADAPT_VISITOR( call_expression )

        public:
            call_expression(
                expression_ptr const& reciever,
                expression_list const& arguments
                )
                : reciever_( reciever )
                , arguments_( arguments )
            {}

        public:
            expression_ptr const reciever_;
            expression_list const arguments_;
        };







        //
        struct intrinsic_function_call_expression
            : public expression
        {
        public:
            RILL_AST_ADAPT_VISITOR( intrinsic_function_call_expression )

        public:
            intrinsic_function_call_expression( intrinsic_function_action_id_t const& action_id )
                : action_id_( action_id )
            {}

        public:
            intrinsic_function_action_id_t const action_id_;
        };



        struct term_expression
            : public expression
        {
        public:
            RILL_AST_ADAPT_VISITOR( term_expression )

        public:
            term_expression( value_ptr const& v )
                : value_( v )
            {}

        public:
            value_ptr const value_;
        };





        struct type_expression
            : public expression
        {
            RILL_AST_ADAPT_VISITOR( type_expression );
            //ast_base_type a;
            //ADAPT_EXPRESSION_VISITOR( type_expression )

        public:
            ~type_expression() {}
        };


        //
        struct type_identifier_expression
            : public type_expression
        {
        public:
            RILL_AST_ADAPT_VISITOR( type_identifier_expression )

        public:
            type_identifier_expression(
                nested_identifier_value_ptr const& v,
                attribute::type_attributes_optional const& attributes
                )
                : value_( v )
                , attributes_( attributes )
            {}

        public:
            nested_identifier_value_ptr const value_;
            attribute::type_attributes_optional const attributes_;
        };



        //
        struct compiletime_return_type_expression
            : public type_expression
        {
        public:
            RILL_AST_ADAPT_VISITOR( compiletime_return_type_expression )

        public:
            compiletime_return_type_expression( expression_ptr const& e )
                : expression_( e )
            {}

        public:
            expression_ptr expression_;
        };

    } // namespace ast
} // namespace rill
