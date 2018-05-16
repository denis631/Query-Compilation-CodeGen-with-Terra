local asdl = require 'asdl'
AlgebraTree = asdl.NewContext()

AlgebraTree:Define [[

    Root = Projection(Operator child, table requiredAttrs)

    Operator = TableScan(string tableName)
             | Selection(Operator child, table predicates)
             | InnerJoin(Operator leftOperator, Operator rightOperator, table predicates)
             | Sort(Operator child, table sortedAttrs, SortOrder order)

    SortOrder = Ascending | Descending
]]
