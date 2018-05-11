local asdl = require 'asdl'
AlgebraTree = asdl.NewContext()

AlgebraTree:Define [[

    Root = Projection(Operator child, table requiredAttrs)

    Operator = TableScan(string tableName)
             | Selection(Operator child, table predicates)
             | InnerJoin(Operator leftOperator, Operator rightOperator, table predicates)
             # TODO: add Sort Operator -> param: ascending/descending
]]
