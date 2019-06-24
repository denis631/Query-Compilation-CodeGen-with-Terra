# Query Compilation with Terra

This is in-memory database project developed as a POC for my bachelor thesis.

The purpose of the project is to utilize [Terra](http://terralang.org) multistaging ability in order to compile a given SQL query algebra plan (SQL AST) into native code for compilation speed, readability and performance.

The query compilation model is data-centric, as described in [Efficiently Compiling Efficient Query Plans for Modern Hardware](http://www.vldb.org/pvldb/vol4/p539-neumann.pdf)

## How to?

Run `configure.sh` in order download terra binary and TPCC-5w data

Run `run.sh` in order to run the database process

## Predefined Queries

### SELECT (1)
```
select c_id, c_first, c_middle, c_last
from customer
where c_last = 'BARBARBAR';
```

### SELECT + JOIN (2)
```
select c_last, o_id, ol_dist_info 
from customer, order, orderline 
where 
c_id = o_c_id and 
o_id = ol_o_id and 
ol_d_id = o_d_id and 
o_w_id = ol_w_id and 
ol_number = 1 and 
ol_o_id = 100;
```

### SELECT + 3 JOINS (3)
```
select c_last, o_id, i_id, ol_dist_info
from customer, order, orderline, item
where c_id = o_c_id
and c_d_id = o_d_id
and c_w_id = o_w_id
and o_id = ol_o_id
and o_d_id = ol_d_id
and o_w_id = ol_w_id
and ol_number = 1
and ol_o_id = 100
and ol_i_id = i_id;
```

### SORT (4)
```
select c_last, o_id
from customer, order
where c_id = o_c_id
and c_d_id = o_d_id
and c_w_id = o_w_id
and c_id = 100
sort by c_id, o_id
```
