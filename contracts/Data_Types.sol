// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


library  Data_Types {
    
    struct User_Address{
        uint256 addr_id;
        string addr;
        string contact_number;
    }

    struct User{
        string name;
        address user_address;
    }

    struct Credit_owner {
        uint256 Credit_owner_id;
        string Credit_owner_name;
        uint256 carbon_Credit;
        uint256 price;
        uint256 max_limit_per_sell;
        address owner_id;
    }

    struct Transaction {
        string transaction_type; //[Buy,Refund]
        uint256 transaction_id;
        uint256 amount;
        string status; // ["Paid","Outstanding"]
        uint256 platform_fee;
        uint256 order_id;
        uint256 convinience_fee;
        uint256 token_charges; // Need to figure out how to put them in the DB.
    }

    struct Order {
        uint256 order_id;
        string order_status; // [Delivered, Cancelled, In Transit, Token Issued]
        uint256 Credit_owner_id;
        uint256 quantity;
        address buyer_id;
        // Transaction[] payment_detail;
    }

    struct Certificate {
        uint256 certificateId;
        uint256 Credit_owner_id;
        address recipient;
        uint256 quantity;
        uint256 timestamp;
    }
}