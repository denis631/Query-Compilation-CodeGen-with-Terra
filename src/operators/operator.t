local asdl = require 'asdl'
AlgebraTree = asdl.NewContext()

AlgebraTree:Define [[

    Operator = Projection(Operator producer, table requiredAttrs)
             | TableScan(string tableName)
             | Selection(Operator producer, table predicates)
             | HashJoin(Operator leftOperator, Operator rightOperator, table predicates)
             | Sort(Operator producer, table sortedAttrs, SortOrder order)

    SortOrder = Ascending | Descending
]]
