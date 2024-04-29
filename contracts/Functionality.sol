// SPDX-License-Identifier: MIT
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
pragma solidity ^0.8.9;
import "./Database.sol";
import "./guard.sol";

contract Functionality is Database{
    bool internal locked;
    modifier reentrancyGuard() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
    // Modifiers

    modifier validateUser(address addr) {
        require(
            bytes(user_list[addr].name).length > 0,
            "User doesn't exist. Please register."
        );
        _;
    }

    function registerUser(
        string memory name,
        string memory addr,
        string memory contact_number
    ) public returns (bool) {
        // Validation
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(addr).length > 0, "Address cannot be empty");
        require(
            bytes(contact_number).length > 0,
            "Contact number cannot be empty"
        );
        Data_Types.User memory user = user_list[msg.sender];
        require(bytes(user.name).length == 0, "User already registered.");

        // Adding User
        user.name = name;
        user.user_address = msg.sender;
        addUser(user);
        Data_Types.User_Address memory newUserAddress = Data_Types
            .User_Address({
                addr_id: user_addresses[msg.sender].length,
                addr: addr,
                contact_number: contact_number
            });
        user_addresses[msg.sender].push(newUserAddress);
        return true;
    }

    function loginUser() public view validateUser(msg.sender) returns (bool) {
        return true;
    }

    function getCredit_owners(
        uint256 lotSize,
        uint256 pageNumber
    )
        public
        view
        validateUser(msg.sender)
        returns (Data_Types.Credit_owner[] memory)
    {
        uint256 startIndex = lotSize * (pageNumber - 1);
        require(startIndex < Credit_owner_list.length, "Invalid Page Number");
        return listCredit_owners(lotSize, pageNumber);
    }

    function addContactDetails(
        string memory addr,
        string memory contact_number
    ) public validateUser(msg.sender) {
        require(bytes(addr).length > 0, "Address cannot be empty");
        require(
            bytes(contact_number).length > 0,
            "Contact Number cannot be empty"
        );
        Data_Types.User_Address memory curr_Addr = Data_Types.User_Address({
            addr_id: user_addresses[msg.sender].length + 1,
            addr: addr,
            contact_number: contact_number
        });
        addAddress(curr_Addr, msg.sender);
    }

    function modifyContactDetails(
        string memory addr,
        string memory contact_number,
        uint256 id
    ) public validateUser(msg.sender) {
        require(bytes(addr).length > 0, "Address cannot be empty");
        require(
            bytes(contact_number).length > 0,
            "Contact Number cannot be empty"
        );
        require(user_addresses[msg.sender].length > id && id > 0, "Invalid ID");
        Data_Types.User_Address memory curr_Addr = Data_Types.User_Address({
            addr_id: id,
            addr: addr,
            contact_number: contact_number
        });
        editAddress(curr_Addr, msg.sender, id);
    }

    function listCredit_owner(
        uint256 Credit_owner_id,
        string memory Credit_owner_name,
        uint256 price,
        uint256 carbon_Credit,
        uint256 max_limit_per_sell
    ) public validateUser(msg.sender) {
        require(Credit_owner_id > 0, "Invalid Credit_owner ID");
        require(bytes(Credit_owner_name).length > 0, "Invalid Credit_owner Name");
        require(price > 0, "Invalid Price");
        require(carbon_Credit > 0, "Invalid carbon_Credit");
        require(
            max_limit_per_sell > 0 && max_limit_per_sell < 1500,
            "Invalid Limit"
        );
        // require()
        require(Credit_owner_mapping[Credit_owner_id] == 0, "Credit_owner Already Exists.");

        Data_Types.Credit_owner memory Credit_owner = Data_Types.Credit_owner({
            Credit_owner_id: Credit_owner_id,
            Credit_owner_name: Credit_owner_name,
            price: price,
            carbon_Credit: carbon_Credit,
            max_limit_per_sell: max_limit_per_sell,
            owner_id: msg.sender
        });
        addCredit_owner(Credit_owner);
    }

    function modifyListedCredit_owner(
        uint256 Credit_owner_id,
        string memory Credit_owner_name,
        uint256 price,
        uint256 carbon_Credit,
        uint256 max_limit_per_sell
    ) public validateUser(msg.sender) {
        require(Credit_owner_id > 0, "Invalid Credit_owner ID");
        require(bytes(Credit_owner_name).length > 0, "Invalid Credit_owner Name");
        require(price > 0, "Invalid Price");
        require(carbon_Credit > 0, "Invalid carbon_Credit");
        require(
            max_limit_per_sell > 0 && max_limit_per_sell < 5,
            "Invalid Limit"
        );
        require(Credit_owner_mapping[Credit_owner_id] != 0, "Credit_owner doesn't exist.");
        Data_Types.Credit_owner memory Credit_owner = Data_Types.Credit_owner({
            Credit_owner_id: Credit_owner_id,
            Credit_owner_name: Credit_owner_name,
            price: price,
            carbon_Credit: carbon_Credit,
            max_limit_per_sell: max_limit_per_sell,
            owner_id: msg.sender
        });
        editCredit_owner(Credit_owner, Credit_owner_id);
    }

    function deleteCredit_ownerFromListing(
        uint256 Credit_owner_id
    ) public validateUser(msg.sender) {
        deleteCredit_owner(Credit_owner_id);
    }


    function sell_carbon_Credit(
        uint256 Credit_owner_id,
        address buyer,
        uint256 quantity
    ) external payable validateUser(msg.sender) {
        require(Credit_owner_mapping[Credit_owner_id] != 0, "Credit_owner doesn't exist");
        require(
            quantity <= Credit_owner_list[Credit_owner_mapping[Credit_owner_id] - 1].carbon_Credit,
            "Insufficient carbon credits."
        );
        require(
            msg.value ==
                    (quantity *
                        Credit_owner_list[Credit_owner_mapping[Credit_owner_id] - 1].price),
            "Invalid amount"
        );
        /*require(
            buyer != msg.sender,
            "Seller and buyer cannot be the same."
        );*/

        // to add order
        Data_Types.Order memory order = Data_Types.Order({
            Credit_owner_id: Credit_owner_id,
            quantity: quantity,
            order_status: IN_TRANSIT,
            order_id: order_list[msg.sender].length + 1,
            buyer_id: buyer
        });

        placeOrder(order, msg.sender);
        // Transfer Money to Escrow
        escrow_amount += msg.value;
        Data_Types.Transaction memory transaction = Data_Types.Transaction({
            transaction_type: BUY,
            transaction_id: order_transaction_list[msg.sender].length + 1,
            amount: (quantity *
                    Credit_owner_list[Credit_owner_mapping[Credit_owner_id] - 1].price),
            status: DONE,
            platform_fee: 0,
            convinience_fee: 0,
            token_charges: 0,
            order_id: order_list[msg.sender].length
        });
        // Issue certificate to seller
        issueCertificate(Credit_owner_id, msg.sender, quantity);

        addTransaction(transaction, msg.sender);
    }




    function buy_carbon_Credit(
        uint256 Credit_owner_id,
        uint256 quantity
    ) external payable validateUser(msg.sender) {
        require(Credit_owner_mapping[Credit_owner_id] != 0, "Credit_owner doesn't exist");
        require(
            quantity <=
                Credit_owner_list[Credit_owner_mapping[Credit_owner_id] - 1]
                    .max_limit_per_sell,
            "Cannot buy the mentioned quantity."
        );
        require(
            quantity <= Credit_owner_list[Credit_owner_mapping[Credit_owner_id] - 1].carbon_Credit,
            "Cannot buy the mentioned quantity."
        );
        require(
            msg.sender !=
                Credit_owner_list[Credit_owner_mapping[Credit_owner_id] - 1].owner_id,
            "Seller can't buy the Carbon_Credit."
        );
        require(
            msg.value ==
                    (quantity *
                        Credit_owner_list[Credit_owner_mapping[Credit_owner_id] - 1].price),
            "Invalid amount"
        );
        Data_Types.Order memory order = Data_Types.Order({
            Credit_owner_id: Credit_owner_id,
            quantity: quantity,
            order_status: IN_TRANSIT,
            order_id: order_list[msg.sender].length + 1,
            buyer_id: msg.sender
        });
        // Order added
        placeOrder(order, msg.sender);
        // Transfer Money to Escrow
        escrow_amount += msg.value;
        Data_Types.Transaction memory transaction = Data_Types.Transaction({
            transaction_type: BUY,
            transaction_id: order_transaction_list[msg.sender].length + 1,
            amount: (quantity *
                    Credit_owner_list[Credit_owner_mapping[Credit_owner_id] - 1].price),
            status: DONE,
            platform_fee: 0,
            convinience_fee: 0,
            token_charges: 0,
            order_id: order_list[msg.sender].length
        });
        // Issue certificate to seller
        issueCertificate(Credit_owner_id, msg.sender, quantity);

        addTransaction(transaction, msg.sender);
    }

    /*function delivercarbon_Credit(
        address buyer_id,
        uint256 order_id
    // ) external validateUser(msg.sender) nonReentrant {
    ) external validateUser(msg.sender)  {
        // // Mark as Delivered
        require(order_list[buyer_id].length > 0, "Invalid Order ID");
        uint256 index = 0;
        uint256 flag = 0;
        for (uint256 i = 0; i < order_list[buyer_id].length; i++) {
            if (order_list[buyer_id][i].order_id == order_id) {
                index = i;
                flag = 1;
            }
        }
        require(flag == 1, "No such order found");
        Data_Types.Order memory order = order_list[buyer_id][index];
        Data_Types.Credit_owner memory Credit_owner = Credit_owner_list[
            uint256(Credit_owner_mapping[order.Credit_owner_id]) - 1
        ];
        require(
            msg.sender == Credit_owner.owner_id,
            "You are not authorized to mark this as delivered."
        );
        require(
            keccak256(abi.encodePacked(order.order_status)) ==
                keccak256(abi.encodePacked(IN_TRANSIT)),
            "This action is not permitted"
        );
        uint256 transactionIndex = 0;
        uint256 found = 0;
        for (uint256 i = 0; i < order_transaction_list[buyer_id].length; i++) {
            if (
                order_transaction_list[buyer_id][i].order_id == order_id &&
                keccak256(
                    abi.encodePacked(
                        order_transaction_list[buyer_id][i].transaction_type
                    )
                ) ==
                keccak256(abi.encodePacked(BUY)) &&
                keccak256(
                    abi.encodePacked(order_transaction_list[buyer_id][i].status)
                ) ==
                keccak256(abi.encodePacked(DONE))
            ) {
                transactionIndex = i;
                found = 1;
            }
        }
        require(found != 0, "No valid transaction found.");
        uint256 amountToTransfer = (order.quantity * Credit_owner.price);
        address payable seller = payable(msg.sender);
        escrow_amount -= amountToTransfer;
        seller.transfer(amountToTransfer);
        markAsDelivered(buyer_id, index);
        markTransactionAsPaid(buyer_id, transactionIndex);
    }*/

    function burn_carbon_Credit(uint256 quantity) external validateUser(msg.sender) {
        require(balances[msg.sender] >= quantity, "Insufficient balance");

        // Burn tokens
        balances[msg.sender] -= quantity;
        uint256 Credit_owner_id = uint256(keccak256(abi.encodePacked(msg.sender)));
    
        // Issue certificate for burning tokens
        issueCertificate(Credit_owner_id, msg.sender, quantity); // Assuming the recipient of the certificate is the same as the burner

        emit Transfer(msg.sender, address(0), quantity);
    }
}
