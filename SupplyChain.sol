pragma solidity >=0.5.0 <0.7.0;

contract SupplyChain {

  event LogForSale(uint indexed sku);
  event LogSold(uint indexed sku);
  event LogShipped(uint indexed sku);
  event LogReceived(uint indexed sku);

  address public owner;
  uint skuCount;
  mapping (uint => Item) items;

  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  modifier onlyOwner() {
    require (msg.sender == owner);
    _;
  }

  modifier verifyCaller(address _address) {
    require (msg.sender == _address);
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price);
    _;
    }

  modifier checkValue(uint _sku, address payable buyer) {
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
    _;
  }

  modifier forSale(uint _sku) {
    require(items[_sku].state == State.ForSale);
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold);
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped);
    _;
  }

  modifier received(uint _sku) {
    require(items[_sku].state == State.Received);
    _;
  }

  function() external payable {
    revert("Something goes wrong!");
  }

  constructor() public {
    owner = msg.sender;
    skuCount = 0;
  }


  function addItem(string memory _name, uint _price) public returns(bool){
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  /*This function should use 3 modifiers to check if the item is for sale, if the buyer paid enough, and check the value after the function is called to make sure the buyer is
    refunded any excess ether sent.*/

  function buyItem(uint sku)
    public
    payable
    forSale(sku)
    paidEnough(items[sku].price)
    checkValue(sku, msg.sender)
    {
      items[sku].buyer = msg.sender;
      items[sku].seller.transfer(items[sku].price);
      items[sku].state = State.Sold;
      emit LogSold(sku);
    }

  /*2 modifiers to check if the item is sold already, and that the person calling this function
  is the seller.*/

  function shipItem(uint sku)
    public
    sold(sku)
    verifyCaller(items[sku].seller)
    {
      items[sku].state = State.Shipped;
      emit LogShipped(sku);
    }

  /*2 modifiers to check if the item is shipped already, and that the person calling this function
  is the buyer.*/

  function receiveItem(uint sku)
    public
    shipped(sku)
    verifyCaller(items[sku].buyer)
  {
      items[sku].state = State.Received;
      emit LogReceived(sku);
  }
  }
