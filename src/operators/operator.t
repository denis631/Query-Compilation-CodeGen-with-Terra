local asdl = require 'asdl'
AlgebraTree = asdl.NewContext()

AlgebraTree:Define [[

    Operator = Projection(Operator child, table requiredAttrs)
             | TableScan(string tableName)
             | Selection(Operator child, table predicates)
             | InnerJoin(Operator leftOperator, Operator rightOperator, table predicates)
             | Sort(Operator child, table sortedAttrs, SortOrder order)

    SortOrder = Ascending | Descending
]]
