require 'types.integer'
require 'types.varchar'
require 'types.char'
require 'types.timestamp'
require 'types.numeric'

struct Customer {
    c_id : Integer
    c_d_id : Integer
    c_w_id : Integer
    c_first : Varchar(16)
    c_middle : Char(2)
    c_last : Varchar(16)
    c_street_1 : Varchar(20)
    c_street_2 : Varchar(20)
    c_city : Varchar(20)
    c_state : Char(2)
    c_zip : Char(9)
    c_phone : Char(16)
    c_since : Timestamp
    c_credit : Char(2)
    c_credit_lim : Numeric(12, 2)
    c_discount : Numeric(4, 4)
    c_balance : Numeric(12, 2)
    c_ytd_paymenr : Numeric(12, 2)
    c_payment_cnt : Numeric(4, 0)
    c_delivery_cnt : Numeric(4, 0)
    c_data : Varchar(500)
}

struct Order {
    o_id : Integer
    o_d_id : Integer
    o_w_id : Integer
    o_c_id : Integer
    o_entry_d : Timestamp
    o_carrier_id : Integer
    o_ol_cnt : Numeric(2, 0)
    o_all_local : Numeric(1, 0)
}

struct Orderline {
    ol_o_id : Integer
    ol_d_id : Integer
    ol_w_id : Integer
    ol_number : Integer
    ol_i_id : Integer
    ol_supply_w_id : Integer
    ol_delivery_d : Timestamp
    ol_quantity : Numeric(2, 0)
    ol_amount : Numeric(6, 2)
    ol_dist_info : Char(24)
}

struct Item {
    i_id : Integer
    i_im_id : Integer
    i_name : Varchar(24)
    i_price : Numeric(5, 2)
    i_data : Varchar(50)
}
