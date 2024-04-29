// SPDX-License-Identifier: MIT

// In the hostel example we have a seller landlord and a buyer tenant. However, in the case of any commodity C,
// let us say that suppliers of commodity C fix their own selling prices for one unit of C, supplies i asking 
// for s(i) rupees per unit. Consumer i wishes to pay rupees b(i) rupees per unit. There can be n suppliers and 
// m consumers. In this marketplace for commodity C, we will require to function automatically using ethereum 
// blockchain using a smart contract written along the lines of the hostel smart contract. This will be tested by 
// this weekend on the same solidity environment Remix IDE. All you have to do is remove the advance deposit and 
// do the money exchanges based on units of C sold / purchased; there will be no monthly rent. There will be a 
// function to buy/sell when a supplier-consumer pair decides to do the transaction.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact soumikkvb&gmail.com
contract CommodityTokens is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory Name, string memory Sym) ERC20(Name, Sym) {
        _mint(msg.sender, 1000);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function transfer(address from, address to, uint256 amount) public returns (bool) {
        // address sender = _msgSender();
        _transfer(from, to, amount * 10 ** decimals());
        return true;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function burn(address from, uint256 amount) public virtual {
        require(balanceOf(from) > amount, "Not enough Tokens !!");
        _burn(from, amount);
    }

    function balanceChecker(address account) public view returns (uint256) {
        return balanceOf(account);
    }
}
// import "contracts/CommodityTokenExample.sol";

contract commodity{
    uint no_of_shop;
    uint no_of_customer;
    uint no_of_purchases;

    struct shop{
        address payable owner;
        uint sales;
        uint price;
        uint stock;
        string name;
        string symbol;
        CommodityTokens tokens;
        uint tokenBal;
    }
    mapping(uint => shop) public shop_No;

    struct customer{
        address payable id;
        // uint amount;
        string name;
        uint stock;
    }
    mapping(uint => customer) public customer_No;
    mapping(address => uint) public customerToKey;

    struct purchaseAgreement{
        address payable seller;
        address payable buyer;
        uint no_of_goods;
        uint total_price;
        uint tokenTransfer;
    }
    mapping(uint => purchaseAgreement) public agreementIndex;

    modifier onlyShopOwner(uint _index) {
        require(msg.sender == shop_No[_index].owner, "Only a shop owner of this market can access this");
        _;
    }

    modifier onlyCustomer(address payable _name) {
        require(msg.sender == customer_No[customerToKey[address(_name)]].id, "Only a customer of this market can access this");
        _;
    }

    modifier enoughBalCheck(uint _amt) {
        require(msg.value >= uint(_amt), "Not enough Ether in your wallet");
        _;
    }

    function initializeShop(uint _price, uint _stock, string memory _name, string memory _symbol) public {
        require(msg.sender != address(0));
        no_of_shop++;
        CommodityTokens commodityTokens = new CommodityTokens(_name, _symbol);
        commodityTokens.mint(msg.sender, _stock + 100);
        shop_No[no_of_shop] = shop(payable(msg.sender), 0, _price, _stock, _name, _symbol, commodityTokens, commodityTokens.balanceChecker(msg.sender));
    }

    function initializeCustomer(string memory _name) public {
        require(msg.sender != address(0));
        no_of_customer++;
        customer_No[no_of_customer] = customer(payable (msg.sender), _name, 0);
        customerToKey[msg.sender] = no_of_customer;
    }

    event BalanceCheck(uint indexed paid, uint indexed to_pay, bool result);
    event TransferCheck(address indexed _to, uint indexed _amt);

    function buy(uint _index, uint _amt) public payable onlyCustomer(payable(msg.sender)) enoughBalCheck(uint(uint(shop_No[_index].price)*uint(_amt))) {
        require(msg.sender != address(0));
        uint total_price = uint(uint(shop_No[_index].price)*uint(_amt)) * 1e18;
        // emit BalanceCheck(msg.value, total_price, true);
        require(msg.value == total_price, "Send exact money, Please");
        shop_No[_index].sales++;
        shop_No[_index].stock -= _amt;
        no_of_purchases++;
        customer_No[customerToKey[address(msg.sender)]].stock +=_amt;
        agreementIndex[no_of_purchases] = purchaseAgreement(payable(shop_No[_index].owner), payable(msg.sender), _amt, uint(uint(shop_No[_index].price)*uint(_amt)), msg.value);
        shop_No[_index].tokens.transfer(shop_No[_index].owner, msg.sender, _amt);
        shop_No[_index].tokenBal = shop_No[_index].tokens.balanceChecker(shop_No[_index].owner);
        payable(shop_No[_index].owner).transfer(msg.value);
        emit TransferCheck(msg.sender, shop_No[_index].tokens.balanceChecker(msg.sender));
    }

    function changePrice(uint _index, uint _newPrice) public onlyShopOwner(_index) {
        shop_No[_index].price = _newPrice;
    }

    function increaseStock(uint _index, uint _inc) public onlyShopOwner(_index) {
        require(shop_No[_index].stock + _inc <= shop_No[_index].tokens.balanceChecker(shop_No[_index].owner), "Please mint enough Tokens first !!");
        shop_No[_index].stock += _inc;
    }

    function mintMore(uint _index, uint _amt) public onlyShopOwner(_index) returns (string memory, string memory, uint) {
        shop_No[_index].tokens.mint(shop_No[_index].owner, _amt);
        shop_No[_index].tokenBal = shop_No[_index].tokens.balanceChecker(shop_No[_index].owner);
        return (shop_No[_index].name, shop_No[_index].symbol, shop_No[_index].tokens.balanceChecker(shop_No[_index].owner));
    }

    function checkBalanceShop(uint _shopIndex) public view onlyShopOwner(_shopIndex) returns (string memory, string memory, uint) {
        return (shop_No[_shopIndex].name, shop_No[_shopIndex].symbol, shop_No[_shopIndex].tokens.balanceChecker(msg.sender));
    }

    function checkBalanceCustomer(uint _shopIndex) public view onlyCustomer(payable (msg.sender)) returns (string memory, string memory, uint) {
        return (shop_No[_shopIndex].name, shop_No[_shopIndex].symbol, shop_No[_shopIndex].tokens.balanceChecker(msg.sender));
    }

    event BurnCheck(string tokenName, string tokenSymbol, uint indexed _amtLeft);

    function Burn(uint _amt, uint _index) public onlyCustomer(payable (msg.sender)) {
        require(shop_No[_index].tokens.balanceChecker(msg.sender) >= _amt, "Not enough Tokens !!!!");
        shop_No[_index].tokens.burn(msg.sender, _amt);
        customer_No[customerToKey[address(msg.sender)]].stock -=_amt;
        emit BurnCheck(shop_No[_index].name, shop_No[_index].symbol, shop_No[_index].tokens.balanceChecker(msg.sender));
    }
    
}c dkncq m,d