// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Data_Types.sol";

contract Database {
    string public CANCELLED = "Cancelled";
    string public IN_TRANSIT = "In Transit";
    string public TOKEN_ISSUED = "Token Issued";

    string public BUY = "Buy";
    string public REFUND = "Refund";

    string public PAID = "Paid";
    string public DONE = "Done";

    uint256 public escrow_amount = 0;
    address public owner;

    // Constructor
    constructor(){
        owner = msg.sender;
    }

    // Private data
    mapping(address => Data_Types.User) public user_list;
    mapping(address => Data_Types.User_Address[]) public user_addresses;
    Data_Types.Credit_owner[] public Credit_owner_list;
    // Credit_owner_id -> index in Credit_owner_list
    mapping(uint256 => uint256) public Credit_owner_mapping;
    // Buyer Address => Order-list
    mapping(address => Data_Types.Order[]) public order_list;
    mapping(address => Data_Types.Transaction[]) public order_transaction_list;
    // Need to check if this is needed or not.

    // Mapping to store certificates
    mapping(uint256 => Data_Types.Certificate) public certificates;
    uint256 public nextCertificateId = 1;

    mapping(address => uint256) public balances;



    // events
    event UserRegistered(address userAddress, string username);
    event Credit_ownerRegistered(uint256 Credit_owner_id);
    event Credit_ownerEdited(uint256 Credit_owner_id);
    event Credit_ownerDeleted(uint256 Credit_owner_id);
    event OrderPlaced(address user_address,uint256 order_id);
    event OrderCancelled(address user_address,uint256 order_id);
    event OrderDelivered(address user_address,uint256 order_id);
    event addressAdded(address user_address);
    event addressEdited(address user_address);
    event CertificateIssued(uint256 certificateId, uint256 Credit_owner_id, address recipient, uint256 quantity);
    event Transfer(address indexed from, address indexed to, uint256 value);


    // Public functions accessible from the implementation contract
    function addUser(Data_Types.User memory newUser) public {
        user_list[newUser.user_address] = newUser;
        emit UserRegistered(newUser.user_address, newUser.name);
    }

    function addCredit_owner(Data_Types.Credit_owner memory newCredit_owner) public {
        Credit_owner_list.push(newCredit_owner);
        // This could lead to errors while scaling.
        Credit_owner_mapping[newCredit_owner.Credit_owner_id] = Credit_owner_list.length;
        emit Credit_ownerRegistered(newCredit_owner.Credit_owner_id);
    }

    function editCredit_owner(Data_Types.Credit_owner memory newCredit_owner, uint256 id) public {
        Credit_owner_list[  Credit_owner_mapping[id] - 1] = newCredit_owner;
        emit Credit_ownerEdited(newCredit_owner.Credit_owner_id);
    }

    function deleteCredit_owner(uint256 id) public {
        Credit_owner_mapping[id] = 0;
        emit Credit_ownerDeleted(id);
    }

    function placeOrder(Data_Types.Order memory newOrder,address id) public {
        order_list[id].push(newOrder) ;
        emit OrderPlaced(newOrder.buyer_id,newOrder.order_id);
    }

    function addTransaction(Data_Types.Transaction memory transaction,address id) public {
        order_transaction_list[id].push(transaction) ;
    }

    function cancelOrder(address buyer_id,uint256 index) public {
        order_list[buyer_id][index].order_status = CANCELLED;
        emit OrderCancelled(buyer_id,order_list[buyer_id][index].order_id);
    }

    function markAsDelivered(address buyer_id,uint256 index) public {
        order_list[buyer_id][index].order_status = CANCELLED;
        // Change status of Transaction to Paid.
        emit OrderDelivered(buyer_id,order_list[buyer_id][index].order_id);
    }

    function markTransactionAsPaid(address buyer_id, uint256 index) public{
        order_transaction_list[buyer_id][index].status = PAID;
    }

    function listCredit_owners(
        uint256 lotSize,
        uint256 pageNumber
    ) public view returns (Data_Types.Credit_owner[] memory) {
        uint256 startIndex = lotSize * (pageNumber - 1);
        uint256 endIndex = startIndex + (lotSize - 1);
        if (endIndex > Credit_owner_list.length) {
            endIndex = Credit_owner_list.length - 1;
        }
        Data_Types.Credit_owner[] memory currentCredit_owners = new Data_Types.Credit_owner[](
            endIndex - startIndex + 1
        );
        for (uint256 i = startIndex; i <= endIndex; i++) {
            currentCredit_owners[i - startIndex] = Credit_owner_list[i];
        }
        return currentCredit_owners;
    }

    function addAddress(
        Data_Types.User_Address memory newAddress,
        address user_address
    ) public {
        user_addresses[user_address].push(newAddress);
        emit addressAdded(user_address);
    }

    function editAddress(
        Data_Types.User_Address memory newAddress,
        address user_address,
        uint256 id
    ) public {
        for (uint256 i = 0; i < user_addresses[user_address].length; i++) {
            if (user_addresses[user_address][i].addr_id == id) {
                user_addresses[user_address][i] = newAddress;
            }
        }
        emit addressEdited(user_address);
    }

    // Function to issue certificate
    function issueCertificate(uint256 Credit_owner_id, address recipient, uint256 quantity) internal {
        certificates[nextCertificateId] = Data_Types.Certificate({
            certificateId: nextCertificateId,
            Credit_owner_id: Credit_owner_id,
            recipient: recipient,
            quantity: quantity,
            timestamp: block.timestamp
        });
        emit CertificateIssued(nextCertificateId, Credit_owner_id, recipient, quantity);
        nextCertificateId++;
    }
}
